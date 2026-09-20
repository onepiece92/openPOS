# Graph Report - offlinePOS  (2026-09-20)

## Corpus Check
- 212 files · ~168,217 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 3746 nodes · 5916 edges · 146 communities (141 shown, 5 thin omitted)
- Extraction: 98% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 85 edges (avg confidence: 0.87)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `32e36b57`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Drift Database Core
- Table
- schema_v10.dart
- schema_v11.dart
- schema_v13.dart
- schema_v12.dart
- schema_v9.dart
- schema_v8.dart
- schema_v4.dart
- schema_v7.dart
- schema_v6.dart
- hive_provider.dart
- ConsumerWidget
- package:pos_app/core/database/app_database.dart
- product_form_screen.dart
- expenses_screen.dart
- DataClass
- backup_screen.dart
- StatelessWidget
- app.dart
- inventory_screen.dart
- home.dart
- report_data.dart
- auto_print_test.dart
- payment_screen.dart
- printer_setup_screen.dart
- orders_screen.dart
- customer_picker_sheet.dart
- receipt_pdf_service.dart
- ColorScheme
- snapshot_service.dart
- order_taxes_table.dart
- held_ticket_number_test.dart
- package:flutter/material.dart
- cart_notifier.dart
- audit_log_screen.dart
- TextColumn get
- orders_table.dart
- IntColumn get
- snapshot_providers.dart
- orders_dao.dart
- tax_settings_screen.dart
- store_profile_edit_screen.dart
- package:pos_app/core/theme/tokens.dart
- onboarding_screen.dart
- products_screen.dart
- held_tickets_bar.dart
- order_detail_screen.dart
- products_dao.dart
- schema.dart
- receipt_screen.dart
- tables_screen.dart
- package:drift/drift.dart
- inventory_filter_bar.dart
- AppDatabase
- cartSessionProvider
- grid_product_tile.dart
- products_table.dart
- currencySymbolProvider
- occupied_tables_test.dart
- product_tile.dart
- inventory_card.dart
- receipt_body.dart
- customer_card.dart
- customers_screen.dart
- app_theme.dart
- tokens.dart
- held_order.dart
- Dependency Audit (2026-04-22)
- tax_rates_table.dart
- backup_repository.dart
- customer_form.dart
- cart_summary.dart
- pos_filter_provider.dart
- article_detail_screen.dart
- held_orders_notifier.dart
- package:pos_app/features/cart/presentation/providers/cart_notifier.dart
- package:flutter_riverpod/flutter_riverpod.dart
- learn_screen.dart
- app_root.dart
- dashboard_screen.dart
- String?
- order_summary.dart
- package:pos_app/core/utils/currency_formatter.dart
- dashboard_body.dart
- pos_app Package Manifest (v1.0.0+9)
- ConsumerState
- money.dart
- Milestone 1 — v1 Foundation & Core POS
- databaseProvider
- tron_border.dart
- migration_test.dart
- customers_table.dart
- cart_item.dart
- render_receipt.dart
- receipt_roll_pdf.dart
- Offline-First Non-Negotiable Constraint
- settingsProvider
- discount_sheet.dart
- snapshot_service_test.dart
- expenses_dao.dart
- expenses_table.dart
- order_items_table.dart
- build
- app_sheet.dart
- star_printer.dart
- receipt_printer.dart
- List
- build
- package:intl/intl.dart
- table_selector.dart
- Riverpod Architecture Decision (provider type per concern)
- Feature-First Layered Architecture
- GeneratedDatabase
- State
- products_provider.dart
- audit_log_table.dart
- country_default.dart
- Route /pos
- Banned Runtime-Fetching Packages
- tax_dao.dart
- audit_service.dart
- onboarding_state.dart
- tables_dao.dart
- build_runner Code Generation Workflow
- VoidCallback?
- audit_dao.dart
- _PrinterSetupScreenState
- Hardware Integration Pillar (ESC/POS + PDF)
- Open POS Brand Logo
- package:flutter/services.dart
- int get
- thermal_plugin_printer.dart
- render_receipt_image.dart
- currencies.dart
- receipt_roll_pdf_test.dart
- _StoreProfileEditScreenState
- dismiss_keyboard_test.dart
- onboarding_notifier.dart
- country_step.dart
- Notifier
- ReceiptPrinter
- string_utils.dart
- _RouterRefresh
- AppScrollBehavior
- ReportPeriod

## God Nodes (most connected - your core abstractions)
1. `databaseProvider` - 34 edges
2. `cartSessionProvider` - 26 edges
3. `AppDatabase` - 23 edges
4. `settingsProvider` - 20 edges
5. `currencyFormatterProvider` - 20 edges
6. `DataClass` - 19 edges
7. `cartProvider` - 18 edges
8. `CurrencyFormatter` - 16 edges
9. `Return` - 14 edges
10. `_PaymentScreenState` - 14 edges

## Surprising Connections (you probably didn't know these)
- `Banned Runtime-Fetching Packages` --semantically_similar_to--> `Bundled Fonts Policy (google_fonts banned)`  [INFERRED] [semantically similar]
  CLAUDE.md → .planning/codebase/DEPENDENCIES.md
- `ROADMAP Phase 1 — Core Foundation & Shared Logic` --semantically_similar_to--> `v1 Phase 0 — Foundation (no UI)`  [INFERRED] [semantically similar]
  ROADMAP.md → v1_roadmap.md
- `ROADMAP Phase 4 — POS Interface (Main Flow)` --semantically_similar_to--> `v1 Phase 3 — Core Sales Loop`  [INFERRED] [semantically similar]
  ROADMAP.md → v1_roadmap.md
