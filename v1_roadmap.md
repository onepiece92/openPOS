# v1 Roadmap — Flutter Offline-First POS

Build order follows strict dependency: a phase cannot start until all items in the prior phase are shippable.

---

## Architecture Decisions

### State Management — Riverpod

**Chosen: Riverpod + `riverpod_generator`**

| Concern | Riverpod Approach |
|---|---|
| Drift DB streams | `StreamProvider` wraps DAO watch queries; auto-rebuilds UI on row changes |
| Async operations (checkout, sync) | `AsyncNotifierProvider` handles loading / error / data states cleanly |
| Global singletons (DB, Hive, connectivity) | `Provider` at root; injected via `ref.watch` — no service locator needed |
| Cart in-memory state | `NotifierProvider` with `CartNotifier` class; immutable state updates |
| Code generation | `@riverpod` annotation + `build_runner`; eliminates boilerplate |

**Key packages:**
```yaml
flutter_riverpod: ^2.x
riverpod_annotation: ^2.x
riverpod_generator: ^2.x   # dev dependency
```

**Pattern per feature:**
```
features/cart/
  data/
    cart_repository.dart       # talks to Drift DAO
  domain/
    cart_item.dart             # pure Dart model
  presentation/
    cart_notifier.dart         # @riverpod CartNotifier extends _$CartNotifier
    cart_screen.dart           # ConsumerWidget
```

**Provider hierarchy (boot order):**
```
databaseProvider          → AppDatabase (Drift singleton)
  └─ hiveProvider         → HiveInterface (opened boxes)
      └─ connectivityProvider  → ConnectivityStatus stream
          └─ onboardingProvider → OnboardingState
              └─ [feature providers...]
```

Every provider is overridable in tests via `ProviderScope(overrides: [...])`.

---

## Phase 0 — Foundation (No UI yet)

Everything downstream depends on this being correct. Get it right before building features.

| # | Task | Module | Notes |
|---|------|--------|-------|
| 0.1 | Flutter project scaffold | — | Feature-first folder structure: `features/cart`, `features/products`, etc. |
| 0.2 | Drift database setup + `schemaVersion` | Sync | Define all tables upfront; migration strategy wired from day 1 |
| 0.3 | Hive initialization + adapters | Settings / Sync | App-wide preferences, brand config, onboarding flag |
| 0.4 | Riverpod (or Bloc) wiring | — | State management layer; providers for each feature |
| 0.5 | Connectivity detection | Sync | `connectivity_plus`; global online/offline state |
| 0.6 | Seed data on first install | Sync | Default tax rate, expense categories; idempotent insert |
| 0.7 | Data integrity check on startup | Sync | SQLite PRAGMA + FK check; log to audit trail |

**Drift schema tables required by Phase 0:**
`tax_rates`, `categories`, `expense_categories`, `audit_log`, `outbox_queue`

---

## Phase 1 — First-Run & Onboarding

> No accounts, no login. 100% offline. Data lives on-device only.

| # | Task | Module | Notes |
|---|------|--------|-------|
| 1.1 | First-Run Setup Wizard | Onboarding | Business name, currency, timezone, default tax; sets `onboarding_complete` flag |
| 1.2 | Country-based defaults | Onboarding | Bundled locale JSON → auto-fill currency + tax suggestion |
| 1.3 | Onboarding checklist widget | Onboarding | Home screen widget; dismissed when all tasks complete |

---

## Phase 2 — Product & Inventory Core

| # | Task | Module | Notes |
|---|------|--------|-------|
| 2.1 | Store Profile + Currency/Locale settings | Settings | Populates receipts; drives `intl` formatting everywhere |
| 2.2 | Product CRUD | Products | Name, price, SKU, images (local file system) |
| 2.3 | Categories & Subcategories | Products | Hierarchical; FK to `categories` table |
| 2.4 | Variants / Modifiers | Products | Variant tables; required for F&B before any selling |
| 2.5 | Stock Level Tracking | Inventory | Real-time deduction on sale; `products.stock_quantity` column |
| 2.6 | Tax Engine — Multiple Rates | Tax | `tax_rates` table; inclusive/exclusive toggle; default assignment |
| 2.7 | Taxable toggle per product | Tax | `products.is_taxable`; overrides store default |
| 2.8 | Tax Assignment per Product | Tax | `product_taxes` join table |

