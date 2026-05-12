# Graph Report - /Users/aashishbijukchhe/Documents/anti/offlinePOS  (2026-05-12)

## Corpus Check
- 122 files · ~110,140 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 985 nodes · 1294 edges · 51 communities detected
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS · INFERRED: 6 edges (avg confidence: 0.88)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Community 0|Community 0]]
- [[_COMMUNITY_Community 1|Community 1]]
- [[_COMMUNITY_Community 2|Community 2]]
- [[_COMMUNITY_Community 3|Community 3]]
- [[_COMMUNITY_Community 4|Community 4]]
- [[_COMMUNITY_Community 5|Community 5]]
- [[_COMMUNITY_Community 6|Community 6]]
- [[_COMMUNITY_Community 7|Community 7]]
- [[_COMMUNITY_Community 8|Community 8]]
- [[_COMMUNITY_Community 9|Community 9]]
- [[_COMMUNITY_Community 10|Community 10]]
- [[_COMMUNITY_Community 11|Community 11]]
- [[_COMMUNITY_Community 12|Community 12]]
- [[_COMMUNITY_Community 13|Community 13]]
- [[_COMMUNITY_Community 14|Community 14]]
- [[_COMMUNITY_Community 15|Community 15]]
- [[_COMMUNITY_Community 16|Community 16]]
- [[_COMMUNITY_Community 17|Community 17]]
- [[_COMMUNITY_Community 18|Community 18]]
- [[_COMMUNITY_Community 19|Community 19]]
- [[_COMMUNITY_Community 20|Community 20]]
- [[_COMMUNITY_Community 21|Community 21]]
- [[_COMMUNITY_Community 22|Community 22]]
- [[_COMMUNITY_Community 23|Community 23]]
- [[_COMMUNITY_Community 24|Community 24]]
- [[_COMMUNITY_Community 25|Community 25]]
- [[_COMMUNITY_Community 26|Community 26]]
- [[_COMMUNITY_Community 27|Community 27]]
- [[_COMMUNITY_Community 28|Community 28]]
- [[_COMMUNITY_Community 29|Community 29]]
- [[_COMMUNITY_Community 30|Community 30]]
- [[_COMMUNITY_Community 31|Community 31]]
- [[_COMMUNITY_Community 32|Community 32]]
- [[_COMMUNITY_Community 33|Community 33]]
- [[_COMMUNITY_Community 34|Community 34]]
- [[_COMMUNITY_Community 35|Community 35]]
- [[_COMMUNITY_Community 36|Community 36]]
- [[_COMMUNITY_Community 37|Community 37]]
- [[_COMMUNITY_Community 38|Community 38]]
- [[_COMMUNITY_Community 39|Community 39]]
- [[_COMMUNITY_Community 40|Community 40]]
- [[_COMMUNITY_Community 41|Community 41]]
- [[_COMMUNITY_Community 42|Community 42]]
- [[_COMMUNITY_Community 43|Community 43]]
- [[_COMMUNITY_Community 44|Community 44]]
- [[_COMMUNITY_Community 45|Community 45]]
- [[_COMMUNITY_Community 46|Community 46]]
- [[_COMMUNITY_Community 47|Community 47]]
- [[_COMMUNITY_Community 48|Community 48]]
- [[_COMMUNITY_Community 49|Community 49]]
- [[_COMMUNITY_Community 50|Community 50]]

## God Nodes (most connected - your core abstractions)
1. `_` - 54 edges
2. `package:drift/drift.dart` - 47 edges
3. `package:pos_app/core/database/app_database.dart` - 44 edges
4. `package:flutter/material.dart` - 41 edges
5. `package:flutter_riverpod/flutter_riverpod.dart` - 37 edges
6. `package:pos_app/core/providers/database_provider.dart` - 20 edges
7. `package:pos_app/core/utils/currency_formatter.dart` - 15 edges
8. `package:pos_app/features/side_nav/presentation/side_nav.dart` - 14 edges
9. `package:pos_app/features/products/domain/products_provider.dart` - 14 edges
10. `package:flutter/services.dart` - 13 edges