- `Offline-First Non-Negotiable Constraint` --semantically_similar_to--> `Offline Reliability + Hardware Integration Focus`  [INFERRED] [semantically similar]
  CLAUDE.md → .planning/codebase/DEPENDENCIES.md
- `flutter_launcher_icons Config (android/ios/web)` --conceptually_related_to--> `Offline-First Non-Negotiable Constraint`  [AMBIGUOUS]
  pubspec.yaml → CLAUDE.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Drift Schema Migration Workflow** — claude_database_schema_change_procedure, claude_app_database_current_schema_version, claude_migration_test, claude_migrator_based_migration, _planning_codebase_dependencies_drift_dev, _planning_codebase_dependencies_build_runner, _planning_codebase_dependencies_drift [EXTRACTED 1.00]
- **Offline-First Enforcement Regime** — claude_offline_first_constraint, claude_banned_packages, claude_network_permission_lockdown, claude_deleted_sync_scaffolding, claude_url_launcher_exception, _planning_codebase_integrations_no_external_apis, project_core_mission [EXTRACTED 1.00]
- **Offline-First Enforcement Surface** — claude_offline_first_constraint, claude_no_outbound_network_calls, claude_banned_packages, claude_network_permission_ban, claude_deleted_sync_scaffolding, pubspec_jetbrainsmono_font_bundle [EXTRACTED 1.00]
- **Receipt Output Stack (thermal + ESC/POS + PDF)** — _planning_codebase_dependencies_flutter_thermal_printer, _planning_codebase_dependencies_esc_pos_utils_plus, _planning_codebase_dependencies_pdf_printing_stack [EXTRACTED 1.00]
- **End-to-End Tax Calculation Flow** — v1_roadmap_tax_engine, v1_roadmap_phase_2_product_inventory_core, v1_roadmap_phase_3_core_sales_loop, v1_roadmap_phase_4_receipts_hardware, v1_roadmap_phase_6_expenses_reports, v1_roadmap_drift_schema_v1 [EXTRACTED 1.00]
- **Open POS Brand Identity System** — assets_images_logo_open_pos_brand_logo, assets_images_logo_open_pos_wordmark, assets_images_logo_circular_arrow_mark, assets_images_logo_green_blue_gradient_palette [INFERRED 0.85]
- **Riverpod State & DI Layer Contract** — _planning_codebase_architecture_state_management_riverpod, _planning_codebase_conventions_provider_naming, v1_roadmap_riverpod_decision_table, v1_roadmap_provider_hierarchy, v1_roadmap_cart_notifier, project_riverpod_sole_di, pubspec_riverpod_generator_omitted [INFERRED 0.85]

## Communities (146 total, 5 thin omitted)

### Community 0 - "Drift Database Core"
Cohesion: 0.01
Nodes (246): class OrderTaxOverride extends, class ProductComponent extends, ColumnFilters, ColumnOrderings, backfillInvoiceNumbers, currentSchemaVersion, migration, _openConnection (+238 more)

### Community 1 - "Table"
Cohesion: 0.03
Nodes (157): Table, TableInfo, AuditLog, Categories, Customers, ExpenseCategories, Expenses, OrderItems (+149 more)

### Community 2 - "schema_v10.dart"
Cohesion: 0.02
Nodes (119): TaxGroups, action, actualTableName, address, _alias, aliasedName, allSchemaEntities, allTables (+111 more)

### Community 3 - "schema_v11.dart"
Cohesion: 0.02
Nodes (101): OrderTaxes, action, actualTableName, address, _alias, aliasedName, allSchemaEntities, allTables (+93 more)

### Community 4 - "schema_v13.dart"
Cohesion: 0.02
Nodes (101): Index, Tables, action, actualTableName, address, _alias, aliasedName, allSchemaEntities (+93 more)

### Community 5 - "schema_v12.dart"
Cohesion: 0.02
Nodes (99): Customers, GeneratedColumn, action, actualTableName, address, _alias, aliasedName, allSchemaEntities (+91 more)

### Community 6 - "schema_v9.dart"
Cohesion: 0.02
Nodes (95): Orders, action, actualTableName, address, _alias, aliasedName, allSchemaEntities, allTables (+87 more)

### Community 7 - "schema_v8.dart"
Cohesion: 0.02
Nodes (93): ExpenseCategories, Products, Returns, action, actualTableName, address, _alias, aliasedName (+85 more)

### Community 8 - "schema_v4.dart"
Cohesion: 0.02
Nodes (92): ProductComponents, ProductModifiers, ProductVariants, TaxGroupMembers, action, actualTableName, address, _alias (+84 more)

### Community 9 - "schema_v7.dart"
Cohesion: 0.02
Nodes (91): AuditLog, Expenses, Iterable, ProductTaxes, action, actualTableName, address, _alias (+83 more)

### Community 10 - "schema_v6.dart"
Cohesion: 0.02
Nodes (90): Categories, OrderItems, OrderTaxOverrides, StockAdjustments, TaxRates, action, actualTableName, address (+82 more)

### Community 11 - "hive_provider.dart"
Cohesion: 0.03
Nodes (71): autoBackupEnabled, autoBackupLastAt, _box, build, businessAddress, businessName, businessNameOrDefault, businessPan (+63 more)

### Community 12 - "ConsumerWidget"
Cohesion: 0.11
Nodes (19): ConsumerWidget, themeModeProvider, OrderSummary, _TaxPickerSheet, InventoryCard, SettingsScreen, AppearanceSection, build (+11 more)

