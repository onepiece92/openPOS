# Graph Report - offlinePOS  (2026-08-18)

## Corpus Check
- 180 files · ~152,232 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 3164 nodes · 5012 edges · 131 communities (127 shown, 4 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 69 edges (avg confidence: 0.88)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `c1a93639`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- app_database.dart
- dashboard_screen.dart
- cart_notifier.dart
- onboarding_screen.dart
- DataClass
- hive_provider.dart
- expenses_screen.dart
- home.dart
- inventory_screen.dart
- products_dao.dart
- customers_screen.dart
- app.dart
- cart_detail_screen.dart
- app_theme.dart
- orders_dao.dart
- appearance_section.dart
- support_screen.dart
- product_form_screen.dart
- receipt_pdf_service.dart
- orders_screen.dart
- order_detail_screen.dart
- package:flutter/material.dart
- schema_v10.dart
- held_tickets_bar.dart
- backup_screen.dart
- products_screen.dart
- snapshot_service_test.dart
- printer_setup_screen.dart
- payment_screen.dart
- receipt_screen.dart
- tables_screen.dart
- AppDatabase
- categoriesStreamProvider
- receipt_body.dart
- onboarding_state.dart
- products_provider.dart
- held_order.dart
- tokens.dart
- product_tile.dart
- learn_screen.dart
- pos_filter_provider.dart
- audit_service.dart
- order_taxes_table.dart
- orders_table.dart
- audit_dao.dart
- article_detail_screen.dart
- package:pos_app/core/database/app_database.dart
- store_profile_edit_screen.dart
- tax_settings_screen.dart
- grid_product_tile.dart
- loyalty_section.dart
- package:pos_app/core/utils/currency_formatter.dart
- schema_v9.dart
- cart_session.dart
- products_table.dart
- List
- package:flutter_test/flutter_test.dart
- package:drift/drift.dart
- IntColumn get
- pos_app Package Manifest (v1.0.0+9)
- schema_v8.dart
- _StoreProfileEditScreenState
- currencyFormatterProvider
- expenses_dao.dart
- customers_table.dart
- expenses_table.dart
- cart_summary.dart
- Table
- render_receipt.dart
- Riverpod Architecture Decision (provider type per concern)
- Offline-First Non-Negotiable Constraint
- TextColumn get
- order_items_table.dart
- CurrencyFormatter
- app_sheet.dart
- snapshot_service.dart
- held_ticket_number_test.dart
- settings_screen.dart
- _
- databaseProvider
- audit_log_table.dart
- schema_v7.dart
- money.dart
- Feature-First Layered Architecture
- Dependency Audit (2026-04-22)
- cart_item.dart
- backup_repository.dart
- schema_v4.dart
- Milestone 1 — v1 Foundation & Core POS
- place_order_test.dart
- tables_dao.dart
- StatelessWidget
- tax_rates_table.dart
- ConsumerWidget
- Dual Data Layer (Drift + Hive)
- Banned Runtime-Fetching Packages
- app_root.dart
- onboarding_notifier.dart
- schema_v6.dart
- product_variants_table.dart
- audit_log_screen.dart
- SettingsNotifier
- Open POS Brand Logo
- native.dart
- snapshot_providers.dart
- schema.dart
- inventory_section.dart
- package:flutter_riverpod/flutter_riverpod.dart
- tables_provider.dart
- currencySymbolProvider
- custom_lint Analyzer Plugin (enabled in analysis_options)
- printerDeviceNameProvider
- occupied_tables_test.dart
- customers_dao.dart
- dismiss_keyboard_test.dart
- returns_table.dart
- String?
- migration_test.dart
- package:intl/intl.dart
- main.dart
- order_number.dart
- build
- GeneratedDatabase
- tax_dao.dart
- categories_table.dart
- defaultTaxIdProvider
- package:pos_app/shared/widgets/app_sheet.dart
- _RouterRefresh
- LoyaltySection
- AppScrollBehavior
- currencies.dart

## God Nodes (most connected - your core abstractions)
1. `databaseProvider` - 35 edges
2. `cartSessionProvider` - 23 edges
3. `AppDatabase` - 22 edges
4. `DataClass` - 21 edges
5. `currencyFormatterProvider` - 21 edges
6. `settingsProvider` - 18 edges
7. `cartProvider` - 17 edges
8. `build` - 13 edges
9. `CurrencyFormatter` - 13 edges
10. `build` - 13 edges

## Surprising Connections (you probably didn't know these)
- `ROADMAP Phase 1 — Core Foundation & Shared Logic` --semantically_similar_to--> `v1 Phase 0 — Foundation (no UI)`  [INFERRED] [semantically similar]
  ROADMAP.md → v1_roadmap.md
- `ROADMAP Phase 4 — POS Interface (Main Flow)` --semantically_similar_to--> `v1 Phase 3 — Core Sales Loop`  [INFERRED] [semantically similar]
  ROADMAP.md → v1_roadmap.md
- `ROADMAP Phase 6 — Order History & Local Reporting` --semantically_similar_to--> `v1 Phase 6 — Expenses & Reports`  [INFERRED] [semantically similar]
  ROADMAP.md → v1_roadmap.md
- `Drift Schema — Full v1 Table List` --implements--> `Drift Layout Convention (tables, daos, AppDatabase migrations)`  [INFERRED]
  v1_roadmap.md → .planning/codebase/CONVENTIONS.md
- `flutter_thermal_printer dependency` --semantically_similar_to--> `heathen_printer_plus (documented printer package)`  [INFERRED] [semantically similar]
  pubspec.yaml → .planning/codebase/DEPENDENCIES.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Offline-First Enforcement Regime** — claude_offline_first_constraint, claude_banned_packages, claude_network_permission_lockdown, claude_deleted_sync_scaffolding, claude_url_launcher_exception, _planning_codebase_integrations_no_external_apis, project_core_mission [EXTRACTED 1.00]
- **Riverpod State & DI Layer Contract** — _planning_codebase_architecture_state_management_riverpod, _planning_codebase_conventions_provider_naming, v1_roadmap_riverpod_decision_table, v1_roadmap_provider_hierarchy, v1_roadmap_cart_notifier, project_riverpod_sole_di, pubspec_riverpod_generator_omitted [INFERRED 0.85]
- **End-to-End Tax Calculation Flow** — v1_roadmap_tax_engine, v1_roadmap_phase_2_product_inventory_core, v1_roadmap_phase_3_core_sales_loop, v1_roadmap_phase_4_receipts_hardware, v1_roadmap_phase_6_expenses_reports, v1_roadmap_drift_schema_v1 [EXTRACTED 1.00]
- **Open POS Brand Identity System** — assets_images_logo_open_pos_brand_logo, assets_images_logo_open_pos_wordmark, assets_images_logo_circular_arrow_mark, assets_images_logo_green_blue_gradient_palette [INFERRED 0.85]

## Communities (131 total, 4 thin omitted)

### Community 0 - "app_database.dart"
Cohesion: 0.01
Nodes (246): class OrderTaxOverride extends, class ProductComponent extends, ColumnFilters, ColumnOrderings, backfillInvoiceNumbers, currentSchemaVersion, migration, _openConnection (+238 more)

### Community 1 - "dashboard_screen.dart"
Cohesion: 0.04
Nodes (53): DateTimeRange?, avgOrder, _buildKpiRows, chartDates, chartHighlightIndex, chartTitle, chartTotals, color (+45 more)

### Community 2 - "cart_notifier.dart"
Cohesion: 0.10
Nodes (20): add, addItem, addProduct, allRates, CartNotifier, clearItems, compute, itemCount (+12 more)

### Community 3 - "onboarding_screen.dart"
Cohesion: 0.05
Nodes (49): onboardingNotifierProvider, _back, build, _businessNameCtrl, canNext, _canProceed, children, controller (+41 more)

### Community 4 - "DataClass"
Cohesion: 0.08
Nodes (46): Insertable, initials, name, OrderNumberX, UpdateCompanion, AuditLogCompanion, AuditLogData, CategoriesCompanion (+38 more)

### Community 5 - "hive_provider.dart"
Cohesion: 0.03
Nodes (66): autoBackupEnabled, autoBackupLastAt, _box, build, businessAddress, businessName, businessNameOrDefault, businessPan (+58 more)

### Community 6 - "expenses_screen.dart"
Cohesion: 0.06
Nodes (40): _amountCtrl, build, categories, category, _categoryId, color, createState, cs (+32 more)

### Community 7 - "home.dart"
Cohesion: 0.06
Nodes (32): _applyFilter, cart, categories, _CategoryRow, _Chip, createState, dispose, favorites (+24 more)

### Community 8 - "inventory_screen.dart"
Cohesion: 0.06
Nodes (35): _apply, badgeColor, canDecrement, canIncrement, _Chip, color, createState, cs (+27 more)

### Community 9 - "products_dao.dart"
Cohesion: 0.08
Nodes (25): adjustStock, deductStock, deleteCategory, getAllCategories, getById, getBySku, getComponents, getModifiers (+17 more)

### Community 10 - "customers_screen.dart"
Cohesion: 0.05
Nodes (45): Color, CustomPainter, dart:math, IconData get, color, e, extractWrappedPath, f (+37 more)

### Community 11 - "app.dart"
Cohesion: 0.06
Nodes (31): GoRouter, getKeyboardDismissBehavior, ping, refresh, _slide, Offset, package:pos_app/features/audit/presentation/audit_log_screen.dart, package:pos_app/features/backup/presentation/backup_screen.dart (+23 more)

### Community 12 - "cart_detail_screen.dart"
Cohesion: 0.06
Nodes (31): addColor, createState, cs, _ctrl, currentDiscount, customers, dispose, fmt (+23 more)

### Community 13 - "app_theme.dart"
Cohesion: 0.11
Nodes (18): AppTheme, backgroundGradient, _build, ctaButtonStyle, dark, _darkGrad, _darkScheme, _fontFamily (+10 more)

### Community 14 - "orders_dao.dart"
Cohesion: 0.09
Nodes (21): getAllOrdersWithItems, getById, getItems, getTaxBreakdown, insertItems, insertOrder, insertReturn, insertTaxLines (+13 more)

### Community 15 - "appearance_section.dart"
Cohesion: 0.18
Nodes (11): POSApp, routerProvider, themeModeProvider, AppearanceSection, build, current, _options, _showThemePicker (+3 more)

### Community 16 - "support_screen.dart"
Cohesion: 0.11
Nodes (17): build, cs, gradient, icon, _InfoRow, label, onTap, _SectionHeader (+9 more)

### Community 17 - "product_form_screen.dart"
Cohesion: 0.06
Nodes (36): _categoryId, _ComponentEntry, _components, _conversionCtrl, createState, _delete, didChangeDependencies, dispose (+28 more)

### Community 18 - "receipt_pdf_service.dart"
Cohesion: 0.07
Nodes (27): baseStyle, billRow, boldStyle, buildReceiptPdf, bytes, customerName, data, _dataCell (+19 more)

### Community 19 - "orders_screen.dart"
Cohesion: 0.08
Nodes (28): build, createState, cs, customerName, _filter, fmt, _groupByDate, icon (+20 more)

### Community 20 - "order_detail_screen.dart"
Cohesion: 0.09
Nodes (22): auditServiceProvider, businessName, customer, data, db, _DetailBody, _DetailData, fmt (+14 more)

### Community 21 - "package:flutter/material.dart"
Cohesion: 0.09
Nodes (18): build, SettingsSectionHeader, title, i, _indexFor, _label, PosDrawer, _routes (+10 more)

### Community 22 - "schema_v10.dart"
Cohesion: 0.02
Nodes (99): Index, action, actualTableName, address, _alias, aliasedName, allSchemaEntities, allTables (+91 more)

### Community 23 - "held_tickets_bar.dart"
Cohesion: 0.09
Nodes (29): AnimationController, ConsumerState, ConsumerStatefulWidget, demoDataServiceProvider, _EmptyProductsState, _EmptyProductsStateState, _loadDemo, PaymentScreen (+21 more)

### Community 24 - "backup_screen.dart"
Cohesion: 0.06
Nodes (36): autoBackupEnabledProvider, autoBackupLastAtProvider, backupRepositoryProvider, snapshotCoordinatorProvider, _AutoBackupTile, BackupScreen, _BackupScreenState, _BackupTile (+28 more)

### Community 25 - "products_screen.dart"
Cohesion: 0.07
Nodes (27): _applyFilter, categories, _CategoryChips, categoryName, _Chip, createState, cs, dispose (+19 more)

### Community 26 - "snapshot_service_test.dart"
Cohesion: 0.15
Nodes (12): Exception, SnapshotFormatException, package:pos_app/features/backup/data/snapshot_service.dart, dbFileIn, hivePathIn, live, main, openDb (+4 more)

### Community 27 - "printer_setup_screen.dart"
Cohesion: 0.09
Nodes (22): connected, device, ftp, printBytesToBleAddress, printData, createState, _devices, _devicesSub (+14 more)

### Community 28 - "payment_screen.dart"
Cohesion: 0.09
Nodes (21): createState, customer, dispose, fmt, icon, initState, label, _loyaltyCtrl (+13 more)

### Community 29 - "receipt_screen.dart"
Cohesion: 0.10
Nodes (21): ReceiptBodyData, build, businessName, customer, data, db, fmt, _handle (+13 more)

### Community 30 - "tables_screen.dart"
Cohesion: 0.10
Nodes (21): _assignToCart, _capacityCtrl, createState, dispose, existing, initState, isCurrentCartTable, isOccupied (+13 more)

### Community 31 - "AppDatabase"
Cohesion: 0.16
Nodes (21): _, @DriftAccessor, @DriftDatabase, _$AuditDaoMixin, _$CustomersDaoMixin, DatabaseAccessor, _$ExpensesDaoMixin, _$InventoryDaoMixin (+13 more)

### Community 32 - "categoriesStreamProvider"
Cohesion: 0.15
Nodes (15): build, categoriesStreamProvider, productsByCategoryProvider, productsFilterProvider, productsStreamProvider, build, CategoriesScreen, _CategoryCard (+7 more)

### Community 33 - "receipt_body.dart"
Cohesion: 0.10
Nodes (19): _BillRow, build, businessName, customer, data, _DataCell, fmt, _HeaderCell (+11 more)

### Community 34 - "onboarding_state.dart"
Cohesion: 0.10
Nodes (18): code, CountryDefault, currency, fromJson, name, symbol, taxName, taxRate (+10 more)

### Community 35 - "products_provider.dart"
Cohesion: 0.13
Nodes (15): clearSearch, copyWith, outOfStockOnly, ProductsFilterNotifier, ProductsFilterState, ref, search, selectedCategoryId (+7 more)

### Community 36 - "held_order.dart"
Cohesion: 0.10
Nodes (19): archivedAt, copyWith, createdAt, customerId, customerName, fromJson, HeldOrder, id (+11 more)

### Community 37 - "tokens.dart"
Cohesion: 0.11
Nodes (18): AppFonts, AppOpacity, heavy, lg, md, medium, mono, Radii (+10 more)

### Community 38 - "product_tile.dart"
Cohesion: 0.11
Nodes (18): bg, build, color, cs, fmt, icon, isFavorite, onDecrement (+10 more)

### Community 39 - "learn_screen.dart"
Cohesion: 0.08
Nodes (23): ColorScheme, _Article, _ArticleCard, _articles, build, category, cs, description (+15 more)

### Community 40 - "pos_filter_provider.dart"
Cohesion: 0.12
Nodes (16): clearSearch, copyWith, favoritesOnly, isGrid, PosFilterNotifier, PosFilterState, PosSortMode, search (+8 more)

### Community 41 - "audit_service.dart"
Cohesion: 0.20
Nodes (9): dart:convert, AuditService, _db, log, orderPlaced, orderRefunded, orderVoided, settingChanged (+1 more)

### Community 42 - "order_taxes_table.dart"
Cohesion: 0.12
Nodes (15): id, orderId, OrderTaxes, taxableAmount, taxAmount, taxRateId, taxRateName, taxRatePercent (+7 more)

### Community 43 - "orders_table.dart"
Cohesion: 0.09
Nodes (22): @TableIndex, changeAmount, createdAt, customerId, discountIsPercent, discountTotal, discountValue, id (+14 more)

### Community 44 - "audit_dao.dart"
Cohesion: 0.29
Nodes (6): log, queryByDateRange, queryByEntity, watchRecent, package:pos_app/core/database/tables/audit_log_table.dart, _

### Community 45 - "article_detail_screen.dart"
Cohesion: 0.11
Nodes (17): ArticleDetailScreen, ArticleSection, build, category, cs, heading, icon, readTime (+9 more)

### Community 46 - "package:pos_app/core/database/app_database.dart"
Cohesion: 0.07
Nodes (36): db, placeOrder, transaction, processReturn, transaction, transaction, voidOrder, package:pos_app/core/database/app_database.dart (+28 more)

### Community 47 - "store_profile_edit_screen.dart"
Cohesion: 0.11
Nodes (17): class, _cache, CountryRepository, load, _addressCtrl, build, createState, dispose (+9 more)

### Community 48 - "tax_settings_screen.dart"
Cohesion: 0.12
Nodes (16): FormState, createState, dispose, existing, _formKey, _inclusionType, _nameCtrl, onAdd (+8 more)

### Community 49 - "grid_product_tile.dart"
Cohesion: 0.07
Nodes (25): build, fmt, GridProductTile, isFavorite, onDecrement, onIncrement, onTap, onToggleFavorite (+17 more)

### Community 50 - "loyalty_section.dart"
Cohesion: 0.22
Nodes (9): createState, dispose, _earnCtrl, earnRate, _LoyaltyRateSheet, _LoyaltyRateSheetState, pointValue, _showRateSheet (+1 more)

### Community 51 - "package:pos_app/core/utils/currency_formatter.dart"
Cohesion: 0.20
Nodes (9): package:pos_app/core/utils/currency_formatter.dart, package:pos_app/features/printing/domain/render_receipt.dart, fmt, item, main, null, order, _sampleData (+1 more)

### Community 52 - "schema_v9.dart"
Cohesion: 0.02
Nodes (101): ProductModifiers, Tables, action, actualTableName, address, _alias, aliasedName, allSchemaEntities (+93 more)

### Community 53 - "cart_session.dart"
Cohesion: 0.14
Nodes (13): bool get, copyWith, customerId, fresh, heldTicketId, isEditingHeldTicket, loyaltyPointsToRedeem, openedAt (+5 more)

### Community 54 - "products_table.dart"
Cohesion: 0.10
Nodes (20): categoryId, conversionRate, createdAt, id, imagePath, isActive, isComposite, isHiddenInPos (+12 more)

### Community 55 - "List"
Cohesion: 0.11
Nodes (19): heldOrdersBoxProvider, SelectedTaxRatesNotifier, archive, archiveAll, _box, build, delete, deleteAllArchived (+11 more)

### Community 56 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.20
Nodes (10): _, compoundTax, lineItemTax, priceBeforeTax, _round, TaxCalculator, package:flutter_test/flutter_test.dart, package:pos_app/core/utils/money.dart (+2 more)

### Community 57 - "package:drift/drift.dart"
Cohesion: 0.09
Nodes (19): openConnection, getAdjustmentsForProduct, logAdjustment, watchLowStock, createdAt, delta, id, notes (+11 more)

### Community 58 - "IntColumn get"
Cohesion: 0.10
Nodes (19): IntColumn get, componentProductId, compositeProductId, id, ProductComponents, quantity, primaryKey, productId (+11 more)

### Community 59 - "pos_app Package Manifest (v1.0.0+9)"
Cohesion: 0.19
Nodes (14): drift as Critical Persistence Dependency, Technology Stack (Dart 3.5+, Flutter 3.24+), pos_app Package Manifest (v1.0.0+9), ROADMAP Phase 1 — Core Foundation & Shared Logic, ROADMAP Phase 3 — Product Management (The Catalog), ROADMAP Phase 4 — POS Interface (Main Flow), Append-Only Audit Log, Drift Schema — Full v1 Table List (+6 more)

### Community 60 - "schema_v8.dart"
Cohesion: 0.02
Nodes (97): AuditLog, Expenses, OrderTaxOverrides, TaxGroupMembers, TaxGroups, action, actualTableName, address (+89 more)

### Community 61 - "_StoreProfileEditScreenState"
Cohesion: 0.42
Nodes (10): businessAddressProvider, businessNameProvider, businessPanProvider, businessPhoneProvider, businessTaglineProvider, didChangeDependencies, _StoreProfileEditScreenState, build (+2 more)

### Community 62 - "currencyFormatterProvider"
Cohesion: 0.23
Nodes (12): posFilterProvider, build, CartScreen, _CartScreenState, initState, build, _orderDetailProvider, OrderDetailScreen (+4 more)

### Community 63 - "expenses_dao.dart"
Cohesion: 0.15
Nodes (12): getAll, getAllCategories, insert, insertCategory, totalForPeriod, updateExpense, upsertCategory, watchAll (+4 more)

### Community 64 - "customers_table.dart"
Cohesion: 0.14
Nodes (13): address, createdAt, Customers, defaultDiscount, defaultDiscountIsPercent, email, id, isTaxExempt (+5 more)

### Community 65 - "expenses_table.dart"
Cohesion: 0.15
Nodes (12): amount, categoryId, createdAt, date, Expenses, id, isRecurring, isTaxDeductible (+4 more)

### Community 66 - "cart_summary.dart"
Cohesion: 0.11
Nodes (17): amount, CartSummary, isInclusive, loyaltyDiscount, name, orderDiscount, pointsToEarn, rate (+9 more)

### Community 67 - "Table"
Cohesion: 0.04
Nodes (101): Table, TableInfo, AuditLog, Categories, Customers, ExpenseCategories, Expenses, OrderItems (+93 more)

### Community 68 - "render_receipt.dart"
Cohesion: 0.15
Nodes (12): bytes, customerName, g, _kv, method, methodLabel, profile, renderReceiptBytes (+4 more)

### Community 69 - "Riverpod Architecture Decision (provider type per concern)"
Cohesion: 0.20
Nodes (12): Data Flow (UI to Notifier to DAO to Stream), State Management Pillar (Riverpod), build_runner Code Generation Workflow, Provider Suffix Naming Convention, Code Generation Dev Dependencies (riverpod_generator, drift_dev, build_runner), build.yaml Code Generation Config, Generated-File Exclusion (*.g.dart, *.freezed.dart), Riverpod as Sole DI Mechanism (+4 more)

### Community 70 - "Offline-First Non-Negotiable Constraint"
Cohesion: 0.18
Nodes (12): Package-Imports-Only Rule, Zero External APIs / Services, No Error Tracking, Analytics, or CI Pipeline, Enforced Lint Rules (analysis_options), Deleted Sync/Cloud-Backup Scaffolding (must not return), Platform Network Permission Lockdown, Offline-First Non-Negotiable Constraint, url_launcher Network-Adjacent Exception (+4 more)

### Community 71 - "TextColumn get"
Cohesion: 0.12
Nodes (15): @DataClassName, DateTimeColumn get, capacity, createdAt, id, name, notes, Tables (+7 more)

### Community 72 - "order_items_table.dart"
Cohesion: 0.15
Nodes (12): discount, id, lineTotal, orderId, OrderItems, productId, productName, quantity (+4 more)

### Community 73 - "CurrencyFormatter"
Cohesion: 0.20
Nodes (9): CurrencyFormatter, decimalDigits, _fmt, format, formatPlain, locale, symbol, tryParse (+1 more)

### Community 74 - "app_sheet.dart"
Cohesion: 0.17
Nodes (10): cs, failurePrefix, messenger, draggable, initialSize, minSize, package:pos_app/shared/widgets/keyboard_safe.dart, required WidgetBuilder builder,
  bool (+2 more)

### Community 75 - "snapshot_service.dart"
Cohesion: 0.07
Nodes (26): File, create, createdAt, dbBytes, dbEntryName, _decode, fileNameFor, filePrefix (+18 more)

### Community 76 - "held_ticket_number_test.dart"
Cohesion: 0.12
Nodes (17): Box, dart:io, Directory, _box, _kFavoriteProductIds, toggle, package:hive_flutter/hive_flutter.dart, package:pos_app/features/cart/data/ticket_sequence.dart (+9 more)

### Community 77 - "settings_screen.dart"
Cohesion: 0.15
Nodes (12): build, package:pos_app/features/settings/presentation/widgets/appearance_section.dart, package:pos_app/features/settings/presentation/widgets/backup_section.dart, package:pos_app/features/settings/presentation/widgets/currency_section.dart, package:pos_app/features/settings/presentation/widgets/danger_section.dart, package:pos_app/features/settings/presentation/widgets/inventory_section.dart, package:pos_app/features/settings/presentation/widgets/loyalty_section.dart, package:pos_app/features/settings/presentation/widgets/printer_section.dart (+4 more)

### Community 78 - "_"
Cohesion: 0.14
Nodes (14): _, CartCalculator, compute, _roundingModeFor, package:pos_app/core/utils/tax_calculator.dart, package:pos_app/features/cart/domain/cart_calculator.dart, package:pos_app/features/cart/domain/cart_session.dart, package:pos_app/features/cart/domain/cart_summary.dart (+6 more)

### Community 79 - "databaseProvider"
Cohesion: 0.09
Nodes (22): databaseProvider, _delete, _save, _delete, _save, _showAddCategoryDialog, category, _colorFor (+14 more)

### Community 80 - "audit_log_table.dart"
Cohesion: 0.20
Nodes (9): action, AuditLog, createdAt, entityId, entityType, id, metadata, newValue (+1 more)

### Community 81 - "schema_v7.dart"
Cohesion: 0.02
Nodes (96): Categories, Customers, OrderTaxes, ProductComponents, StockAdjustments, action, actualTableName, address (+88 more)

### Community 82 - "money.dart"
Cohesion: 0.13
Nodes (14): allowZero, eps, isRequired, kMaxMoneyAmount, kMaxMoneyAmountLabel, noun, nudged, null (+6 more)

### Community 83 - "Feature-First Layered Architecture"
Cohesion: 0.22
Nodes (9): lib/ Directory Structure (core, features, shared), Feature-First Layered Architecture, Presentation-Domain-Data Feature Pattern, graphify Knowledge Graph Workflow, Core Mission (100% offline POS), Guiding Principles (offline-first, hardware, feature-first, premium), Offline-First Flutter POS (project charter), README (unmodified Flutter template) (+1 more)

### Community 84 - "Dependency Audit (2026-04-22)"
Cohesion: 0.28
Nodes (9): Hardware Integration Pillar (ESC/POS + PDF), PrintingService Abstraction, Dependency Audit (2026-04-22), google_fonts listed as Utility dependency, heathen_printer_plus (documented printer package), Critical Stack Dependencies (drift, riverpod, go_router, pdf, share_plus), flutter_thermal_printer dependency, ROADMAP Phase 5 — Hardware Deep Integration (+1 more)

### Community 85 - "cart_item.dart"
Cohesion: 0.18
Nodes (10): double get, CartItem, copyWith, isTaxable, lineDiscount, lineSubtotal, name, productId (+2 more)

### Community 86 - "backup_repository.dart"
Cohesion: 0.14
Nodes (16): DateTime, BackupRepository, db, exportCustomers, exportExpenses, exportOrders, exportProducts, exportSalesReport (+8 more)

### Community 87 - "schema_v4.dart"
Cohesion: 0.02
Nodes (97): ExpenseCategories, ProductTaxes, ProductVariants, Returns, action, actualTableName, address, _alias (+89 more)

### Community 88 - "Milestone 1 — v1 Foundation & Core POS"
Cohesion: 0.25
Nodes (8): Responsive Desktop POS Layout Rule, Local Auth (no external identity provider), Platform Requirements (Android API 21+, iOS 12+), Milestone 1 — v1 Foundation & Core POS, ROADMAP Phase 2 — Onboarding & Store Configuration, ROADMAP Phase 6 — Order History & Local Reporting, ROADMAP Phase 8 — Final Stabilization, v1 Phase 1 — First-Run & Onboarding

### Community 89 - "place_order_test.dart"
Cohesion: 0.25
Nodes (7): audit, db, main, makeItem, makeSession, makeSummary, seedProduct

### Community 90 - "tables_dao.dart"
Cohesion: 0.25
Nodes (7): deleteById, getAll, getById, upsert, watchAll, package:pos_app/core/database/tables/tables_table.dart, _

### Community 91 - "StatelessWidget"
Cohesion: 0.07
Nodes (30): _QtyButton, _TablePickerSheet, _CategoryChips, _Chip, _ExpenseTile, _TotalBar, build, cs (+22 more)

### Community 92 - "tax_rates_table.dart"
Cohesion: 0.18
Nodes (10): createdAt, id, inclusionType, isActive, isCompound, name, rate, roundingMode (+2 more)

### Community 93 - "ConsumerWidget"
Cohesion: 0.11
Nodes (32): ConsumerWidget, build, CartDetailScreen, _CartLineItem, _OrderSummary, _pickCustomer, _pickTable, _showDiscountSheet (+24 more)

### Community 94 - "Dual Data Layer (Drift + Hive)"
Cohesion: 0.38
Nodes (7): Dual Data Layer (Drift + Hive), Navigation Pillar (GoRouter routerProvider), Drift Layout Convention (tables, daos, AppDatabase migrations), No Hardcoded Colors (AppTheme / colorScheme), Premium Glassmorphic Dark Aesthetic, ROADMAP Phase 7 — Polish & Power Features, v1 Phase 8 — Polish & Theme

### Community 95 - "Banned Runtime-Fetching Packages"
Cohesion: 0.33
Nodes (7): Local-Only Data Storage (Drift file + Hive + path_provider), Banned Runtime-Fetching Packages, Export & Sharing Stack (share_plus, csv, file_picker, permission_handler), Bundled JetBrainsMono Font Family, Connectivity Detection task (0.5, connectivity_plus), v1 Phase 5 — Backup & Data Safety (local-only), v1 Phase 6 — Expenses & Reports

### Community 96 - "app_root.dart"
Cohesion: 0.09
Nodes (27): dart:async, AppRoot, AppRootState, build, child, _container, createState, dispose (+19 more)

### Community 97 - "onboarding_notifier.dart"
Cohesion: 0.13
Nodes (19): settingsBoxProvider, settingsProvider, back, build, finish, next, OnboardingNotifier, setBusinessName (+11 more)

### Community 98 - "schema_v6.dart"
Cohesion: 0.02
Nodes (95): GeneratedColumn, Iterable, OrderItems, Orders, Products, TaxRates, action, actualTableName (+87 more)

### Community 99 - "product_variants_table.dart"
Cohesion: 0.12
Nodes (14): BoolColumn get, color, ExpenseCategories, id, isDefault, name, id, isActive (+6 more)

### Community 100 - "audit_log_screen.dart"
Cohesion: 0.20
Nodes (11): action, _ActionChip, _actionColor, _actionIcon, AuditLogScreen, _auditLogsProvider, build, color (+3 more)

### Community 101 - "SettingsNotifier"
Cohesion: 0.67
Nodes (3): @immutable, AppSettings, SettingsNotifier

### Community 102 - "Open POS Brand Logo"
Cohesion: 0.53
Nodes (6): Interlocking Circular Arrow Mark, Green-to-Blue Gradient Brand Palette, Open POS Brand Logo, OPEN POS Wordmark, Point-of-Sale Product Identity, Transaction Cycle Visual Metaphor

### Community 103 - "native.dart"
Cohesion: 0.20
Nodes (8): databaseFile, dir, kDatabaseFileName, openConnection, package:drift/native.dart, package:path/path.dart, package:path_provider/path_provider.dart, openInMemoryDatabase

### Community 104 - "snapshot_providers.dart"
Cohesion: 0.11
Nodes (17): dart:isolate, autoBackupDir, create, createAndShare, docs, inspect, kAutoBackupInterval, kAutoBackupKeep (+9 more)

### Community 105 - "schema.dart"
Cohesion: 0.17
Nodes (11): package:drift/internal/migrations.dart, schema_v10.dart, schema_v4.dart, schema_v6.dart, schema_v7.dart, schema_v8.dart, schema_v9.dart, SchemaInstantiationHelper (+3 more)

### Community 106 - "inventory_section.dart"
Cohesion: 0.20
Nodes (11): lowStockThresholdProvider, build, createState, _ctrl, current, dispose, _editThreshold, InventorySection (+3 more)

### Community 107 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.09
Nodes (21): dart:ui, int?, _db, DemoDataService, seed, _settings, customerId, customers (+13 more)

### Community 108 - "tables_provider.dart"
Cohesion: 0.21
Nodes (12): _TableSelectorRow, activeHeld, cartTableId, cartTableProvider, occupiedTableIdsProvider, tableId, tables, tablesStreamProvider (+4 more)

### Community 109 - "currencySymbolProvider"
Cohesion: 0.32
Nodes (8): currencyCodeProvider, currencySymbolProvider, build, DashboardScreen, _DashboardScreenState, _reportProvider, build, CurrencySection

### Community 111 - "printerDeviceNameProvider"
Cohesion: 0.35
Nodes (10): printerDeviceAddressProvider, printerDeviceNameProvider, printerPaperWidthProvider, autoPrintOrder, build, _PrinterSetupScreenState, _printTestPage, build (+2 more)

### Community 112 - "occupied_tables_test.dart"
Cohesion: 0.11
Nodes (18): _box, formatTicketNumber, kTicketSeqKey, next, TicketSequence, ticketSequenceProvider, CartSession, CartSessionNotifier (+10 more)

### Community 113 - "customers_dao.dart"
Cohesion: 0.20
Nodes (9): addLoyaltyPoints, getAll, getById, redeemLoyaltyPoints, search, upsert, watchAll, package:pos_app/core/database/tables/customers_table.dart (+1 more)

### Community 114 - "dismiss_keyboard_test.dart"
Cohesion: 0.22
Nodes (7): EditableText, package:pos_app/app.dart, package:pos_app/shared/widgets/dismiss_keyboard.dart, harness, main, main, textFieldHasFocus

### Community 115 - "returns_table.dart"
Cohesion: 0.12
Nodes (15): createdAt, id, orderId, OrderTaxOverrides, originalTax, overrideTax, reason, amount (+7 more)

### Community 116 - "String?"
Cohesion: 0.12
Nodes (15): double?, IconData?, action, AppEmptyState, build, icon, subtitle, title (+7 more)

### Community 117 - "migration_test.dart"
Cohesion: 0.25
Nodes (7): generated/schema.dart, package:drift_dev/api/migrations_common.dart, package:drift_dev/api/migrations_native.dart, SchemaVerifier, main, shipped, verifier

### Community 118 - "package:intl/intl.dart"
Cohesion: 0.25
Nodes (7): buildReceiptText, dateFmt, join, lines, o, package:intl/intl.dart, package:pos_app/features/receipts/presentation/receipt_body.dart

### Community 119 - "main.dart"
Cohesion: 0.40
Nodes (4): initFlutter, main, package:pos_app/app_root.dart, package:pos_app/features/backup/data/snapshot_providers.dart

### Community 120 - "order_number.dart"
Cohesion: 0.40
Nodes (4): int get, billNo, displayNo, String get

### Community 121 - "build"
Cohesion: 0.25
Nodes (9): build, build, Route /customers, Route /expenses, Route /help/shortcuts, Route /inventory, Route /orders, Route /settings (+1 more)

### Community 122 - "GeneratedDatabase"
Cohesion: 0.29
Nodes (7): GeneratedDatabase, DatabaseAtV10, DatabaseAtV4, DatabaseAtV6, DatabaseAtV7, DatabaseAtV8, DatabaseAtV9

### Community 123 - "tax_dao.dart"
Cohesion: 0.22
Nodes (8): getAll, getById, getRatesForProduct, setProductTaxes, upsertRate, watchActive, package:pos_app/core/database/tables/product_taxes_table.dart, _

### Community 124 - "categories_table.dart"
Cohesion: 0.22
Nodes (8): Categories, createdAt, id, name, parentId, sortOrder, taxRateId, updatedAt

### Community 125 - "defaultTaxIdProvider"
Cohesion: 0.36
Nodes (8): defaultTaxIdProvider, build, reset, taxRatesStreamProvider, build, TaxSection, build, TaxSettingsScreen

### Community 126 - "package:pos_app/shared/widgets/app_sheet.dart"
Cohesion: 0.33
Nodes (5): _CurrencyPickerSheet, current, _showCurrencyPicker, package:pos_app/features/settings/domain/currencies.dart, package:pos_app/shared/widgets/app_sheet.dart

### Community 128 - "LoyaltySection"
Cohesion: 0.60
Nodes (5): loyaltyEarnRateProvider, loyaltyEnabledProvider, loyaltyPointValueProvider, build, LoyaltySection

## Ambiguous Edges - Review These
- `Responsive Desktop POS Layout Rule` → `Platform Requirements (Android API 21+, iOS 12+)`  [AMBIGUOUS]
  .planning/codebase/CONVENTIONS.md · relation: conceptually_related_to
- `pos_app Package Manifest (v1.0.0+9)` → `v1 Phase 3 — Core Sales Loop`  [AMBIGUOUS]
  v1_roadmap.md · relation: references
- `pos_app Package Manifest (v1.0.0+9)` → `v1 Phase 7 — Customers, Loyalty & Audit`  [AMBIGUOUS]
  v1_roadmap.md · relation: references

## Knowledge Gaps
- **2098 isolated node(s):** `refresh`, `getKeyboardDismissBehavior`, `_slide`, `ping`, `_container` (+2093 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **4 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `Responsive Desktop POS Layout Rule` and `Platform Requirements (Android API 21+, iOS 12+)`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **What is the exact relationship between `pos_app Package Manifest (v1.0.0+9)` and `v1 Phase 3 — Core Sales Loop`?**
  _Edge tagged AMBIGUOUS (relation: references) - confidence is low._
- **What is the exact relationship between `pos_app Package Manifest (v1.0.0+9)` and `v1 Phase 7 — Customers, Loyalty & Audit`?**
  _Edge tagged AMBIGUOUS (relation: references) - confidence is low._
- **Why does `Return` connect `DataClass` to `app_database.dart`, `products_provider.dart`, `render_receipt.dart`, `customers_screen.dart`, `package:pos_app/core/database/app_database.dart`, `money.dart`, `receipt_pdf_service.dart`?**
  _High betweenness centrality (0.024) - this node is a cross-community bridge._
- **Why does `_` connect `_` to `package:flutter_test/flutter_test.dart`, `package:pos_app/core/database/app_database.dart`?**
  _High betweenness centrality (0.011) - this node is a cross-community bridge._
- **Why does `Product` connect `DataClass` to `app_database.dart`, `product_tile.dart`, `inventory_screen.dart`, `grid_product_tile.dart`, `product_form_screen.dart`, `products_screen.dart`?**
  _High betweenness centrality (0.007) - this node is a cross-community bridge._
- **What connects `refresh`, `getKeyboardDismissBehavior`, `_slide` to the rest of the system?**
  _2098 weakly-connected nodes found - possible documentation gaps or missing edges._