## Surprising Connections (you probably didn't know these)
- `autoPrintOrder` --rationale_for--> `Phase 4: Receipts & Hardware (ESC/POS)`  [INFERRED]
  lib/features/printing/domain/auto_print.dart → v1_roadmap.md
- `HeldOrder` --rationale_for--> `Phase 8.6: Hold & Resume Orders`  [INFERRED]
  lib/features/cart/domain/held_order.dart → v1_roadmap.md
- `Phase 7: Held orders (Hive-based snapshots)` --semantically_similar_to--> `Phase 8.6: Hold & Resume Orders`  [INFERRED] [semantically similar]
  ROADMAP.md → v1_roadmap.md
- `Offline-First Flutter POS` --references--> `Milestone 1: v1 (Foundation & Core POS)`  [EXTRACTED]
  PROJECT.md → ROADMAP.md
- `Offline-First Principle` --rationale_for--> `100% Offline Constraint`  [EXTRACTED]
  PROJECT.md → CLAUDE.md

## Hyperedges (group relationships)
- **Table occupancy coordination across cart, held orders, tables UI** — tables_provider_tablesstreamprovider, tables_provider_occupiedtableidsprovider, tables_provider_carttableprovider, cart_notifier_cartsession, held_orders_notifier_activeheldordersprovider, tables_screen_tablesscreen, cart_detail_screen_cartdetailscreen [EXTRACTED 0.88]
- **Held tickets subsystem (Hive-backed park & resume)** — held_order_heldorder, held_orders_notifier_heldordersnotifier, held_orders_notifier_activeheldordersprovider, held_tickets_bar_heldticketsbar, checkout_bar_checkoutbar, v1roadmap_phase8_hold_resume [EXTRACTED 0.92]
- **Offline-first constraint: drop outbox + bundled fonts + url_launcher handoff (no network)** — app_database_offline_drop_outbox, receipt_pdf_service_loadfont, receipt_screen_launch [INFERRED 0.85]
- **Cart session assignment flow (customer + table on active cart)** — checkout_bar_cartsessionprovider_watch, checkout_bar_route_customers, checkout_bar_route_tables [INFERRED 0.80]
- **Save-as-ticket pattern (hold current cart then clear)** — checkout_bar_holdcurrentcart_call, checkout_bar_clearcart_call, checkout_bar_cartprovider_watch [EXTRACTED 0.95]

## Communities

### Community 0 - "Community 0"
Cohesion: 0.03
Nodes (76): LazyDatabase, openConnection, WasmDatabase, AuditLog, Customers, ExpenseCategories, TaxGroups, TaxRates (+68 more)

### Community 1 - "Community 1"
Cohesion: 0.02
Nodes (73): dart:math, dart:ui, extractWrappedPath, paint, shouldRepaint, TronBorderPainter, ArticleDetailScreen, ArticleSection (+65 more)

### Community 2 - "Community 2"
Cohesion: 0.03
Nodes (61): package:go_router/go_router.dart, package:pos_app/core/theme/app_theme.dart, package:pos_app/core/theme/tron_border.dart, package:pos_app/features/cart/presentation/providers/cart_notifier.dart, package:pos_app/features/cart/presentation/providers/held_orders_notifier.dart, package:pos_app/shared/widgets/customer_avatar.dart, package:pos_app/shared/widgets/summary_row.dart, build (+53 more)

### Community 3 - "Community 3"
Cohesion: 0.04
Nodes (53): _, AuditLogCompanion, AuditLogData, CategoriesCompanion, Category, copyWith, copyWithCompanion, Customer (+45 more)

### Community 4 - "Community 4"
Cohesion: 0.04
Nodes (47): package:pos_app/features/products/domain/products_provider.dart, package:pos_app/shared/widgets/app_empty_state.dart, package:pos_app/shared/widgets/app_sheet.dart, build, Card, CategoriesScreen, _CategoryCard, _colorFor (+39 more)

### Community 5 - "Community 5"
Cohesion: 0.07
Nodes (36): AuditService, package:flutter_test/flutter_test.dart, package:pos_app/core/database/app_database.dart, package:pos_app/core/services/audit_service.dart, package:pos_app/features/cart/data/place_order.dart, package:pos_app/features/cart/domain/cart_item.dart, package:pos_app/features/cart/domain/cart_notifier.dart, package:pos_app/features/cart/domain/held_order.dart (+28 more)