### Community 13 - "package:pos_app/core/database/app_database.dart"
Cohesion: 0.06
Nodes (46): AuditService, invoicePrefix, placeOrder, transaction, transaction, voidOrder, package:flutter_test/flutter_test.dart, package:pos_app/core/database/app_database.dart (+38 more)

### Community 14 - "product_form_screen.dart"
Cohesion: 0.06
Nodes (34): _categoryId, _ComponentEntry, _components, _conversionCtrl, createState, _delete, didChangeDependencies, dispose (+26 more)

### Community 15 - "expenses_screen.dart"
Cohesion: 0.05
Nodes (42): _amountCtrl, build, categories, category, _CategoryChips, _categoryId, _Chip, color (+34 more)

### Community 16 - "DataClass"
Cohesion: 0.09
Nodes (40): Insertable, OrderNumberX, UpdateCompanion, AuditLogCompanion, AuditLogData, CategoriesCompanion, Category, Customer (+32 more)

### Community 17 - "backup_screen.dart"
Cohesion: 0.06
Nodes (36): autoBackupEnabledProvider, autoBackupLastAtProvider, backupRepositoryProvider, snapshotCoordinatorProvider, _AutoBackupTile, BackupScreen, _BackupScreenState, _BackupTile (+28 more)

### Community 18 - "StatelessWidget"
Cohesion: 0.08
Nodes (28): build, cs, key_, _KeyChip, keys, label, _SectionHeader, _ShortcutRow (+20 more)

### Community 19 - "app.dart"
Cohesion: 0.06
Nodes (31): GoRouter, getKeyboardDismissBehavior, ping, refresh, _slide, Offset, package:pos_app/features/audit/presentation/audit_log_screen.dart, package:pos_app/features/backup/presentation/backup_screen.dart (+23 more)

### Community 20 - "inventory_screen.dart"
Cohesion: 0.09
Nodes (25): lowStockThresholdProvider, build, createState, dispose, _filter, _filtered, InventoryScreen, _InventoryScreenState (+17 more)

### Community 21 - "home.dart"
Cohesion: 0.06
Nodes (34): _applyFilter, cart, categories, _CategoryRow, _Chip, createState, dispose, favorites (+26 more)

### Community 22 - "report_data.dart"
Cohesion: 0.06
Nodes (30): avgOrder, chartDates, chartHighlightIndex, chartTitle, chartTotals, count, days, db (+22 more)

### Community 23 - "auto_print_test.dart"
Cohesion: 0.12
Nodes (16): Object?, package:pos_app/features/printing/domain/auto_print.dart, box, db, devices, failWith, main, makeContainer (+8 more)

### Community 24 - "payment_screen.dart"
Cohesion: 0.09
Nodes (25): build, createState, customer, dispose, fmt, icon, initState, label (+17 more)

### Community 25 - "printer_setup_screen.dart"
Cohesion: 0.10
Nodes (20): PrinterDriver, createState, _devices, _devicesSub, _disconnectSavedPrinter, dispose, _driver, _driverLabel (+12 more)

### Community 26 - "orders_screen.dart"
Cohesion: 0.08
Nodes (28): build, createState, cs, customerName, _filter, fmt, _groupByDate, icon (+20 more)

### Community 27 - "customer_picker_sheet.dart"
Cohesion: 0.20
Nodes (10): build, createState, CustomerPickerSheet, _CustomerPickerSheetState, customers, onSelect, _search, selectedId (+2 more)

### Community 28 - "receipt_pdf_service.dart"
Cohesion: 0.08
Nodes (24): baseStyle, billRow, boldStyle, buildReceiptPdf, bytes, customerName, data, _dataCell (+16 more)

### Community 29 - "ColorScheme"
Cohesion: 0.13
Nodes (13): ColorScheme, build, cs, highlightIndex, labels, MiniBarChart, values, cs (+5 more)

### Community 30 - "snapshot_service.dart"
Cohesion: 0.07
Nodes (26): File, create, createdAt, dbBytes, dbEntryName, _decode, fileNameFor, filePrefix (+18 more)

### Community 31 - "order_taxes_table.dart"
Cohesion: 0.08
Nodes (24): createdAt, id, orderId, OrderTaxOverrides, originalTax, overrideTax, reason, id (+16 more)

### Community 32 - "held_ticket_number_test.dart"
Cohesion: 0.12
Nodes (17): Box, dart:io, Directory, _box, _kFavoriteProductIds, toggle, package:hive_flutter/hive_flutter.dart, package:pos_app/features/cart/data/ticket_sequence.dart (+9 more)

### Community 33 - "package:flutter/material.dart"
Cohesion: 0.07
Nodes (23): BackupSection, build, build, SettingsSectionHeader, title, build, i, _indexFor (+15 more)

### Community 34 - "cart_notifier.dart"
Cohesion: 0.06
Nodes (34): _, CartCalculator, compute, _roundingModeFor, add, addItem, addProduct, addProductInSecondaryUnit (+26 more)

### Community 35 - "audit_log_screen.dart"
Cohesion: 0.09
Nodes (23): action, _ActionChip, _actionColor, _actionIcon, AuditLogScreen, _auditLogsProvider, build, color (+15 more)

### Community 36 - "TextColumn get"
Cohesion: 0.09
Nodes (22): @DataClassName, DateTimeColumn get, createdAt, delta, id, notes, productId, reasonCode (+14 more)

### Community 37 - "orders_table.dart"
Cohesion: 0.08
Nodes (24): @TableIndex, changeAmount, createdAt, customerId, discountIsPercent, discountTotal, discountValue, id (+16 more)