**Drift tables added:** `products`, `product_variants`, `product_modifiers`, `product_taxes`

---

## Phase 3 — Core Sales Loop

| # | Task | Module | Notes |
|---|------|--------|-------|
| 3.1 | Product Catalog Browser | Core Sales | Grid/list; category filter; search |
| 3.2 | Barcode / QR Scanner | Core Sales | `mobile_scanner`; add to cart by SKU lookup |
| 3.3 | Cart Management | Core Sales | In-memory + Hive; quantity, line discounts |
| 3.4 | Checkout Flow | Core Sales | Order review → payment method → confirm |
| 3.5 | Cash Payment | Core Sales | Tendered amount → change due; denomination breakdown optional |
| 3.6 | Tax calculation at checkout | Tax | Apply rates per line; tax rounding rules; build `order_taxes` rows |
| 3.7 | Tax Breakdown on Receipt | Tax | Itemised tax lines per rate on every receipt |
| 3.8 | Refunds & Returns | Expenses | Full/partial refund; optional restock |
| 3.9 | Void Transaction | Expenses | Soft delete; manager PIN; audit log entry |
| 3.10 | Transaction Audit Trail | Audit Log | Append-only log for every sale/void/refund |

**Drift tables added:** `orders`, `order_items`, `order_taxes`, `order_tax_override`, `returns`, `audit_log` (rows begin here)

---

## Phase 4 — Receipts & Hardware

| # | Task | Module | Notes |
|---|------|--------|-------|
| 4.1 | Digital Receipt (in-app) | Receipts | On-screen after each sale; stored in `orders` |
| 4.2 | Thermal Printer Receipt | Receipts / Hardware | `esc_pos_utils` + `blue_thermal_printer`; ESC/POS commands |
| 4.3 | Bluetooth Thermal Printer pairing | Hardware | Printer Setup Wizard in Settings; test page print |
| 4.4 | USB / Network Printer | Hardware | `esc_pos_utils`; LAN discovery |
| 4.5 | Cash Drawer kick | Hardware | ESC/POS DLE EOT via printer port; fires on cash payment |
| 4.6 | Receipt Customization | Receipts | Logo, store name, footer, tax number; live preview |
| 4.7 | Reprint Last Receipt | Receipts | From order history; re-render ESC/POS from stored order |

---

## Phase 5 — Backup & Data Safety

> No cloud sync. Backup is local-only: export to device storage or share via Files app.

| # | Task | Module | Notes |
|---|------|--------|-------|
| 5.1 | Local Backup Export | Backup | `path_provider` + `share_plus`; export encrypted DB file to device or share |
| 5.2 | Restore from Local Backup | Backup | Pick backup file from device; overwrite local DB; confirmation dialog |
| 5.3 | Backup History (local) | Backup | List of past local snapshots with date + size; keep last 10 |
| 5.4 | Auto Local Backup on Schedule | Backup | `workmanager` triggers export to app documents folder daily |

---

## Phase 6 — Expenses & Reports

| # | Task | Module | Notes |
|---|------|--------|-------|
| 6.1 | Expense Entry + Categories | Expenses | Quick-add from home; color-coded categories |
| 6.2 | Petty Cash Tracking | Expenses | Ledger with opening balance; cash in / cash out |
| 6.3 | Cash Reconciliation / X-Report | Expenses | Expected vs actual drawer; per session |
| 6.4 | Expense vs Revenue Report (P&L) | Expenses | Day/week/month selector |
| 6.5 | Sales Summary Dashboard | Reports | Today/week/month totals; top products; local charts |
| 6.6 | Tax Report by Rate | Tax | Gross sales + tax collected per rate; CSV export |
| 6.7 | Product Sales Report | Reports | Units sold, revenue per product; CSV export |
| 6.8 | Export to CSV / PDF | Reports | `csv` + `pdf` packages; share via device apps |