### Community 6 - "Community 6"
Cohesion: 0.04
Nodes (44): back, build, next, OnboardingNotifier, saveDefaultTaxId, saveOnboardingComplete, setBusinessName, setCountry (+36 more)

### Community 7 - "Community 7"
Cohesion: 0.05
Nodes (37): FavoritesNotifier, build, didChangeDependencies, dispose, _label, saveBusinessAddress, saveBusinessName, saveBusinessPan (+29 more)

### Community 8 - "Community 8"
Cohesion: 0.05
Nodes (41): dart:io, LazyDatabase, openConnection, package:csv/csv.dart, package:drift/native.dart, package:image_picker/image_picker.dart, package:path/path.dart, package:path_provider/path_provider.dart (+33 more)

### Community 9 - "Community 9"
Cohesion: 0.04
Nodes (44): _AppearanceSection, _BackupSection, build, Card, Column, _confirmReset, _CurrencyPickerSheet, _CurrencySection (+36 more)

### Community 10 - "Community 10"
Cohesion: 0.05
Nodes (39): CurrencyFormatter, format, formatPlain, package:esc_pos_utils_plus/esc_pos_utils_plus.dart, package:intl/intl.dart, package:pdf/pdf.dart, package:pdf/widgets.dart, package:pos_app/core/utils/currency_formatter.dart (+31 more)

### Community 11 - "Community 11"
Cohesion: 0.06
Nodes (31): _ActionChip, _actionColor, _actionIcon, AuditLogScreen, build, _entityLabel, ListTile, _parseMeta (+23 more)

### Community 12 - "Community 12"
Cohesion: 0.06
Nodes (32): package:pos_app/core/services/demo_data_service.dart, package:pos_app/features/cart/domain/pos_filter_provider.dart, package:pos_app/features/cart/presentation/widgets/checkout_bar.dart, package:pos_app/features/cart/presentation/widgets/grid_product_tile.dart, package:pos_app/features/cart/presentation/widgets/held_tickets_bar.dart, package:pos_app/features/cart/presentation/widgets/product_tile.dart, package:pos_app/features/products/domain/favorites_provider.dart, allowQty (+24 more)

### Community 13 - "Community 13"
Cohesion: 0.06
Nodes (29): dart:convert, package:flutter/services.dart, package:pos_app/core/providers/audit_service_provider.dart, package:pos_app/features/customers/domain/customers_provider.dart, package:pos_app/features/printing/domain/auto_print.dart, AuditService, build, ChoiceChip (+21 more)

### Community 14 - "Community 14"
Cohesion: 0.08
Nodes (23): package:pos_app/core/utils/tax_calculator.dart, add, addItem, addProduct, build, CartNotifier, CartSession, CartSessionNotifier (+15 more)

### Community 15 - "Community 15"
Cohesion: 0.08
Nodes (23): _Body, build, Card, Column, Container, DashboardScreen, _DashboardScreenState, DateTime (+15 more)

### Community 16 - "Community 16"
Cohesion: 0.08
Nodes (23): AppEmptyState, _apply, _badgeColor, build, Card, _Chip, Color, Column (+15 more)

### Community 17 - "Community 17"
Cohesion: 0.09
Nodes (21): dart:async, package:flutter_thermal_printer/flutter_thermal_printer.dart, package:flutter_thermal_printer/utils/printer.dart, package:pos_app/core/utils/async_feedback.dart, package:pos_app/features/printing/domain/print_receipt.dart, StateError, build, clearPrinterDevice (+13 more)

### Community 18 - "Community 18"
Cohesion: 0.1
Nodes (20): AppEmptyState, _Badge, build, Card, Center, Container, _CustomerCard, _CustomerForm (+12 more)

### Community 19 - "Community 19"
Cohesion: 0.11
Nodes (18): _assignToCart, build, Center, dispose, initState, InkWell, Padding, PopupMenuItem (+10 more)