### Community 38 - "IntColumn get"
Cohesion: 0.09
Nodes (22): IntColumn get, Categories, createdAt, id, name, parentId, sortOrder, taxRateId (+14 more)

### Community 39 - "snapshot_providers.dart"
Cohesion: 0.09
Nodes (21): dart:isolate, databaseFile, dir, kDatabaseFileName, openConnection, autoBackupDir, create, createAndShare (+13 more)

### Community 40 - "orders_dao.dart"
Cohesion: 0.06
Nodes (32): addLoyaltyPoints, getAll, getById, redeemLoyaltyPoints, search, upsert, watchAll, getAllOrdersWithItems (+24 more)

### Community 41 - "tax_settings_screen.dart"
Cohesion: 0.09
Nodes (26): FormState, defaultTaxIdProvider, invoicePrefixProvider, _placeOrder, build, reset, taxRatesStreamProvider, build (+18 more)

### Community 42 - "store_profile_edit_screen.dart"
Cohesion: 0.15
Nodes (12): class, _addressCtrl, build, createState, dispose, _initialised, _label, _loading (+4 more)

### Community 43 - "package:pos_app/core/theme/tokens.dart"
Cohesion: 0.13
Nodes (13): build, icon, isDestructive, onTap, StepButton, build, emphasis, icon (+5 more)

### Community 44 - "onboarding_screen.dart"
Cohesion: 0.08
Nodes (29): onboardingNotifierProvider, _back, build, _businessNameCtrl, _canProceed, _countries, createState, dispose (+21 more)

### Community 45 - "products_screen.dart"
Cohesion: 0.09
Nodes (22): _applyFilter, categories, _CategoryChips, categoryName, _Chip, createState, cs, dispose (+14 more)

### Community 46 - "held_tickets_bar.dart"
Cohesion: 0.13
Nodes (19): AnimationController, archivedHeldOrdersProvider, heldOrdersProvider, build, _buildActiveList, _buildArchivedList, createState, _ctrl (+11 more)

### Community 47 - "order_detail_screen.dart"
Cohesion: 0.09
Nodes (25): auditServiceProvider, build, businessName, customer, data, db, _DetailBody, _DetailData (+17 more)

### Community 48 - "products_dao.dart"
Cohesion: 0.09
Nodes (21): adjustStock, deductStock, deleteCategory, getAllCategories, getById, getBySku, getComponents, replaceComponents (+13 more)

### Community 49 - "schema.dart"
Cohesion: 0.13
Nodes (14): package:drift/internal/migrations.dart, schema_v10.dart, schema_v11.dart, schema_v12.dart, schema_v13.dart, schema_v4.dart, schema_v6.dart, schema_v7.dart (+6 more)

### Community 50 - "receipt_screen.dart"
Cohesion: 0.10
Nodes (21): build, businessName, customer, data, db, fmt, _handle, items (+13 more)

### Community 51 - "tables_screen.dart"
Cohesion: 0.10
Nodes (21): _assignToCart, _capacityCtrl, createState, dispose, existing, initState, isCurrentCartTable, isOccupied (+13 more)

### Community 52 - "package:drift/drift.dart"
Cohesion: 0.10
Nodes (17): openConnection, getAdjustmentsForProduct, logAdjustment, watchLowStock, componentProductId, compositeProductId, id, ProductComponents (+9 more)

### Community 53 - "inventory_filter_bar.dart"
Cohesion: 0.17
Nodes (11): build, _Chip, color, InventoryFilterBar, label, lowCount, onSelect, onTap (+3 more)

### Community 54 - "AppDatabase"
Cohesion: 0.16
Nodes (21): _, @DriftAccessor, @DriftDatabase, _$AuditDaoMixin, _$CustomersDaoMixin, DatabaseAccessor, _$ExpensesDaoMixin, _$InventoryDaoMixin (+13 more)

### Community 55 - "cartSessionProvider"
Cohesion: 0.12
Nodes (21): dart:ui, build, CartDetailScreen, cartProvider, cartSessionProvider, clear, build, CartLineItem (+13 more)

### Community 56 - "grid_product_tile.dart"
Cohesion: 0.10
Nodes (18): CurrencyFormatter, build, fmt, GridProductTile, isFavorite, onDecrement, onIncrement, onLongPress (+10 more)

### Community 57 - "products_table.dart"
Cohesion: 0.10
Nodes (19): categoryId, conversionRate, createdAt, id, imagePath, isActive, isComposite, isHiddenInPos (+11 more)

### Community 58 - "currencySymbolProvider"
Cohesion: 0.67
Nodes (4): currencyCodeProvider, currencySymbolProvider, build, CurrencySection

### Community 59 - "occupied_tables_test.dart"
Cohesion: 0.12
Nodes (17): _box, formatTicketNumber, kTicketSeqKey, next, TicketSequence, ticketSequenceProvider, CartSession, CartSessionNotifier (+9 more)

### Community 60 - "product_tile.dart"
Cohesion: 0.10
Nodes (19): bg, build, color, cs, fmt, icon, isFavorite, onDecrement (+11 more)

### Community 61 - "inventory_card.dart"
Cohesion: 0.10
Nodes (19): _apply, badgeColor, build, canDecrement, canIncrement, cs, _decrement, icon (+11 more)

### Community 62 - "receipt_body.dart"
Cohesion: 0.10
Nodes (20): _BillRow, build, businessName, customer, data, _DataCell, fmt, _HeaderCell (+12 more)

### Community 63 - "customer_card.dart"
Cohesion: 0.11
Nodes (16): Color, _Badge, bg, customer, CustomerCard, fg, icon, label (+8 more)