---

## Phase 7 — Customers, Loyalty & Audit

| # | Task | Module | Notes |
|---|------|--------|-------|
| 7.1 | Customer Profiles | Customers | Name, phone, email, loyalty points; link to orders |
| 7.2 | Customer Search at POS | Customers | SQLite FTS; search by name or phone during checkout |
| 7.3 | Loyalty Points | Customers | Configurable earn/redeem rates; applied at checkout |
| 7.4 | Audit Log Viewer | Audit Log | Owner-only; searchable by date + entity type |
| 7.5 | Settings Change Log | Audit Log | Tracks price/tax/config changes |
| 7.6 | Inventory Adjustment Log | Audit Log | Stock +/- with reason code; cross-ref audit trail |
| 7.7 | Low Stock Alerts | Inventory | `flutter_local_notifications`; threshold per product |

---

## Phase 8 — Polish & Theme

| # | Task | Module | Notes |
|---|------|--------|-------|
| 8.1 | Day / Night Mode Toggle | Theme | `ThemeData` + `ThemeMode`; follows system default |
| 8.2 | Brand Kit Theme (logo + colors) | Theme | `ColorScheme.fromSeed`; stored in Hive |
| 8.3 | Minimal Theme | Theme | High-contrast flat; best for bright retail environments |
| 8.4 | Theme Preview Screen | Theme | Full-screen sample checkout preview before apply |
| 8.5 | Favorites / Quick-Access Grid | Products | Pin frequent items; stored in Hive preferences |
| 8.6 | Hold & Resume Orders | Core Sales | Park open order; multi-cart support |
| 8.7 | Sample Data Option (onboarding) | Onboarding | Demo products for exploration; one-tap wipe |
| 8.8 | Email / SMS Receipt (outbox) | Receipts | Queue when offline; deliver on reconnect |

---

## Deferred to v2

- Composite / Bundle Items
- Price Tiers / Pricelists
- Stock Take / Count
- Purchase Orders (Receiving)
- Multi-Location Stock
- Customer Groups / Tags
- Account / House Credit
- Compound Tax
- Tax-Exempt Customers
- Tax Override at Checkout
- Staff Performance Report
- Hourly Sales Heatmap
- Glassmorphic Theme
- Weight Scale Integration
- Customer Display / Pole Display
- Import Products via CSV
- Migration Import Wizard
- Cloud Backup / Supabase Sync (no accounts in v1)

---

## Drift Schema — Full Table List (v1)

```
tax_rates           id, name, rate, type, inclusion_type, rounding_mode, is_active
categories          id, name, parent_id, tax_rate_id
products            id, sku, name, price, stock_quantity, is_taxable, category_id, image_path
product_variants    id, product_id, name, price_delta, stock_quantity
product_modifiers   id, product_id, name, price_delta
product_taxes       product_id, tax_rate_id
tax_groups          id, name
tax_group_members   group_id, tax_rate_id
orders              id, created_at, updated_at, status, subtotal, tax_total, discount_total, total, payment_method, customer_id
order_items         id, order_id, product_id, variant_id, quantity, unit_price, discount, tax_amount
order_taxes         id, order_id, tax_rate_id, taxable_amount, tax_amount
order_tax_override  id, order_id, original_tax, override_tax, reason, created_at
returns             id, order_id, created_at, amount, restock, reason
customers           id, name, phone, email, loyalty_points, tax_exempt
expense_categories  id, name, color
expenses            id, amount, date, category_id, notes, receipt_image_path, is_recurring, vendor_id, is_tax_deductible
audit_log           id, created_at, entity_type, entity_id, action, old_value, new_value
outbox_queue        id, created_at, endpoint, payload, retry_count, last_attempt_at
stock_adjustments   id, product_id, delta, reason_code, created_at, audit_log_id
```
