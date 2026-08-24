# Graph Report - offlinePOS  (2026-08-23)

## Corpus Check
- 204 files · ~159,580 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 3498 nodes · 5527 edges · 140 communities (137 shown, 3 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 69 edges (avg confidence: 0.88)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `8c4d6c24`
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
- report_data.dart
- products_dao.dart
- customers_screen.dart
- app.dart
- schema_v12.dart
- app_theme.dart
- orders_dao.dart
- held_tickets_bar.dart
- StatelessWidget
- product_form_screen.dart
- receipt_pdf_service.dart
- orders_screen.dart
- order_detail_screen.dart
- package:flutter/material.dart
- schema_v10.dart
- String?
- backup_screen.dart
- products_screen.dart
- snapshot_service_test.dart
- printer_setup_screen.dart
- payment_screen.dart
- receipt_screen.dart
- tables_screen.dart
- AppDatabase
- tron_border.dart
- receipt_body.dart
- country_default.dart
- products_provider.dart
- held_order.dart
- tokens.dart
- product_tile.dart
- learn_screen.dart
- pos_filter_provider.dart
- audit_service.dart
- IntColumn get
- orders_table.dart
- schema.dart
- article_detail_screen.dart
- onboardingNotifierProvider
- store_profile_edit_screen.dart
- tax_settings_screen.dart
- grid_product_tile.dart
- loyalty_section.dart
- render_receipt_test.dart
- schema_v9.dart
- cart_session.dart
- products_table.dart
- held_orders_notifier.dart
- cartSessionProvider
- package:drift/drift.dart
- tax_dao.dart
- pos_app Package Manifest (v1.0.0+9)
- schema_v8.dart
- _StoreProfileEditScreenState
- auto_print_test.dart
- expenses_table.dart
- customers_table.dart
- customers_dao.dart
- cart_summary.dart
- Table
- render_receipt.dart
- Riverpod Architecture Decision (provider type per concern)
- Offline-First Non-Negotiable Constraint
- TextColumn get
- thermal_plugin_printer.dart
- schema_v11.dart
- app_sheet.dart
- snapshot_service.dart
- held_ticket_number_test.dart
- settings_screen.dart
- _
- databaseProvider
- _PrinterSetupScreenState
- schema_v7.dart
- money.dart
- Feature-First Layered Architecture
- Dependency Audit (2026-04-22)
- cart_item.dart
- backup_repository.dart
- schema_v4.dart
- Milestone 1 — v1 Foundation & Core POS
- inventory_card.dart
- appearance_section.dart
- order_summary.dart
- customer_form.dart
- ConsumerWidget
- Dual Data Layer (Drift + Hive)
- Banned Runtime-Fetching Packages
- app_root.dart
- auto_print.dart
- schema_v6.dart
- settingsProvider
- audit_log_screen.dart
- package:pos_app/core/database/app_database.dart
- Open POS Brand Logo
- IconData?
- snapshot_providers.dart
- dashboard_body.dart
- inventory_screen.dart
- package:flutter_riverpod/flutter_riverpod.dart
- _ExpensesScreenState
- inventory_section.dart
- custom_lint Analyzer Plugin (enabled in analysis_options)
- package:flutter/services.dart
- occupied_tables_test.dart
- receipt_printer.dart
- shortcuts_screen.dart
- wizard_header.dart
- side_nav.dart
- migration_test.dart
- build
- tax_rates_table.dart
- order_number.dart
- ConsumerState
- GeneratedDatabase
- country_repository.dart
- VoidCallback?
- onboarding_notifier.dart
- _
- onboarding_state.dart
- customer_picker_sheet.dart
- ticket_header.dart
- List
- package:pos_app/core/utils/currency_formatter.dart
- currencies.dart
- Return
- discount_sheet.dart
- country_step.dart
- cart_calculator_test.dart
- main.dart
- ReceiptPrinter
- ReportPeriod

## God Nodes (most connected - your core abstractions)
1. `databaseProvider` - 34 edges
2. `cartSessionProvider` - 26 edges
3. `AppDatabase` - 23 edges
4. `currencyFormatterProvider` - 20 edges
5. `DataClass` - 19 edges
6. `settingsProvider` - 19 edges
7. `cartProvider` - 18 edges
8. `CurrencyFormatter` - 14 edges
9. `_PaymentScreenState` - 14 edges
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

## Communities (140 total, 3 thin omitted)

### Community 0 - "app_database.dart"
Cohesion: 0.01
Nodes (242): class OrderTaxOverride extends, class ProductComponent extends, ColumnFilters, ColumnOrderings, backfillInvoiceNumbers, currentSchemaVersion, migration, _openConnection (+234 more)

### Community 1 - "dashboard_screen.dart"
Cohesion: 0.10
Nodes (22): DateTimeRange?, currencyCodeProvider, currencySymbolProvider, reportProvider, build, createState, _customRange, DashboardScreen (+14 more)

### Community 2 - "cart_notifier.dart"
Cohesion: 0.11
Nodes (17): add, addItem, addProduct, allRates, compute, itemCount, _nextTicketNumber, remove (+9 more)

### Community 3 - "onboarding_screen.dart"
Cohesion: 0.09
Nodes (22): _businessNameCtrl, _canProceed, _countries, createState, dispose, _filterCountries, _filtered, _loadingCountries (+14 more)

### Community 4 - "DataClass"
Cohesion: 0.10
Nodes (38): Insertable, OrderNumberX, UpdateCompanion, AuditLogCompanion, AuditLogData, CategoriesCompanion, Category, Customer (+30 more)

### Community 5 - "hive_provider.dart"
Cohesion: 0.03
Nodes (69): autoBackupEnabled, autoBackupLastAt, _box, build, businessAddress, businessName, businessNameOrDefault, businessPan (+61 more)

### Community 6 - "expenses_screen.dart"
Cohesion: 0.05
Nodes (37): _amountCtrl, categories, category, _CategoryChips, _categoryId, _Chip, color, createState (+29 more)

### Community 7 - "home.dart"
Cohesion: 0.06
Nodes (36): demoDataServiceProvider, _applyFilter, cart, categories, _CategoryRow, _Chip, createState, dispose (+28 more)

### Community 8 - "report_data.dart"
Cohesion: 0.06
Nodes (30): avgOrder, chartDates, chartHighlightIndex, chartTitle, chartTotals, count, days, db (+22 more)

### Community 9 - "products_dao.dart"
Cohesion: 0.10
Nodes (20): adjustStock, deductStock, deleteCategory, getAllCategories, getById, getBySku, getComponents, replaceComponents (+12 more)

### Community 10 - "customers_screen.dart"
Cohesion: 0.12
Nodes (17): IconData get, createState, CustomersScreen, _CustomersScreenState, dispose, _filterAndSort, icon, label (+9 more)

### Community 11 - "app.dart"
Cohesion: 0.04
Nodes (44): ChangeNotifier, EditableText, GoRouter, AppScrollBehavior, getKeyboardDismissBehavior, ping, POSApp, refresh (+36 more)

### Community 12 - "schema_v12.dart"
Cohesion: 0.02
Nodes (99): Tables, TaxGroupMembers, action, actualTableName, address, _alias, aliasedName, allSchemaEntities (+91 more)

### Community 13 - "app_theme.dart"
Cohesion: 0.11
Nodes (18): AppTheme, backgroundGradient, _build, ctaButtonStyle, dark, _darkGrad, _darkScheme, _fontFamily (+10 more)

### Community 14 - "orders_dao.dart"
Cohesion: 0.08
Nodes (23): getAllOrdersWithItems, getById, getItems, getTaxBreakdown, incrementPrintCount, insertItems, insertOrder, insertReturn (+15 more)

### Community 15 - "held_tickets_bar.dart"
Cohesion: 0.12
Nodes (19): AnimationController, heldOrdersProvider, build, CheckoutBar, _buildActiveList, _buildArchivedList, createState, _ctrl (+11 more)

### Community 16 - "StatelessWidget"
Cohesion: 0.08
Nodes (27): build, cs, gradient, icon, _InfoRow, label, onTap, _SectionHeader (+19 more)

### Community 17 - "product_form_screen.dart"
Cohesion: 0.06
Nodes (34): _categoryId, _ComponentEntry, _components, _conversionCtrl, createState, _delete, didChangeDependencies, dispose (+26 more)

### Community 18 - "receipt_pdf_service.dart"
Cohesion: 0.07
Nodes (27): baseStyle, billRow, boldStyle, buildReceiptPdf, bytes, customerName, data, _dataCell (+19 more)

### Community 19 - "orders_screen.dart"
Cohesion: 0.08
Nodes (24): createState, cs, customerName, _filter, fmt, _groupByDate, icon, label (+16 more)

### Community 20 - "order_detail_screen.dart"
Cohesion: 0.09
Nodes (21): auditServiceProvider, businessName, customer, data, db, _DetailBody, _DetailData, fmt (+13 more)

### Community 21 - "package:flutter/material.dart"
Cohesion: 0.08
Nodes (22): BackupSection, build, build, SettingsSectionHeader, title, build, ThemePreviewScreen, action (+14 more)

### Community 22 - "schema_v10.dart"
Cohesion: 0.02
Nodes (120): Index, ProductVariants, action, actualTableName, address, _alias, aliasedName, allSchemaEntities (+112 more)

### Community 23 - "String?"
Cohesion: 0.10
Nodes (19): double?, build, _Chip, color, InventoryFilterBar, label, lowCount, onSelect (+11 more)

### Community 24 - "backup_screen.dart"
Cohesion: 0.06
Nodes (36): autoBackupEnabledProvider, autoBackupLastAtProvider, backupRepositoryProvider, snapshotCoordinatorProvider, _AutoBackupTile, BackupScreen, _BackupScreenState, _BackupTile (+28 more)

### Community 25 - "products_screen.dart"
Cohesion: 0.09
Nodes (22): _applyFilter, categories, _CategoryChips, categoryName, _Chip, createState, cs, dispose (+14 more)

### Community 26 - "snapshot_service_test.dart"
Cohesion: 0.18
Nodes (10): package:pos_app/features/backup/data/snapshot_service.dart, dbFileIn, hivePathIn, live, main, openDb, restored, seedLive (+2 more)

### Community 27 - "printer_setup_screen.dart"
Cohesion: 0.12
Nodes (16): createState, _devices, _devicesSub, _disconnectSavedPrinter, dispose, initState, _printer, _scanning (+8 more)

### Community 28 - "payment_screen.dart"
Cohesion: 0.08
Nodes (25): dart:ui, createState, customer, dispose, fmt, icon, label, _loyaltyCtrl (+17 more)

### Community 29 - "receipt_screen.dart"
Cohesion: 0.10
Nodes (21): build, businessName, customer, data, db, fmt, _handle, items (+13 more)

### Community 30 - "tables_screen.dart"
Cohesion: 0.10
Nodes (19): _assignToCart, _capacityCtrl, createState, dispose, existing, initState, isCurrentCartTable, isOccupied (+11 more)

### Community 31 - "AppDatabase"
Cohesion: 0.11
Nodes (27): _, @DriftAccessor, @DriftDatabase, _$AuditDaoMixin, _$CustomersDaoMixin, DatabaseAccessor, _$ExpensesDaoMixin, _$InventoryDaoMixin (+19 more)

### Community 32 - "tron_border.dart"
Cohesion: 0.14
Nodes (13): CustomPainter, dart:math, color, e, extractWrappedPath, f, len, p (+5 more)

### Community 33 - "receipt_body.dart"
Cohesion: 0.10
Nodes (20): _BillRow, build, businessName, customer, data, _DataCell, fmt, _HeaderCell (+12 more)

### Community 34 - "country_default.dart"
Cohesion: 0.20
Nodes (9): code, CountryDefault, currency, fromJson, name, symbol, taxName, taxRate (+1 more)

### Community 35 - "products_provider.dart"
Cohesion: 0.13
Nodes (15): clearSearch, copyWith, outOfStockOnly, ProductsFilterNotifier, ProductsFilterState, ref, search, selectedCategoryId (+7 more)

### Community 36 - "held_order.dart"
Cohesion: 0.11
Nodes (18): archivedAt, copyWith, createdAt, customerId, customerName, fromJson, id, isArchived (+10 more)

### Community 37 - "tokens.dart"
Cohesion: 0.11
Nodes (18): AppFonts, AppOpacity, heavy, lg, md, medium, mono, Radii (+10 more)

### Community 38 - "product_tile.dart"
Cohesion: 0.11
Nodes (18): bg, build, color, cs, fmt, icon, isFavorite, onDecrement (+10 more)

### Community 39 - "learn_screen.dart"
Cohesion: 0.12
Nodes (16): _Article, _ArticleCard, _articles, build, category, cs, description, icon (+8 more)

### Community 40 - "pos_filter_provider.dart"
Cohesion: 0.12
Nodes (16): clearSearch, copyWith, favoritesOnly, isGrid, PosFilterNotifier, PosFilterState, PosSortMode, search (+8 more)

### Community 41 - "audit_service.dart"
Cohesion: 0.25
Nodes (7): _db, log, orderPlaced, orderRefunded, orderVoided, settingChanged, taxOverridden

### Community 42 - "IntColumn get"
Cohesion: 0.05
Nodes (40): IntColumn get, discount, id, lineTotal, orderId, OrderItems, productId, productName (+32 more)

### Community 43 - "orders_table.dart"
Cohesion: 0.06
Nodes (31): @TableIndex, deleteById, getAll, getById, upsert, watchAll, changeAmount, createdAt (+23 more)

### Community 44 - "schema.dart"
Cohesion: 0.14
Nodes (13): package:drift/internal/migrations.dart, schema_v10.dart, schema_v11.dart, schema_v12.dart, schema_v4.dart, schema_v6.dart, schema_v7.dart, schema_v8.dart (+5 more)

### Community 45 - "article_detail_screen.dart"
Cohesion: 0.11
Nodes (17): ArticleDetailScreen, ArticleSection, build, category, cs, heading, icon, readTime (+9 more)

### Community 46 - "onboardingNotifierProvider"
Cohesion: 0.20
Nodes (11): build, onboardingNotifierProvider, _back, build, _finish, initState, _loadCountries, _next (+3 more)

### Community 47 - "store_profile_edit_screen.dart"
Cohesion: 0.15
Nodes (12): class, _addressCtrl, build, createState, dispose, _initialised, _label, _loading (+4 more)

### Community 48 - "tax_settings_screen.dart"
Cohesion: 0.13
Nodes (15): FormState, createState, dispose, existing, _formKey, _inclusionType, _nameCtrl, onAdd (+7 more)

### Community 49 - "grid_product_tile.dart"
Cohesion: 0.09
Nodes (20): CurrencyFormatter, decimalDigits, _fmt, format, formatPlain, locale, symbol, tryParse (+12 more)

### Community 50 - "loyalty_section.dart"
Cohesion: 0.17
Nodes (14): loyaltyEarnRateProvider, loyaltyEnabledProvider, loyaltyPointValueProvider, build, createState, dispose, _earnCtrl, earnRate (+6 more)

### Community 51 - "render_receipt_test.dart"
Cohesion: 0.22
Nodes (8): package:pos_app/features/printing/domain/render_receipt.dart, fmt, item, main, null, order, _sampleData, tax

### Community 52 - "schema_v9.dart"
Cohesion: 0.02
Nodes (96): OrderItems, Returns, action, actualTableName, address, _alias, aliasedName, allSchemaEntities (+88 more)

### Community 53 - "cart_session.dart"
Cohesion: 0.14
Nodes (13): bool get, copyWith, customerId, fresh, heldTicketId, isEditingHeldTicket, loyaltyPointsToRedeem, openedAt (+5 more)

### Community 54 - "products_table.dart"
Cohesion: 0.10
Nodes (20): categoryId, conversionRate, createdAt, id, imagePath, isActive, isComposite, isHiddenInPos (+12 more)

### Community 55 - "held_orders_notifier.dart"
Cohesion: 0.10
Nodes (20): heldOrdersBoxProvider, HeldOrder, archive, archiveAll, _box, build, delete, deleteAllArchived (+12 more)

### Community 56 - "cartSessionProvider"
Cohesion: 0.11
Nodes (24): cartSessionProvider, clear, build, _showDiscountSheet, build, occupied, onSelect, _pickTable (+16 more)

### Community 57 - "package:drift/drift.dart"
Cohesion: 0.09
Nodes (19): openConnection, getAdjustmentsForProduct, logAdjustment, watchLowStock, createdAt, delta, id, notes (+11 more)

### Community 58 - "tax_dao.dart"
Cohesion: 0.09
Nodes (21): getAll, getById, getRatesForProduct, setProductTaxes, upsertRate, watchActive, primaryKey, productId (+13 more)

### Community 59 - "pos_app Package Manifest (v1.0.0+9)"
Cohesion: 0.19
Nodes (14): drift as Critical Persistence Dependency, Technology Stack (Dart 3.5+, Flutter 3.24+), pos_app Package Manifest (v1.0.0+9), ROADMAP Phase 1 — Core Foundation & Shared Logic, ROADMAP Phase 3 — Product Management (The Catalog), ROADMAP Phase 4 — POS Interface (Main Flow), Append-Only Audit Log, Drift Schema — Full v1 Table List (+6 more)

### Community 60 - "schema_v8.dart"
Cohesion: 0.02
Nodes (93): Customers, OrderTaxes, ProductTaxes, action, actualTableName, address, _alias, aliasedName (+85 more)

### Community 61 - "_StoreProfileEditScreenState"
Cohesion: 0.42
Nodes (10): businessAddressProvider, businessNameProvider, businessPanProvider, businessPhoneProvider, businessTaglineProvider, didChangeDependencies, _StoreProfileEditScreenState, build (+2 more)

### Community 62 - "auto_print_test.dart"
Cohesion: 0.12
Nodes (16): Object?, package:pos_app/features/printing/domain/auto_print.dart, box, bytesContain, db, devices, failWith, main (+8 more)

### Community 63 - "expenses_table.dart"
Cohesion: 0.08
Nodes (24): getAll, getAllCategories, insert, insertCategory, totalForPeriod, updateExpense, upsertCategory, watchAll (+16 more)

### Community 64 - "customers_table.dart"
Cohesion: 0.14
Nodes (13): address, createdAt, Customers, defaultDiscount, defaultDiscountIsPercent, email, id, isTaxExempt (+5 more)

### Community 65 - "customers_dao.dart"
Cohesion: 0.20
Nodes (9): addLoyaltyPoints, getAll, getById, redeemLoyaltyPoints, search, upsert, watchAll, package:pos_app/core/database/tables/customers_table.dart (+1 more)

### Community 66 - "cart_summary.dart"
Cohesion: 0.11
Nodes (17): amount, CartSummary, isInclusive, loyaltyDiscount, name, orderDiscount, pointsToEarn, rate (+9 more)

### Community 67 - "Table"
Cohesion: 0.03
Nodes (139): Table, TableInfo, AuditLog, Categories, Customers, ExpenseCategories, Expenses, OrderItems (+131 more)

### Community 68 - "render_receipt.dart"
Cohesion: 0.14
Nodes (13): bytes, customerName, g, isCopy, _kv, method, methodLabel, profile (+5 more)

### Community 69 - "Riverpod Architecture Decision (provider type per concern)"
Cohesion: 0.20
Nodes (12): Data Flow (UI to Notifier to DAO to Stream), State Management Pillar (Riverpod), build_runner Code Generation Workflow, Provider Suffix Naming Convention, Code Generation Dev Dependencies (riverpod_generator, drift_dev, build_runner), build.yaml Code Generation Config, Generated-File Exclusion (*.g.dart, *.freezed.dart), Riverpod as Sole DI Mechanism (+4 more)

### Community 70 - "Offline-First Non-Negotiable Constraint"
Cohesion: 0.18
Nodes (12): Package-Imports-Only Rule, Zero External APIs / Services, No Error Tracking, Analytics, or CI Pipeline, Enforced Lint Rules (analysis_options), Deleted Sync/Cloud-Backup Scaffolding (must not return), Platform Network Permission Lockdown, Offline-First Non-Negotiable Constraint, url_launcher Network-Adjacent Exception (+4 more)

### Community 71 - "TextColumn get"
Cohesion: 0.06
Nodes (32): @DataClassName, DateTimeColumn get, action, AuditLog, createdAt, entityId, entityType, id (+24 more)

### Community 72 - "thermal_plugin_printer.dart"
Cohesion: 0.20
Nodes (9): devices, _ftp, printBytes, startScan, stopScan, package:flutter_thermal_printer/flutter_thermal_printer.dart, package:flutter_thermal_printer/utils/printer.dart, package:pos_app/features/printing/domain/receipt_printer.dart (+1 more)

### Community 73 - "schema_v11.dart"
Cohesion: 0.02
Nodes (101): GeneratedColumn, action, actualTableName, address, _alias, aliasedName, allSchemaEntities, allTables (+93 more)

### Community 74 - "app_sheet.dart"
Cohesion: 0.17
Nodes (10): cs, failurePrefix, messenger, draggable, initialSize, minSize, package:pos_app/shared/widgets/keyboard_safe.dart, required WidgetBuilder builder,
  bool (+2 more)

### Community 75 - "snapshot_service.dart"
Cohesion: 0.07
Nodes (28): Exception, File, create, createdAt, dbBytes, dbEntryName, _decode, fileNameFor (+20 more)

### Community 76 - "held_ticket_number_test.dart"
Cohesion: 0.12
Nodes (17): Box, dart:io, Directory, _box, _kFavoriteProductIds, toggle, package:hive_flutter/hive_flutter.dart, package:pos_app/features/cart/data/ticket_sequence.dart (+9 more)

### Community 77 - "settings_screen.dart"
Cohesion: 0.17
Nodes (11): build, package:pos_app/features/settings/presentation/widgets/appearance_section.dart, package:pos_app/features/settings/presentation/widgets/backup_section.dart, package:pos_app/features/settings/presentation/widgets/currency_section.dart, package:pos_app/features/settings/presentation/widgets/danger_section.dart, package:pos_app/features/settings/presentation/widgets/inventory_section.dart, package:pos_app/features/settings/presentation/widgets/loyalty_section.dart, package:pos_app/features/settings/presentation/widgets/printer_section.dart (+3 more)

### Community 78 - "_"
Cohesion: 0.33
Nodes (7): _, CartCalculator, compute, _roundingModeFor, package:pos_app/core/utils/tax_calculator.dart, package:pos_app/features/cart/domain/cart_session.dart, package:pos_app/features/cart/domain/cart_summary.dart

### Community 79 - "databaseProvider"
Cohesion: 0.08
Nodes (28): databaseProvider, _delete, _save, _showAddCategoryDialog, categoriesStreamProvider, productsByCategoryProvider, build, CategoriesScreen (+20 more)

### Community 80 - "_PrinterSetupScreenState"
Cohesion: 0.36
Nodes (9): printerDeviceAddressProvider, printerDeviceNameProvider, printerPaperWidthProvider, receiptPrinterProvider, build, PrinterSetupScreen, _PrinterSetupScreenState, _printTestPage (+1 more)

### Community 81 - "schema_v7.dart"
Cohesion: 0.02
Nodes (91): ExpenseCategories, Expenses, ProductModifiers, TaxRates, action, actualTableName, address, _alias (+83 more)

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
Nodes (92): Iterable, ProductComponents, Products, StockAdjustments, action, actualTableName, address, _alias (+84 more)

### Community 88 - "Milestone 1 — v1 Foundation & Core POS"
Cohesion: 0.25
Nodes (8): Responsive Desktop POS Layout Rule, Local Auth (no external identity provider), Platform Requirements (Android API 21+, iOS 12+), Milestone 1 — v1 Foundation & Core POS, ROADMAP Phase 2 — Onboarding & Store Configuration, ROADMAP Phase 6 — Order History & Local Reporting, ROADMAP Phase 8 — Final Stabilization, v1 Phase 1 — First-Run & Onboarding

### Community 89 - "inventory_card.dart"
Cohesion: 0.10
Nodes (19): _apply, badgeColor, build, canDecrement, canIncrement, cs, _decrement, icon (+11 more)

### Community 90 - "appearance_section.dart"
Cohesion: 0.25
Nodes (8): themeModeProvider, AppearanceSection, build, current, _options, _showThemePicker, _ThemePickerSheet, ThemeMode

### Community 91 - "order_summary.dart"
Cohesion: 0.12
Nodes (15): addColor, cs, fmt, label, onTap, ref, _showTaxPicker, summary (+7 more)

### Community 92 - "customer_form.dart"
Cohesion: 0.12
Nodes (17): _addressCtrl, build, createState, customer, CustomerForm, _CustomerFormState, _delete, _discountCtrl (+9 more)

### Community 93 - "ConsumerWidget"
Cohesion: 0.11
Nodes (27): ConsumerWidget, build, CartDetailScreen, build, initState, _PaymentActionBar, _PaymentScreenState, _placeOrder (+19 more)

### Community 94 - "Dual Data Layer (Drift + Hive)"
Cohesion: 0.38
Nodes (7): Dual Data Layer (Drift + Hive), Navigation Pillar (GoRouter routerProvider), Drift Layout Convention (tables, daos, AppDatabase migrations), No Hardcoded Colors (AppTheme / colorScheme), Premium Glassmorphic Dark Aesthetic, ROADMAP Phase 7 — Polish & Power Features, v1 Phase 8 — Polish & Theme

### Community 95 - "Banned Runtime-Fetching Packages"
Cohesion: 0.33
Nodes (7): Local-Only Data Storage (Drift file + Hive + path_provider), Banned Runtime-Fetching Packages, Export & Sharing Stack (share_plus, csv, file_picker, permission_handler), Bundled JetBrainsMono Font Family, Connectivity Detection task (0.5, connectivity_plus), v1 Phase 5 — Backup & Data Safety (local-only), v1 Phase 6 — Expenses & Reports

### Community 96 - "app_root.dart"
Cohesion: 0.10
Nodes (23): dart:async, AppRoot, AppRootState, build, child, _container, createState, dispose (+15 more)

### Community 97 - "auto_print.dart"
Cohesion: 0.25
Nodes (7): autoPrintOrder, AutoPrintService, autoPrintServiceProvider, printOrder, _ref, package:pos_app/features/receipts/presentation/receipt_body.dart, Ref

### Community 98 - "schema_v6.dart"
Cohesion: 0.02
Nodes (90): AuditLog, Categories, Orders, OrderTaxOverrides, TaxGroups, action, actualTableName, address (+82 more)

### Community 99 - "settingsProvider"
Cohesion: 0.17
Nodes (17): int?, defaultTaxIdProvider, invoicePrefixProvider, settingsProvider, build, reset, taxRatesStreamProvider, _save (+9 more)

### Community 100 - "audit_log_screen.dart"
Cohesion: 0.20
Nodes (11): action, _ActionChip, _actionColor, _actionIcon, AuditLogScreen, _auditLogsProvider, build, color (+3 more)

### Community 101 - "package:pos_app/core/database/app_database.dart"
Cohesion: 0.05
Nodes (49): AuditService, invoicePrefix, placeOrder, transaction, processReturn, transaction, transaction, voidOrder (+41 more)

### Community 102 - "Open POS Brand Logo"
Cohesion: 0.53
Nodes (6): Interlocking Circular Arrow Mark, Green-to-Blue Gradient Brand Palette, Open POS Brand Logo, OPEN POS Wordmark, Point-of-Sale Product Identity, Transaction Cycle Visual Metaphor

### Community 103 - "IconData?"
Cohesion: 0.09
Nodes (22): Color, IconData?, build, color, cs, icon, KpiCard, label (+14 more)

### Community 104 - "snapshot_providers.dart"
Cohesion: 0.09
Nodes (22): dart:isolate, databaseFile, dir, kDatabaseFileName, openConnection, autoBackupDir, create, createAndShare (+14 more)

### Community 105 - "dashboard_body.dart"
Cohesion: 0.12
Nodes (16): ReportData, build, _buildKpiRows, cs, DashboardBody, data, _fmt, isCustomRange (+8 more)

### Community 106 - "inventory_screen.dart"
Cohesion: 0.15
Nodes (13): createState, dispose, _filter, _filtered, InventoryScreen, _InventoryScreenState, _search, _searchCtrl (+5 more)

### Community 107 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.15
Nodes (12): db, _db, DemoDataService, seed, _settings, build, _confirmReset, build (+4 more)

### Community 108 - "_ExpensesScreenState"
Cohesion: 0.33
Nodes (7): build, _expenseCategoriesStreamProvider, _ExpenseForm, _ExpenseFormState, ExpensesScreen, _ExpensesScreenState, _expensesStreamProvider

### Community 109 - "inventory_section.dart"
Cohesion: 0.22
Nodes (10): lowStockThresholdProvider, build, createState, _ctrl, current, dispose, _editThreshold, InventorySection (+2 more)

### Community 111 - "package:flutter/services.dart"
Cohesion: 0.17
Nodes (10): build, BusinessNameStep, controller, build, currencySymbol, nameController, rateController, TaxStep (+2 more)

### Community 112 - "occupied_tables_test.dart"
Cohesion: 0.11
Nodes (18): _box, formatTicketNumber, kTicketSeqKey, next, TicketSequence, ticketSequenceProvider, CartSession, CartSessionNotifier (+10 more)

### Community 113 - "receipt_printer.dart"
Cohesion: 0.18
Nodes (10): address, devices, DiscoveredPrinter, name, printBytes, PrinterTransport, startScan, stopScan (+2 more)

### Community 114 - "shortcuts_screen.dart"
Cohesion: 0.08
Nodes (24): ColorScheme, build, cs, key_, _KeyChip, keys, label, _SectionHeader (+16 more)

### Community 115 - "wizard_header.dart"
Cohesion: 0.29
Nodes (6): build, _labels, onSkip, step, WizardHeader, static const

### Community 116 - "side_nav.dart"
Cohesion: 0.29
Nodes (6): build, i, _indexFor, _label, PosDrawer, _routes

### Community 117 - "migration_test.dart"
Cohesion: 0.22
Nodes (8): generated/schema.dart, package:drift_dev/api/migrations_common.dart, package:drift_dev/api/migrations_native.dart, package:drift/native.dart, SchemaVerifier, main, shipped, verifier

### Community 118 - "build"
Cohesion: 0.13
Nodes (20): build, posFilterProvider, build, CartScreen, _CartScreenState, initState, build, favoritesProvider (+12 more)

### Community 119 - "tax_rates_table.dart"
Cohesion: 0.11
Nodes (16): BoolColumn get, color, ExpenseCategories, id, isDefault, name, createdAt, id (+8 more)

### Community 120 - "order_number.dart"
Cohesion: 0.40
Nodes (4): int get, billNo, displayNo, String get

### Community 121 - "ConsumerState"
Cohesion: 0.16
Nodes (17): ConsumerState, ConsumerStatefulWidget, PaymentScreen, activeHeldOrdersProvider, archivedHeldOrdersProvider, build, HeldTicketsBar, _HeldTicketsBarState (+9 more)

### Community 122 - "GeneratedDatabase"
Cohesion: 0.22
Nodes (9): GeneratedDatabase, DatabaseAtV10, DatabaseAtV11, DatabaseAtV12, DatabaseAtV4, DatabaseAtV6, DatabaseAtV7, DatabaseAtV8 (+1 more)

### Community 123 - "country_repository.dart"
Cohesion: 0.33
Nodes (5): dart:convert, _cache, CountryRepository, load, static List

### Community 124 - "VoidCallback?"
Cohesion: 0.11
Nodes (16): _Badge, bg, customer, CustomerCard, fg, icon, label, onEdit (+8 more)

### Community 125 - "onboarding_notifier.dart"
Cohesion: 0.10
Nodes (20): @immutable, AppSettings, settingsBoxProvider, SettingsNotifier, OnboardingState, back, build, finish (+12 more)

### Community 126 - "_"
Cohesion: 0.40
Nodes (6): _, compoundTax, lineItemTax, priceBeforeTax, _round, TaxCalculator

### Community 127 - "onboarding_state.dart"
Cohesion: 0.22
Nodes (8): businessName, copyWith, country, saving, step, taxName, taxRate, package:pos_app/features/onboarding/domain/country_default.dart

### Community 128 - "customer_picker_sheet.dart"
Cohesion: 0.20
Nodes (10): build, createState, CustomerPickerSheet, _CustomerPickerSheetState, customers, onSelect, _search, selectedId (+2 more)

### Community 129 - "ticket_header.dart"
Cohesion: 0.15
Nodes (14): build, _pickCustomer, session, TicketHeader, customersStreamProvider, build, build, OrdersScreen (+6 more)

### Community 130 - "List"
Cohesion: 0.40
Nodes (6): CartNotifier, clearItems, SelectedTaxRatesNotifier, selectedTaxRatesProvider, List, Notifier

### Community 131 - "package:pos_app/core/utils/currency_formatter.dart"
Cohesion: 0.29
Nodes (6): buildReceiptText, dateFmt, join, lines, o, package:pos_app/core/utils/currency_formatter.dart

### Community 133 - "Return"
Cohesion: 0.40
Nodes (4): initials, name, Return, ReturnsCompanion

### Community 134 - "discount_sheet.dart"
Cohesion: 0.18
Nodes (11): build, createState, _ctrl, currentDiscount, DiscountSheet, _DiscountSheetState, dispose, initState (+3 more)

### Community 135 - "country_step.dart"
Cohesion: 0.22
Nodes (8): build, countries, CountryStep, loading, onSearch, onSelect, searchController, selected

### Community 136 - "cart_calculator_test.dart"
Cohesion: 0.25
Nodes (7): package:pos_app/features/cart/domain/cart_calculator.dart, item, main, money, rate, roundTripsAt2dp, session

### Community 137 - "main.dart"
Cohesion: 0.40
Nodes (4): initFlutter, main, package:pos_app/app_root.dart, package:pos_app/features/backup/data/snapshot_providers.dart

### Community 138 - "ReceiptPrinter"
Cohesion: 0.67
Nodes (3): ThermalPluginPrinter, ReceiptPrinter, FakeReceiptPrinter

## Ambiguous Edges - Review These
- `Responsive Desktop POS Layout Rule` → `Platform Requirements (Android API 21+, iOS 12+)`  [AMBIGUOUS]
  .planning/codebase/CONVENTIONS.md · relation: conceptually_related_to
- `pos_app Package Manifest (v1.0.0+9)` → `v1 Phase 3 — Core Sales Loop`  [AMBIGUOUS]
  v1_roadmap.md · relation: references
- `pos_app Package Manifest (v1.0.0+9)` → `v1 Phase 7 — Customers, Loyalty & Audit`  [AMBIGUOUS]
  v1_roadmap.md · relation: references

## Knowledge Gaps
- **2338 isolated node(s):** `refresh`, `getKeyboardDismissBehavior`, `_slide`, `ping`, `_container` (+2333 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **3 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `Responsive Desktop POS Layout Rule` and `Platform Requirements (Android API 21+, iOS 12+)`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **What is the exact relationship between `pos_app Package Manifest (v1.0.0+9)` and `v1 Phase 3 — Core Sales Loop`?**
  _Edge tagged AMBIGUOUS (relation: references) - confidence is low._
- **What is the exact relationship between `pos_app Package Manifest (v1.0.0+9)` and `v1 Phase 7 — Customers, Loyalty & Audit`?**
  _Edge tagged AMBIGUOUS (relation: references) - confidence is low._
- **Why does `Return` connect `Return` to `app_database.dart`, `tron_border.dart`, `products_provider.dart`, `render_receipt.dart`, `DataClass`, `package:flutter_riverpod/flutter_riverpod.dart`, `money.dart`, `receipt_pdf_service.dart`?**
  _High betweenness centrality (0.023) - this node is a cross-community bridge._
- **Why does `CurrencyFormatter` connect `grid_product_tile.dart` to `receipt_body.dart`, `products_provider.dart`, `product_tile.dart`, `home.dart`, `expenses_screen.dart`, `receipt_screen.dart`, `orders_screen.dart`, `order_detail_screen.dart`, `products_screen.dart`, `order_summary.dart`, `payment_screen.dart`, `ConsumerWidget`?**
  _High betweenness centrality (0.014) - this node is a cross-community bridge._
- **Why does `AuditDao` connect `AppDatabase` to `app_database.dart`?**
  _High betweenness centrality (0.011) - this node is a cross-community bridge._
- **What connects `refresh`, `getKeyboardDismissBehavior`, `_slide` to the rest of the system?**
  _2338 weakly-connected nodes found - possible documentation gaps or missing edges._