### Community 64 - "customers_screen.dart"
Cohesion: 0.12
Nodes (18): IconData get, build, createState, CustomersScreen, _CustomersScreenState, dispose, _filterAndSort, icon (+10 more)

### Community 65 - "app_theme.dart"
Cohesion: 0.11
Nodes (18): AppTheme, backgroundGradient, _build, ctaButtonStyle, dark, _darkGrad, _darkScheme, _fontFamily (+10 more)

### Community 66 - "tokens.dart"
Cohesion: 0.11
Nodes (18): AppFonts, AppOpacity, heavy, lg, md, medium, mono, Radii (+10 more)

### Community 67 - "held_order.dart"
Cohesion: 0.06
Nodes (31): bool get, copyWith, customerId, fresh, heldTicketId, isEditingHeldTicket, loyaltyPointsToRedeem, openedAt (+23 more)

### Community 68 - "Dependency Audit (2026-04-22)"
Cohesion: 0.18
Nodes (18): build_runner (Generator CLI), Dependency Audit (2026-04-22), drift (SQLite Relational Storage), drift_dev (Database Layer Codegen), esc_pos_utils_plus (ESC/POS Encoding), flutter_riverpod (State Management), flutter_thermal_printer (POS Hardware), hive / hive_flutter (KV Storage) (+10 more)

### Community 69 - "tax_rates_table.dart"
Cohesion: 0.11
Nodes (16): BoolColumn get, color, ExpenseCategories, id, isDefault, name, createdAt, id (+8 more)

### Community 70 - "backup_repository.dart"
Cohesion: 0.14
Nodes (16): DateTime, BackupRepository, db, exportCustomers, exportExpenses, exportOrders, exportProducts, exportSalesReport (+8 more)

### Community 71 - "customer_form.dart"
Cohesion: 0.11
Nodes (18): _addressCtrl, build, createState, customer, CustomerForm, _CustomerFormState, _delete, _discountCtrl (+10 more)

### Community 72 - "cart_summary.dart"
Cohesion: 0.11
Nodes (17): amount, CartSummary, isInclusive, loyaltyDiscount, name, orderDiscount, pointsToEarn, rate (+9 more)

### Community 73 - "pos_filter_provider.dart"
Cohesion: 0.12
Nodes (16): clearSearch, copyWith, favoritesOnly, isGrid, PosFilterNotifier, PosFilterState, PosSortMode, search (+8 more)

### Community 74 - "article_detail_screen.dart"
Cohesion: 0.11
Nodes (17): ArticleDetailScreen, ArticleSection, build, category, cs, heading, icon, readTime (+9 more)

### Community 75 - "held_orders_notifier.dart"
Cohesion: 0.12
Nodes (16): heldOrdersBoxProvider, HeldOrder, archive, archiveAll, _box, build, delete, deleteAllArchived (+8 more)

### Community 76 - "package:pos_app/features/cart/presentation/providers/cart_notifier.dart"
Cohesion: 0.16
Nodes (12): build, _pickCustomer, session, TicketHeader, customerId, customers, customersStreamProvider, watch (+4 more)

### Community 77 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.10
Nodes (21): int?, db, _db, DemoDataService, seed, _settings, autoPrintOrder, AutoPrintService (+13 more)

### Community 78 - "learn_screen.dart"
Cohesion: 0.12
Nodes (16): _Article, _ArticleCard, _articles, build, category, cs, description, icon (+8 more)

### Community 79 - "app_root.dart"
Cohesion: 0.10
Nodes (19): build, child, _container, createState, dispose, initState, message, _notice (+11 more)

### Community 80 - "dashboard_screen.dart"
Cohesion: 0.16
Nodes (13): DateTimeRange?, reportProvider, build, createState, _customRange, DashboardScreen, _DashboardScreenState, _period (+5 more)

### Community 81 - "String?"
Cohesion: 0.09
Nodes (21): double?, IconData?, CartItem, fmt, icon, item, onPressed, _QtyButton (+13 more)

### Community 82 - "order_summary.dart"
Cohesion: 0.11
Nodes (17): addColor, build, cs, fmt, label, onTap, ref, _showDiscountSheet (+9 more)

### Community 83 - "package:pos_app/core/utils/currency_formatter.dart"
Cohesion: 0.12
Nodes (15): buildReceiptText, dateFmt, join, lines, o, package:pos_app/core/utils/currency_formatter.dart, package:pos_app/features/printing/domain/render_receipt.dart, package:pos_app/features/receipts/presentation/receipt_body.dart (+7 more)

### Community 84 - "dashboard_body.dart"
Cohesion: 0.12
Nodes (15): ReportData, build, _buildKpiRows, cs, DashboardBody, data, _fmt, isCustomRange (+7 more)

### Community 85 - "pos_app Package Manifest (v1.0.0+9)"
Cohesion: 0.17
Nodes (15): Technology Stack (Dart 3.5+, Flutter 3.24+), pos_app Package Manifest (v1.0.0+9), ROADMAP Phase 1 — Core Foundation & Shared Logic, ROADMAP Phase 3 — Product Management (The Catalog), ROADMAP Phase 4 — POS Interface (Main Flow), Append-Only Audit Log, Connectivity Detection task (0.5, connectivity_plus), Drift Schema — Full v1 Table List (+7 more)

### Community 86 - "ConsumerState"
Cohesion: 0.08
Nodes (29): ConsumerState, ConsumerStatefulWidget, demoDataServiceProvider, _EmptyProductsState, _EmptyProductsStateState, _loadDemo, _HeldTicketsSheet, categoriesStreamProvider (+21 more)