### Community 20 - "Community 20"
Cohesion: 0.11
Nodes (18): package:uuid/uuid.dart, build, _ComponentEntry, _ComponentPickerSheet, _ComponentPickerSheetState, didChangeDependencies, dispose, Divider (+10 more)

### Community 21 - "Community 21"
Cohesion: 0.12
Nodes (15): BackupScreen, _BackupScreenState, _BackupTile, build, _buildInfoCard, Card, Container, exportFn (+7 more)

### Community 22 - "Community 22"
Cohesion: 0.18
Nodes (13): CallbackShortcuts bindings (Cmd+T tables, Cmd+H pos, etc.), onboarding redirect guard, POSApp, GoRoute /pos -> CartScreen, GoRoute /receipt/:orderId -> ReceiptScreen, GoRoute /tables -> TablesScreen, routerProvider (GoRouter), _slide (CustomTransitionPage builder) (+5 more)

### Community 23 - "Community 23"
Cohesion: 0.2
Nodes (9): clearSearch, copyWith, PosFilterNotifier, PosFilterState, setCategory, setSearch, setSortMode, toggleFavoritesOnly (+1 more)

### Community 24 - "Community 24"
Cohesion: 0.22
Nodes (9): Banned Packages Rationale (no google_fonts/connectivity_plus/workmanager/Firebase/Supabase), No-Cloud-Sync / Sandbox-Blocked Network Rationale, 100% Offline Constraint, Feature-First Architecture, Hardware Integration Principle (ESC/POS), Offline-First Flutter POS, Offline-First Principle, Tech Stack (Flutter/Riverpod/Drift/Hive/GoRouter) (+1 more)

### Community 25 - "Community 25"
Cohesion: 0.33
Nodes (5): compoundTax, lineItemTax, priceBeforeTax, _round, TaxCalculator

### Community 26 - "Community 26"
Cohesion: 0.47
Nodes (6): Circular Arrows Mark, Green and Blue Color Palette, Openness and Cycle Concept, OpenPOS Brand Logo, Point of Sale Concept, OPEN POS Wordmark

### Community 27 - "Community 27"
Cohesion: 0.5
Nodes (4): Flutter codelab citation, Flutter cookbook citation, Flutter online documentation, pos_app (README)

### Community 28 - "Community 28"
Cohesion: 0.67
Nodes (3): ShortcutsScreen, PosDrawer, _routes (route map)

### Community 29 - "Community 29"
Cohesion: 0.67
Nodes (2): CartItem, copyWith

### Community 30 - "Community 30"
Cohesion: 0.67
Nodes (3): HeldOrder, Phase 7: Held orders (Hive-based snapshots), Phase 8.6: Hold & Resume Orders

### Community 31 - "Community 31"
Cohesion: 1.0
Nodes (2): Rationale: DataClassName PosTable to avoid clashing with Drift Table base, Tables (Drift table, DataClassName PosTable)

### Community 32 - "Community 32"
Cohesion: 1.0
Nodes (2): autoPrintOrder, Phase 4: Receipts & Hardware (ESC/POS)

### Community 33 - "Community 33"
Cohesion: 1.0
Nodes (2): _orderDetailProvider, OrderDetailScreen

### Community 34 - "Community 34"
Cohesion: 1.0
Nodes (1): CountryDefault

### Community 35 - "Community 35"
Cohesion: 1.0
Nodes (2): Provider boot hierarchy, Riverpod State Management Decision

### Community 36 - "Community 36"
Cohesion: 1.0
Nodes (1): _

### Community 37 - "Community 37"
Cohesion: 1.0
Nodes (1): _

### Community 38 - "Community 38"
Cohesion: 1.0
Nodes (1): _

### Community 39 - "Community 39"
Cohesion: 1.0
Nodes (1): _

### Community 40 - "Community 40"
Cohesion: 1.0
Nodes (1): _

### Community 41 - "Community 41"
Cohesion: 1.0
Nodes (1): _

### Community 42 - "Community 42"
Cohesion: 1.0
Nodes (1): _

### Community 43 - "Community 43"
Cohesion: 1.0
Nodes (1): _