### Community 87 - "money.dart"
Cohesion: 0.13
Nodes (14): allowZero, eps, isRequired, kMaxMoneyAmount, kMaxMoneyAmountLabel, noun, nudged, null (+6 more)

### Community 88 - "Milestone 1 — v1 Foundation & Core POS"
Cohesion: 0.18
Nodes (14): Dual Data Layer (Drift + Hive), Navigation Pillar (GoRouter routerProvider), Drift Layout Convention (tables, daos, AppDatabase migrations), Responsive Desktop POS Layout Rule, No Hardcoded Colors (AppTheme / colorScheme), Local Auth (no external identity provider), Platform Requirements (Android API 21+, iOS 12+), Premium Glassmorphic Dark Aesthetic (+6 more)

### Community 89 - "databaseProvider"
Cohesion: 0.10
Nodes (22): databaseProvider, _delete, _save, _showAddCategoryDialog, productsByCategoryProvider, build, category, _CategoryCard (+14 more)

### Community 90 - "tron_border.dart"
Cohesion: 0.14
Nodes (13): CustomPainter, dart:math, color, e, extractWrappedPath, f, len, p (+5 more)

### Community 91 - "migration_test.dart"
Cohesion: 0.13
Nodes (14): generated/schema.dart, _, compoundTax, lineItemTax, priceBeforeTax, _round, TaxCalculator, package:drift_dev/api/migrations_common.dart (+6 more)

### Community 92 - "customers_table.dart"
Cohesion: 0.14
Nodes (13): address, createdAt, Customers, defaultDiscount, defaultDiscountIsPercent, email, id, isTaxExempt (+5 more)

### Community 93 - "cart_item.dart"
Cohesion: 0.14
Nodes (13): copyWith, isSecondaryUnit, isTaxable, lineDiscount, lineSubtotal, mainUnitQty, name, productId (+5 more)

### Community 94 - "render_receipt.dart"
Cohesion: 0.11
Nodes (16): bytes, customerName, g, isCopy, _kv, method, methodLabel, profile (+8 more)

### Community 95 - "receipt_roll_pdf.dart"
Cohesion: 0.10
Nodes (19): base, body, bold, buildReceiptRollPdf, buildTestPageRollPdf, dateFmt, doc, font (+11 more)

### Community 96 - "Offline-First Non-Negotiable Constraint"
Cohesion: 0.19
Nodes (13): Zero External APIs / Services, Deleted Sync / Cloud-Backup Scaffolding, Graphify Knowledge Graph Workflow Rule, Sandbox-Blocked Release Binary (no INTERNET / network entitlements), Platform Network Permission Lockdown, No Outbound Network Calls Rule, Offline-First Non-Negotiable Constraint, url_launcher Network-Adjacent Exception (+5 more)

### Community 97 - "settingsProvider"
Cohesion: 0.15
Nodes (18): loyaltyEarnRateProvider, loyaltyEnabledProvider, loyaltyPointValueProvider, settingsBoxProvider, settingsProvider, OnboardingState, finish, OnboardingNotifier (+10 more)

### Community 98 - "discount_sheet.dart"
Cohesion: 0.18
Nodes (10): double get, build, createState, _ctrl, currentDiscount, dispose, initState, isPercent (+2 more)

### Community 99 - "snapshot_service_test.dart"
Cohesion: 0.15
Nodes (12): Exception, SnapshotFormatException, package:pos_app/features/backup/data/snapshot_service.dart, dbFileIn, hivePathIn, live, main, openDb (+4 more)

### Community 100 - "expenses_dao.dart"
Cohesion: 0.15
Nodes (12): getAll, getAllCategories, insert, insertCategory, totalForPeriod, updateExpense, upsertCategory, watchAll (+4 more)

### Community 101 - "expenses_table.dart"
Cohesion: 0.15
Nodes (12): amount, categoryId, createdAt, date, Expenses, id, isRecurring, isTaxDeductible (+4 more)

### Community 102 - "order_items_table.dart"
Cohesion: 0.15
Nodes (12): discount, id, lineTotal, orderId, OrderItems, productId, productName, quantity (+4 more)

### Community 103 - "build"
Cohesion: 0.25
Nodes (8): build, POSApp, routerProvider, Route /expenses, Route /help/shortcuts, Route /inventory, Route /products, Route /settings

### Community 104 - "app_sheet.dart"
Cohesion: 0.17
Nodes (10): cs, failurePrefix, messenger, draggable, initialSize, minSize, package:pos_app/shared/widgets/keyboard_safe.dart, required WidgetBuilder builder,
  bool (+2 more)

### Community 105 - "star_printer.dart"
Cohesion: 0.12
Nodes (16): dart:async, _devices, _discovery, dispose, _events, _found, _isAndroid, _methods (+8 more)

### Community 106 - "receipt_printer.dart"
Cohesion: 0.08
Nodes (25): address, data, devices, DiscoveredPrinter, driver, escPosPrinterProvider, fmt, fromKey (+17 more)

### Community 107 - "List"
Cohesion: 0.12
Nodes (15): CartNotifier, clearItems, selectedTaxRatesProvider, build, children, ConfirmStep, icon, isLast (+7 more)

### Community 108 - "build"
Cohesion: 0.32
Nodes (8): posFilterProvider, build, CartScreen, _CartScreenState, initState, favoritesProvider, productSalesCountProvider, Route /orders

### Community 109 - "package:intl/intl.dart"
Cohesion: 0.20
Nodes (9): decimalDigits, _fmt, format, formatPlain, locale, symbol, tryParse, NumberFormat (+1 more)

### Community 110 - "table_selector.dart"
Cohesion: 0.13
Nodes (20): activeHeldOrdersProvider, build, occupied, onSelect, selectedId, session, _TablePickerSheet, tables (+12 more)

### Community 111 - "Riverpod Architecture Decision (provider type per concern)"
Cohesion: 0.24
Nodes (10): Data Flow (UI to Notifier to DAO to Stream), State Management Pillar (Riverpod), Package-Imports-Only Rule, Provider Suffix Naming Convention, No Error Tracking, Analytics, or CI Pipeline, Enforced Lint Rules (analysis_options), Riverpod as Sole DI Mechanism, Testing Practice (unit for domain, widget for shared) (+2 more)

### Community 112 - "Feature-First Layered Architecture"
Cohesion: 0.20
Nodes (10): lib/ Directory Structure (core, features, shared), Feature-First Layered Architecture, Presentation-Domain-Data Feature Pattern, drift as Critical Persistence Dependency, graphify Knowledge Graph Workflow, Core Mission (100% offline POS), Guiding Principles (offline-first, hardware, feature-first, premium), Offline-First Flutter POS (project charter) (+2 more)

### Community 113 - "GeneratedDatabase"
Cohesion: 0.20
Nodes (10): GeneratedDatabase, DatabaseAtV10, DatabaseAtV11, DatabaseAtV12, DatabaseAtV13, DatabaseAtV4, DatabaseAtV6, DatabaseAtV7 (+2 more)

### Community 114 - "State"
Cohesion: 0.27
Nodes (10): AppRoot, AppRootState, _NoticeOverlay, _NoticeOverlayState, DiscountSheet, _DiscountSheetState, _ComponentPickerSheet, _ComponentPickerSheetState (+2 more)

### Community 115 - "products_provider.dart"
Cohesion: 0.13
Nodes (15): clearSearch, copyWith, outOfStockOnly, ProductsFilterNotifier, ProductsFilterState, ref, search, selectedCategoryId (+7 more)

### Community 116 - "audit_log_table.dart"
Cohesion: 0.20
Nodes (9): action, AuditLog, createdAt, entityId, entityType, id, metadata, newValue (+1 more)

### Community 117 - "country_default.dart"
Cohesion: 0.20
Nodes (9): code, CountryDefault, currency, fromJson, name, symbol, taxName, taxRate (+1 more)

### Community 118 - "Route /pos"
Cohesion: 0.50
Nodes (4): build, _finish, _skip, Route /pos

### Community 119 - "Banned Runtime-Fetching Packages"
Cohesion: 0.28
Nodes (9): Bundled Fonts Policy (google_fonts banned), google_fonts listed as Utility dependency, Local-Only Data Storage (Drift file + Hive + path_provider), Banned Runtime-Fetching Packages, Export & Sharing Stack (share_plus, csv, file_picker, permission_handler), Bundled JetBrainsMono Font Family, ROADMAP Phase 6 — Order History & Local Reporting, v1 Phase 5 — Backup & Data Safety (local-only) (+1 more)

### Community 120 - "tax_dao.dart"
Cohesion: 0.22
Nodes (8): getAll, getById, getRatesForProduct, setProductTaxes, upsertRate, watchActive, package:pos_app/core/database/tables/product_taxes_table.dart, _

### Community 121 - "audit_service.dart"
Cohesion: 0.14
Nodes (12): dart:convert, _db, log, orderPlaced, orderRefunded, orderVoided, settingChanged, taxOverridden (+4 more)

### Community 122 - "onboarding_state.dart"
Cohesion: 0.22
Nodes (8): businessName, copyWith, country, saving, step, taxName, taxRate, package:pos_app/features/onboarding/domain/country_default.dart

### Community 123 - "tables_dao.dart"
Cohesion: 0.25
Nodes (7): deleteById, getAll, getById, upsert, watchAll, package:pos_app/core/database/tables/tables_table.dart, _

### Community 124 - "build_runner Code Generation Workflow"
Cohesion: 0.29
Nodes (7): build_runner Code Generation Workflow, Code Generation Dev Dependencies (riverpod_generator, drift_dev, build_runner), build.yaml Code Generation Config, custom_lint Analyzer Plugin (enabled in analysis_options), Generated-File Exclusion (*.g.dart, *.freezed.dart), custom_lint / riverpod_lint Commented Out, riverpod_generator Omitted

### Community 125 - "VoidCallback?"
Cohesion: 0.13
Nodes (13): build, _labels, onSkip, step, WizardHeader, build, canNext, onBack (+5 more)

### Community 126 - "audit_dao.dart"
Cohesion: 0.29
Nodes (6): log, queryByDateRange, queryByEntity, watchRecent, package:pos_app/core/database/tables/audit_log_table.dart, _

### Community 127 - "_PrinterSetupScreenState"
Cohesion: 0.24
Nodes (13): printerDeviceAddressProvider, printerDeviceNameProvider, printerDriverProvider, printerPaperWidthProvider, printerForDriverProvider, receiptPrinterProvider, build, PrinterSetupScreen (+5 more)

### Community 128 - "Hardware Integration Pillar (ESC/POS + PDF)"
Cohesion: 0.47
Nodes (6): Hardware Integration Pillar (ESC/POS + PDF), PrintingService Abstraction, heathen_printer_plus (documented printer package), flutter_thermal_printer dependency, ROADMAP Phase 5 — Hardware Deep Integration, v1 Phase 4 — Receipts & Hardware