### Community 44 - "Community 44"
Cohesion: 1.0
Nodes (1): tables_dao_test main

### Community 45 - "Community 45"
Cohesion: 1.0
Nodes (1): upsert + watchAll returns rows ordered by name

### Community 46 - "Community 46"
Cohesion: 1.0
Nodes (1): getById/deleteById round-trip

### Community 47 - "Community 47"
Cohesion: 1.0
Nodes (1): upsert with explicit id updates row

### Community 48 - "Community 48"
Cohesion: 1.0
Nodes (0): 

### Community 49 - "Community 49"
Cohesion: 1.0
Nodes (1): Phase 3: Core Sales Loop (cart, checkout, refund)

### Community 50 - "Community 50"
Cohesion: 1.0
Nodes (1): Drift Schema (v1 tables)

## Knowledge Gaps
- **789 isolated node(s):** `tables_dao_test main`, `upsert + watchAll returns rows ordered by name`, `getById/deleteById round-trip`, `upsert with explicit id updates row`, `_FixedSessionNotifier` (+784 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Community 31`** (2 nodes): `Rationale: DataClassName PosTable to avoid clashing with Drift Table base`, `Tables (Drift table, DataClassName PosTable)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 32`** (2 nodes): `autoPrintOrder`, `Phase 4: Receipts & Hardware (ESC/POS)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 33`** (2 nodes): `_orderDetailProvider`, `OrderDetailScreen`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 34`** (2 nodes): `country_default.dart`, `CountryDefault`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 35`** (2 nodes): `Provider boot hierarchy`, `Riverpod State Management Decision`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 36`** (1 nodes): `_`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 37`** (1 nodes): `_`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 38`** (1 nodes): `_`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 39`** (1 nodes): `_`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 40`** (1 nodes): `_`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 41`** (1 nodes): `_`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 42`** (1 nodes): `_`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 43`** (1 nodes): `_`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 44`** (1 nodes): `tables_dao_test main`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 45`** (1 nodes): `upsert + watchAll returns rows ordered by name`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 46`** (1 nodes): `getById/deleteById round-trip`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 47`** (1 nodes): `upsert with explicit id updates row`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 48`** (1 nodes): `string_utils.dart`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 49`** (1 nodes): `Phase 3: Core Sales Loop (cart, checkout, refund)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 50`** (1 nodes): `Drift Schema (v1 tables)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `package:flutter/material.dart` connect `Community 1` to `Community 2`, `Community 4`, `Community 6`, `Community 7`, `Community 8`, `Community 9`, `Community 10`, `Community 11`, `Community 12`, `Community 13`, `Community 15`, `Community 16`, `Community 17`, `Community 18`, `Community 19`, `Community 20`, `Community 21`?**
  _High betweenness centrality (0.210) - this node is a cross-community bridge._
- **Why does `package:flutter_riverpod/flutter_riverpod.dart` connect `Community 7` to `Community 2`, `Community 4`, `Community 5`, `Community 6`, `Community 8`, `Community 9`, `Community 10`, `Community 11`, `Community 12`, `Community 13`, `Community 14`, `Community 15`, `Community 16`, `Community 17`, `Community 18`, `Community 19`, `Community 20`, `Community 21`, `Community 23`?**
  _High betweenness centrality (0.151) - this node is a cross-community bridge._
- **Why does `package:pos_app/core/database/app_database.dart` connect `Community 5` to `Community 0`, `Community 1`, `Community 2`, `Community 4`, `Community 6`, `Community 7`, `Community 8`, `Community 9`, `Community 10`, `Community 11`, `Community 12`, `Community 13`, `Community 14`, `Community 16`, `Community 18`, `Community 19`, `Community 20`?**
  _High betweenness centrality (0.148) - this node is a cross-community bridge._
- **What connects `tables_dao_test main`, `upsert + watchAll returns rows ordered by name`, `getById/deleteById round-trip` to the rest of the system?**
  _789 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.03 - nodes in this community are weakly interconnected._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.02 - nodes in this community are weakly interconnected._
- **Should `Community 2` be split into smaller, more focused modules?**
  _Cohesion score 0.03 - nodes in this community are weakly interconnected._