### Community 129 - "Open POS Brand Logo"
Cohesion: 0.53
Nodes (6): Interlocking Circular Arrow Mark, Green-to-Blue Gradient Brand Palette, Open POS Brand Logo, OPEN POS Wordmark, Point-of-Sale Product Identity, Transaction Cycle Visual Metaphor

### Community 130 - "package:flutter/services.dart"
Cohesion: 0.17
Nodes (10): build, BusinessNameStep, controller, build, currencySymbol, nameController, rateController, TaxStep (+2 more)

### Community 131 - "int get"
Cohesion: 0.40
Nodes (4): int get, billNo, displayNo, String get

### Community 132 - "thermal_plugin_printer.dart"
Cohesion: 0.17
Nodes (11): devices, _ftp, _printBytes, printReceipt, printTestPage, startScan, stopScan, package:flutter_thermal_printer/flutter_thermal_printer.dart (+3 more)

### Community 133 - "render_receipt_image.dart"
Cohesion: 0.18
Nodes (10): dart:typed_data, doc, isCopy, kReceiptDpi, pages, _rasterise, renderReceiptImages, renderTestPageImages (+2 more)

### Community 135 - "receipt_roll_pdf_test.dart"
Cohesion: 0.18
Nodes (10): package:pdf/pdf.dart, package:pos_app/features/printing/domain/receipt_roll_pdf.dart, package:pos_app/features/printing/domain/render_receipt_image.dart, doc, fmt, main, order, _pageFormats (+2 more)

### Community 136 - "_StoreProfileEditScreenState"
Cohesion: 0.42
Nodes (10): businessAddressProvider, businessNameProvider, businessPanProvider, businessPhoneProvider, businessTaglineProvider, didChangeDependencies, _StoreProfileEditScreenState, build (+2 more)

### Community 137 - "dismiss_keyboard_test.dart"
Cohesion: 0.22
Nodes (7): EditableText, package:pos_app/app.dart, package:pos_app/shared/widgets/dismiss_keyboard.dart, harness, main, main, textFieldHasFocus

### Community 138 - "onboarding_notifier.dart"
Cohesion: 0.22
Nodes (8): back, build, next, setBusinessName, setCountry, setSaving, setTaxName, setTaxRate

### Community 139 - "country_step.dart"
Cohesion: 0.22
Nodes (8): build, countries, CountryStep, loading, onSearch, onSelect, searchController, selected

### Community 140 - "Notifier"
Cohesion: 0.40
Nodes (5): @immutable, AppSettings, SettingsNotifier, SelectedTaxRatesNotifier, Notifier

### Community 141 - "ReceiptPrinter"
Cohesion: 0.50
Nodes (4): StarBluetoothPrinter, ThermalPluginPrinter, ReceiptPrinter, FakeReceiptPrinter

## Ambiguous Edges - Review These
- `v1 Phase 3 — Core Sales Loop` → `pos_app Package Manifest (v1.0.0+9)`  [AMBIGUOUS]
  v1_roadmap.md · relation: references
- `v1 Phase 7 — Customers, Loyalty & Audit` → `pos_app Package Manifest (v1.0.0+9)`  [AMBIGUOUS]
  v1_roadmap.md · relation: references
- `Responsive Desktop POS Layout Rule` → `Platform Requirements (Android API 21+, iOS 12+)`  [AMBIGUOUS]
  .planning/codebase/CONVENTIONS.md · relation: conceptually_related_to
- `Offline-First Non-Negotiable Constraint` → `flutter_launcher_icons Config (android/ios/web)`  [AMBIGUOUS]
  pubspec.yaml · relation: conceptually_related_to

## Knowledge Gaps
- **2528 isolated node(s):** `refresh`, `getKeyboardDismissBehavior`, `_slide`, `ping`, `_container` (+2523 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **5 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `v1 Phase 3 — Core Sales Loop` and `pos_app Package Manifest (v1.0.0+9)`?**
  _Edge tagged AMBIGUOUS (relation: references) - confidence is low._
- **What is the exact relationship between `v1 Phase 7 — Customers, Loyalty & Audit` and `pos_app Package Manifest (v1.0.0+9)`?**
  _Edge tagged AMBIGUOUS (relation: references) - confidence is low._
- **What is the exact relationship between `Responsive Desktop POS Layout Rule` and `Platform Requirements (Android API 21+, iOS 12+)`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **What is the exact relationship between `Offline-First Non-Negotiable Constraint` and `flutter_launcher_icons Config (android/ios/web)`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **Why does `Return` connect `DataClass` to `Drift Database Core`, `render_receipt_image.dart`, `receipt_printer.dart`, `package:flutter_riverpod/flutter_riverpod.dart`, `string_utils.dart`, `products_provider.dart`, `money.dart`, `tron_border.dart`, `receipt_pdf_service.dart`, `render_receipt.dart`, `receipt_roll_pdf.dart`?**
  _High betweenness centrality (0.031) - this node is a cross-community bridge._
- **Why does `CurrencyFormatter` connect `grid_product_tile.dart` to `receipt_printer.dart`, `package:intl/intl.dart`, `products_screen.dart`, `expenses_screen.dart`, `order_detail_screen.dart`, `String?`, `order_summary.dart`, `products_provider.dart`, `receipt_screen.dart`, `home.dart`, `payment_screen.dart`, `orders_screen.dart`, `product_tile.dart`, `receipt_body.dart`?**
  _High betweenness centrality (0.011) - this node is a cross-community bridge._
- **Why does `_` connect `migration_test.dart` to `cart_notifier.dart`?**
  _High betweenness centrality (0.011) - this node is a cross-community bridge._