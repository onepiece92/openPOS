# Graph Report - offlinePOS  (2026-08-23)

## Corpus Check
- 204 files · ~159,186 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 3415 nodes · 5404 edges · 140 communities (138 shown, 2 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 69 edges (avg confidence: 0.88)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `c1787606`
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
- ConsumerWidget
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
- inventory_filter_bar.dart
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
- returns_table.dart
- orders_table.dart
- audit_dao.dart
- article_detail_screen.dart
- package:flutter_test/flutter_test.dart
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
- IntColumn get
- pos_app Package Manifest (v1.0.0+9)
- schema_v8.dart
- _StoreProfileEditScreenState
- auto_print_test.dart
- expenses_dao.dart
- customers_table.dart
- expenses_table.dart
- cart_summary.dart
- Table
- render_receipt.dart
- Riverpod Architecture Decision (provider type per concern)
- Offline-First Non-Negotiable Constraint
- DateTimeColumn get
- order_items_table.dart
- schema_v11.dart
- app_sheet.dart
- snapshot_service.dart
- held_ticket_number_test.dart
- settings_screen.dart
- package:pos_app/features/cart/domain/cart_item.dart
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
- inventory_card.dart
- tables_dao.dart
- order_summary.dart
- customer_form.dart
- currencyFormatterProvider
- Dual Data Layer (Drift + Hive)
- Banned Runtime-Fetching Packages
- app_root.dart
- SettingsNotifier
- schema_v6.dart
- settingsProvider
- audit_log_screen.dart
- invoice_numbering_test.dart
- Open POS Brand Logo
- customer_card.dart
- snapshot_providers.dart
- dashboard_body.dart
- inventory_screen.dart
- package:flutter_riverpod/flutter_riverpod.dart
- package:pos_app/features/cart/presentation/providers/cart_notifier.dart
- ConsumerState
- custom_lint Analyzer Plugin (enabled in analysis_options)
- package:flutter/services.dart
- occupied_tables_test.dart
- receipt_printer.dart
- package:pos_app/core/theme/tokens.dart
- TextColumn get
- String?
- package:pos_app/core/database/app_database.dart
- build
- tax_rates_table.dart
- order_number.dart
- categoriesStreamProvider
- GeneratedDatabase
- tax_dao.dart
- VoidCallback?
- onboarding_notifier.dart
- order_taxes_table.dart
- onboarding_state.dart
- customer_picker_sheet.dart
- ticket_header.dart
- confirm_step.dart
- package:pos_app/core/utils/currency_formatter.dart
- currencies.dart
- State
- discount_sheet.dart
- country_step.dart
- cart_calculator_test.dart
- place_order_test.dart
- build
- business_name_step.dart

## God Nodes (most connected - your core abstractions)
1. `databaseProvider` - 34 edges
2. `cartSessionProvider` - 26 edges
3. `AppDatabase` - 23 edges
4. `DataClass` - 21 edges
5. `currencyFormatterProvider` - 20 edges
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

## Communities (140 total, 2 thin omitted)

### Community 0 - "app_database.dart"
Cohesion: 0.01
Nodes (250): class OrderTaxOverride extends, class ProductComponent extends, ColumnFilters, ColumnOrderings, backfillInvoiceNumbers, currentSchemaVersion, migration, _openConnection (+242 more)

### Community 1 - "dashboard_screen.dart"
Cohesion: 0.14
Nodes (15): DateTimeRange?, ReportPeriod, ReportPeriodX, reportProvider, build, createState, _customRange, DashboardScreen (+7 more)

### Community 2 - "cart_notifier.dart"
Cohesion: 0.08
Nodes (27): ticketSequenceProvider, CartSession, add, addItem, addProduct, allRates, CartNotifier, CartSessionNotifier (+19 more)

### Community 3 - "onboarding_screen.dart"
Cohesion: 0.07
Nodes (34): build, onboardingNotifierProvider, _back, build, _businessNameCtrl, _canProceed, _countries, createState (+26 more)

### Community 4 - "DataClass"
Cohesion: 0.08
Nodes (46): Insertable, initials, name, OrderNumberX, UpdateCompanion, AuditLogCompanion, AuditLogData, CategoriesCompanion (+38 more)

### Community 5 - "hive_provider.dart"
Cohesion: 0.03
Nodes (69): autoBackupEnabled, autoBackupLastAt, _box, build, businessAddress, businessName, businessNameOrDefault, businessPan (+61 more)

### Community 6 - "expenses_screen.dart"
Cohesion: 0.05
Nodes (44): _amountCtrl, build, categories, category, _CategoryChips, _categoryId, _Chip, color (+36 more)

### Community 7 - "home.dart"
Cohesion: 0.06
Nodes (36): demoDataServiceProvider, _applyFilter, cart, categories, _CategoryRow, _Chip, createState, dispose (+28 more)

### Community 8 - "report_data.dart"
Cohesion: 0.06
Nodes (30): avgOrder, chartDates, chartHighlightIndex, chartTitle, chartTotals, count, days, db (+22 more)

### Community 9 - "products_dao.dart"
Cohesion: 0.08
Nodes (25): adjustStock, deductStock, deleteCategory, getAllCategories, getById, getBySku, getComponents, getModifiers (+17 more)

### Community 10 - "customers_screen.dart"
Cohesion: 0.12
Nodes (17): IconData get, createState, CustomersScreen, _CustomersScreenState, dispose, _filterAndSort, icon, label (+9 more)

### Community 11 - "app.dart"
Cohesion: 0.04
Nodes (44): ChangeNotifier, EditableText, GoRouter, AppScrollBehavior, getKeyboardDismissBehavior, ping, POSApp, refresh (+36 more)

### Community 12 - "ConsumerWidget"
Cohesion: 0.10
Nodes (20): ConsumerWidget, currencyCodeProvider, currencySymbolProvider, build, CartLineItem, fmt, icon, item (+12 more)

### Community 13 - "app_theme.dart"
Cohesion: 0.05
Nodes (38): themeModeProvider, AppTheme, backgroundGradient, _build, ctaButtonStyle, dark, _darkGrad, _darkScheme (+30 more)

### Community 14 - "orders_dao.dart"
Cohesion: 0.06
Nodes (32): addLoyaltyPoints, getAll, getById, redeemLoyaltyPoints, search, upsert, watchAll, getAllOrdersWithItems (+24 more)

### Community 15 - "held_tickets_bar.dart"
Cohesion: 0.13
Nodes (21): AnimationController, activeHeldOrdersProvider, archivedHeldOrdersProvider, heldOrdersProvider, build, _buildActiveList, _buildArchivedList, createState (+13 more)

### Community 16 - "StatelessWidget"
Cohesion: 0.08
Nodes (28): build, cs, key_, _KeyChip, keys, label, _SectionHeader, _ShortcutRow (+20 more)

### Community 17 - "product_form_screen.dart"
Cohesion: 0.06
Nodes (34): _categoryId, _ComponentEntry, _components, _conversionCtrl, createState, _delete, didChangeDependencies, dispose (+26 more)

### Community 18 - "receipt_pdf_service.dart"
Cohesion: 0.07
Nodes (27): baseStyle, billRow, boldStyle, buildReceiptPdf, bytes, customerName, data, _dataCell (+19 more)

### Community 19 - "orders_screen.dart"
Cohesion: 0.08
Nodes (28): build, createState, cs, customerName, _filter, fmt, _groupByDate, icon (+20 more)

### Community 20 - "order_detail_screen.dart"
Cohesion: 0.10
Nodes (21): auditServiceProvider, businessName, customer, data, db, _DetailBody, _DetailData, fmt (+13 more)

### Community 21 - "package:flutter/material.dart"
Cohesion: 0.08
Nodes (22): BackupSection, build, build, SettingsSectionHeader, title, i, _indexFor, _label (+14 more)

### Community 22 - "schema_v10.dart"
Cohesion: 0.02
Nodes (100): Index, Tables, action, actualTableName, address, _alias, aliasedName, allSchemaEntities (+92 more)

### Community 23 - "inventory_filter_bar.dart"
Cohesion: 0.17
Nodes (11): build, _Chip, color, InventoryFilterBar, label, lowCount, onSelect, onTap (+3 more)

### Community 24 - "backup_screen.dart"
Cohesion: 0.06
Nodes (36): autoBackupEnabledProvider, autoBackupLastAtProvider, backupRepositoryProvider, snapshotCoordinatorProvider, _AutoBackupTile, BackupScreen, _BackupScreenState, _BackupTile (+28 more)

### Community 25 - "products_screen.dart"
Cohesion: 0.09
Nodes (22): _applyFilter, categories, _CategoryChips, categoryName, _Chip, createState, cs, dispose (+14 more)

### Community 26 - "snapshot_service_test.dart"
Cohesion: 0.15
Nodes (12): Exception, SnapshotFormatException, package:pos_app/features/backup/data/snapshot_service.dart, dbFileIn, hivePathIn, live, main, openDb (+4 more)

### Community 27 - "printer_setup_screen.dart"
Cohesion: 0.11
Nodes (24): printerDeviceAddressProvider, printerDeviceNameProvider, printerPaperWidthProvider, receiptPrinterProvider, build, createState, _devices, _devicesSub (+16 more)

### Community 28 - "payment_screen.dart"
Cohesion: 0.11
Nodes (18): createState, customer, dispose, fmt, icon, label, _loyaltyCtrl, _LoyaltySection (+10 more)

### Community 29 - "receipt_screen.dart"
Cohesion: 0.10
Nodes (21): build, businessName, customer, data, db, fmt, _handle, items (+13 more)

### Community 30 - "tables_screen.dart"
Cohesion: 0.09
Nodes (21): _assignToCart, _capacityCtrl, _confirmDelete, createState, dispose, existing, initState, isCurrentCartTable (+13 more)

### Community 31 - "AppDatabase"
Cohesion: 0.16
Nodes (21): _, @DriftAccessor, @DriftDatabase, _$AuditDaoMixin, _$CustomersDaoMixin, DatabaseAccessor, _$ExpensesDaoMixin, _$InventoryDaoMixin (+13 more)

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

### Community 42 - "returns_table.dart"
Cohesion: 0.08
Nodes (22): createdAt, id, orderId, OrderTaxOverrides, originalTax, overrideTax, reason, id (+14 more)

### Community 43 - "orders_table.dart"
Cohesion: 0.08
Nodes (24): @TableIndex, changeAmount, createdAt, customerId, discountIsPercent, discountTotal, discountValue, id (+16 more)

### Community 44 - "audit_dao.dart"
Cohesion: 0.29
Nodes (6): log, queryByDateRange, queryByEntity, watchRecent, package:pos_app/core/database/tables/audit_log_table.dart, _

### Community 45 - "article_detail_screen.dart"
Cohesion: 0.11
Nodes (17): ArticleDetailScreen, ArticleSection, build, category, cs, heading, icon, readTime (+9 more)

### Community 46 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.12
Nodes (15): package:flutter_test/flutter_test.dart, package:pos_app/features/cart/data/place_order.dart, package:pos_app/features/returns/domain/process_return.dart, ../../_support/test_db.dart, main, audit, db, main (+7 more)

### Community 47 - "store_profile_edit_screen.dart"
Cohesion: 0.15
Nodes (12): class, _addressCtrl, build, createState, dispose, _initialised, _label, _loading (+4 more)

### Community 48 - "tax_settings_screen.dart"
Cohesion: 0.12
Nodes (17): FormState, createState, dispose, existing, _formKey, _inclusionType, _nameCtrl, onAdd (+9 more)

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
Nodes (103): Expenses, StockAdjustments, TaxGroups, action, actualTableName, address, _alias, aliasedName (+95 more)

### Community 53 - "cart_session.dart"
Cohesion: 0.14
Nodes (13): bool get, copyWith, customerId, fresh, heldTicketId, isEditingHeldTicket, loyaltyPointsToRedeem, openedAt (+5 more)

### Community 54 - "products_table.dart"
Cohesion: 0.10
Nodes (20): categoryId, conversionRate, createdAt, id, imagePath, isActive, isComposite, isHiddenInPos (+12 more)

### Community 55 - "held_orders_notifier.dart"
Cohesion: 0.12
Nodes (16): heldOrdersBoxProvider, HeldOrder, archive, archiveAll, _box, build, delete, deleteAllArchived (+8 more)

### Community 56 - "cartSessionProvider"
Cohesion: 0.16
Nodes (18): cartSessionProvider, clear, build, _showDiscountSheet, build, occupied, onSelect, _pickTable (+10 more)

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
Nodes (102): OrderItems, OrderTaxOverrides, Returns, TaxRates, action, actualTableName, address, _alias (+94 more)

### Community 61 - "_StoreProfileEditScreenState"
Cohesion: 0.42
Nodes (10): businessAddressProvider, businessNameProvider, businessPanProvider, businessPhoneProvider, businessTaglineProvider, didChangeDependencies, _StoreProfileEditScreenState, build (+2 more)

### Community 62 - "auto_print_test.dart"
Cohesion: 0.07
Nodes (27): devices, _ftp, printBytes, startScan, stopScan, ThermalPluginPrinter, ReceiptPrinter, Object? (+19 more)

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
Nodes (100): Table, TableInfo, AuditLog, Categories, Customers, ExpenseCategories, Expenses, OrderItems (+92 more)

### Community 68 - "render_receipt.dart"
Cohesion: 0.14
Nodes (13): bytes, customerName, g, isCopy, _kv, method, methodLabel, profile (+5 more)

### Community 69 - "Riverpod Architecture Decision (provider type per concern)"
Cohesion: 0.20
Nodes (12): Data Flow (UI to Notifier to DAO to Stream), State Management Pillar (Riverpod), build_runner Code Generation Workflow, Provider Suffix Naming Convention, Code Generation Dev Dependencies (riverpod_generator, drift_dev, build_runner), build.yaml Code Generation Config, Generated-File Exclusion (*.g.dart, *.freezed.dart), Riverpod as Sole DI Mechanism (+4 more)

### Community 70 - "Offline-First Non-Negotiable Constraint"
Cohesion: 0.18
Nodes (12): Package-Imports-Only Rule, Zero External APIs / Services, No Error Tracking, Analytics, or CI Pipeline, Enforced Lint Rules (analysis_options), Deleted Sync/Cloud-Backup Scaffolding (must not return), Platform Network Permission Lockdown, Offline-First Non-Negotiable Constraint, url_launcher Network-Adjacent Exception (+4 more)

### Community 71 - "DateTimeColumn get"
Cohesion: 0.11
Nodes (17): @DataClassName, DateTimeColumn get, Categories, createdAt, id, name, parentId, sortOrder (+9 more)

### Community 72 - "order_items_table.dart"
Cohesion: 0.15
Nodes (12): discount, id, lineTotal, orderId, OrderItems, productId, productName, quantity (+4 more)

### Community 73 - "schema_v11.dart"
Cohesion: 0.02
Nodes (101): ProductVariants, action, actualTableName, address, _alias, aliasedName, allSchemaEntities, allTables (+93 more)

### Community 74 - "app_sheet.dart"
Cohesion: 0.17
Nodes (10): cs, failurePrefix, messenger, draggable, initialSize, minSize, package:pos_app/shared/widgets/keyboard_safe.dart, required WidgetBuilder builder,
  bool (+2 more)

### Community 75 - "snapshot_service.dart"
Cohesion: 0.07
Nodes (26): File, create, createdAt, dbBytes, dbEntryName, _decode, fileNameFor, filePrefix (+18 more)

### Community 76 - "held_ticket_number_test.dart"
Cohesion: 0.08
Nodes (26): Box, dart:io, Directory, _box, formatTicketNumber, kTicketSeqKey, next, _box (+18 more)

### Community 77 - "settings_screen.dart"
Cohesion: 0.15
Nodes (12): build, SettingsScreen, package:pos_app/features/settings/presentation/widgets/appearance_section.dart, package:pos_app/features/settings/presentation/widgets/backup_section.dart, package:pos_app/features/settings/presentation/widgets/currency_section.dart, package:pos_app/features/settings/presentation/widgets/danger_section.dart, package:pos_app/features/settings/presentation/widgets/inventory_section.dart, package:pos_app/features/settings/presentation/widgets/loyalty_section.dart (+4 more)

### Community 78 - "package:pos_app/features/cart/domain/cart_item.dart"
Cohesion: 0.10
Nodes (20): _, compoundTax, lineItemTax, priceBeforeTax, _round, TaxCalculator, invoicePrefix, placeOrder (+12 more)

### Community 79 - "databaseProvider"
Cohesion: 0.13
Nodes (17): databaseProvider, _delete, _save, _showAddCategoryDialog, CategoriesScreen, category, _colorFor, _confirmDelete (+9 more)

### Community 80 - "audit_log_table.dart"
Cohesion: 0.20
Nodes (9): action, AuditLog, createdAt, entityId, entityType, id, metadata, newValue (+1 more)

### Community 81 - "schema_v7.dart"
Cohesion: 0.02
Nodes (101): Categories, Customers, Products, TaxGroupMembers, action, actualTableName, address, _alias (+93 more)

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
Nodes (101): Orders, OrderTaxes, ProductComponents, action, actualTableName, address, _alias, aliasedName (+93 more)

### Community 88 - "Milestone 1 — v1 Foundation & Core POS"
Cohesion: 0.25
Nodes (8): Responsive Desktop POS Layout Rule, Local Auth (no external identity provider), Platform Requirements (Android API 21+, iOS 12+), Milestone 1 — v1 Foundation & Core POS, ROADMAP Phase 2 — Onboarding & Store Configuration, ROADMAP Phase 6 — Order History & Local Reporting, ROADMAP Phase 8 — Final Stabilization, v1 Phase 1 — First-Run & Onboarding

### Community 89 - "inventory_card.dart"
Cohesion: 0.10
Nodes (19): _apply, badgeColor, build, canDecrement, canIncrement, cs, _decrement, icon (+11 more)

### Community 90 - "tables_dao.dart"
Cohesion: 0.25
Nodes (7): deleteById, getAll, getById, upsert, watchAll, package:pos_app/core/database/tables/tables_table.dart, _

### Community 91 - "order_summary.dart"
Cohesion: 0.09
Nodes (22): ColorScheme, addColor, cs, fmt, label, onTap, ref, _showTaxPicker (+14 more)

### Community 92 - "customer_form.dart"
Cohesion: 0.12
Nodes (16): _addressCtrl, build, createState, customer, _delete, _discountCtrl, _discountIsPercent, dispose (+8 more)

### Community 93 - "currencyFormatterProvider"
Cohesion: 0.17
Nodes (19): invoicePrefixProvider, build, CartDetailScreen, build, initState, _PaymentActionBar, _PaymentScreenState, _placeOrder (+11 more)

### Community 94 - "Dual Data Layer (Drift + Hive)"
Cohesion: 0.38
Nodes (7): Dual Data Layer (Drift + Hive), Navigation Pillar (GoRouter routerProvider), Drift Layout Convention (tables, daos, AppDatabase migrations), No Hardcoded Colors (AppTheme / colorScheme), Premium Glassmorphic Dark Aesthetic, ROADMAP Phase 7 — Polish & Power Features, v1 Phase 8 — Polish & Theme

### Community 95 - "Banned Runtime-Fetching Packages"
Cohesion: 0.33
Nodes (7): Local-Only Data Storage (Drift file + Hive + path_provider), Banned Runtime-Fetching Packages, Export & Sharing Stack (share_plus, csv, file_picker, permission_handler), Bundled JetBrainsMono Font Family, Connectivity Detection task (0.5, connectivity_plus), v1 Phase 5 — Backup & Data Safety (local-only), v1 Phase 6 — Expenses & Reports

### Community 96 - "app_root.dart"
Cohesion: 0.12
Nodes (16): dart:async, build, child, _container, createState, dispose, initState, message (+8 more)

### Community 97 - "SettingsNotifier"
Cohesion: 0.67
Nodes (3): @immutable, AppSettings, SettingsNotifier

### Community 98 - "schema_v6.dart"
Cohesion: 0.02
Nodes (98): AuditLog, ExpenseCategories, GeneratedColumn, Iterable, ProductModifiers, ProductTaxes, action, actualTableName (+90 more)

### Community 99 - "settingsProvider"
Cohesion: 0.16
Nodes (17): defaultTaxIdProvider, settingsProvider, build, reset, skip, taxRatesStreamProvider, _save, _ThemePickerSheet (+9 more)

### Community 100 - "audit_log_screen.dart"
Cohesion: 0.18
Nodes (12): action, _ActionChip, _actionColor, _actionIcon, AuditLogScreen, _auditLogsProvider, build, color (+4 more)

### Community 101 - "invoice_numbering_test.dart"
Cohesion: 0.11
Nodes (18): AuditService, processReturn, transaction, transaction, voidOrder, package:pos_app/core/services/audit_service.dart, package:pos_app/features/orders/domain/order_number.dart, package:pos_app/features/returns/domain/void_order.dart (+10 more)

### Community 102 - "Open POS Brand Logo"
Cohesion: 0.53
Nodes (6): Interlocking Circular Arrow Mark, Green-to-Blue Gradient Brand Palette, Open POS Brand Logo, OPEN POS Wordmark, Point-of-Sale Product Identity, Transaction Cycle Visual Metaphor

### Community 103 - "customer_card.dart"
Cohesion: 0.11
Nodes (16): Color, _Badge, bg, customer, CustomerCard, fg, icon, label (+8 more)

### Community 104 - "snapshot_providers.dart"
Cohesion: 0.09
Nodes (21): dart:isolate, databaseFile, dir, kDatabaseFileName, openConnection, autoBackupDir, create, createAndShare (+13 more)

### Community 105 - "dashboard_body.dart"
Cohesion: 0.12
Nodes (15): ReportData, build, _buildKpiRows, cs, DashboardBody, data, _fmt, isCustomRange (+7 more)

### Community 106 - "inventory_screen.dart"
Cohesion: 0.15
Nodes (13): createState, dispose, _filter, _filtered, InventoryScreen, _InventoryScreenState, _search, _searchCtrl (+5 more)

### Community 107 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.11
Nodes (19): _db, DemoDataService, seed, _settings, autoPrintOrder, AutoPrintService, autoPrintServiceProvider, printOrder (+11 more)

### Community 108 - "package:pos_app/features/cart/presentation/providers/cart_notifier.dart"
Cohesion: 0.13
Nodes (13): dart:ui, CheckoutBar, customerId, customers, watch, activeHeld, cartTableId, tableId (+5 more)

### Community 109 - "ConsumerState"
Cohesion: 0.12
Nodes (20): ConsumerState, ConsumerStatefulWidget, lowStockThresholdProvider, PaymentScreen, CustomerForm, _CustomerFormState, ProductFormScreen, _ProductFormScreenState (+12 more)

### Community 111 - "package:flutter/services.dart"
Cohesion: 0.29
Nodes (6): build, currencySymbol, nameController, rateController, TaxStep, package:flutter/services.dart

### Community 112 - "occupied_tables_test.dart"
Cohesion: 0.20
Nodes (9): TicketSequence, package:pos_app/features/tables/domain/tables_provider.dart, build, _container, heldOrders, main, _MemorySequence, _n (+1 more)

### Community 113 - "receipt_printer.dart"
Cohesion: 0.18
Nodes (10): address, devices, DiscoveredPrinter, name, printBytes, PrinterTransport, startScan, stopScan (+2 more)

### Community 114 - "package:pos_app/core/theme/tokens.dart"
Cohesion: 0.12
Nodes (14): build, cs, highlightIndex, labels, MiniBarChart, values, build, emphasis (+6 more)

### Community 115 - "TextColumn get"
Cohesion: 0.09
Nodes (20): BoolColumn get, color, ExpenseCategories, id, isDefault, name, id, isActive (+12 more)

### Community 116 - "String?"
Cohesion: 0.09
Nodes (20): double?, IconData?, action, AppEmptyState, build, icon, subtitle, title (+12 more)

### Community 117 - "package:pos_app/core/database/app_database.dart"
Cohesion: 0.15
Nodes (11): generated/schema.dart, db, package:drift_dev/api/migrations_common.dart, package:drift_dev/api/migrations_native.dart, package:drift/native.dart, package:pos_app/core/database/app_database.dart, SchemaVerifier, main (+3 more)

### Community 118 - "build"
Cohesion: 0.18
Nodes (14): build, posFilterProvider, build, CartScreen, _CartScreenState, initState, favoritesProvider, productSalesCountProvider (+6 more)

### Community 119 - "tax_rates_table.dart"
Cohesion: 0.18
Nodes (10): createdAt, id, inclusionType, isActive, isCompound, name, rate, roundingMode (+2 more)

### Community 120 - "order_number.dart"
Cohesion: 0.40
Nodes (4): int get, billNo, displayNo, String get

### Community 121 - "categoriesStreamProvider"
Cohesion: 0.16
Nodes (14): build, categoriesStreamProvider, productsByCategoryProvider, productsFilterProvider, productsStreamProvider, build, _CategoryCard, build (+6 more)

### Community 122 - "GeneratedDatabase"
Cohesion: 0.25
Nodes (8): GeneratedDatabase, DatabaseAtV10, DatabaseAtV11, DatabaseAtV4, DatabaseAtV6, DatabaseAtV7, DatabaseAtV8, DatabaseAtV9

### Community 123 - "tax_dao.dart"
Cohesion: 0.22
Nodes (8): getAll, getById, getRatesForProduct, setProductTaxes, upsertRate, watchActive, package:pos_app/core/database/tables/product_taxes_table.dart, _

### Community 124 - "VoidCallback?"
Cohesion: 0.13
Nodes (13): build, _labels, onSkip, step, WizardHeader, build, canNext, onBack (+5 more)

### Community 125 - "onboarding_notifier.dart"
Cohesion: 0.12
Nodes (16): settingsBoxProvider, OnboardingState, back, build, finish, next, OnboardingNotifier, setBusinessName (+8 more)

### Community 126 - "order_taxes_table.dart"
Cohesion: 0.22
Nodes (8): id, orderId, OrderTaxes, taxableAmount, taxAmount, taxRateId, taxRateName, taxRatePercent

### Community 127 - "onboarding_state.dart"
Cohesion: 0.13
Nodes (13): dart:convert, _cache, CountryRepository, load, businessName, copyWith, country, saving (+5 more)

### Community 128 - "customer_picker_sheet.dart"
Cohesion: 0.20
Nodes (10): int?, build, createState, CustomerPickerSheet, _CustomerPickerSheetState, customers, onSelect, _search (+2 more)

### Community 129 - "ticket_header.dart"
Cohesion: 0.20
Nodes (10): build, _pickCustomer, session, TicketHeader, customersStreamProvider, build, package:intl/intl.dart, package:pos_app/features/cart/presentation/widgets/customer_picker_sheet.dart (+2 more)

### Community 130 - "confirm_step.dart"
Cohesion: 0.18
Nodes (10): build, children, ConfirmStep, icon, isLast, label, state, _SummaryCard (+2 more)

### Community 131 - "package:pos_app/core/utils/currency_formatter.dart"
Cohesion: 0.25
Nodes (7): buildReceiptText, dateFmt, join, lines, o, package:pos_app/core/utils/currency_formatter.dart, package:pos_app/features/receipts/presentation/receipt_body.dart

### Community 133 - "State"
Cohesion: 0.27
Nodes (10): AppRoot, AppRootState, _NoticeOverlay, _NoticeOverlayState, DiscountSheet, _DiscountSheetState, _ComponentPickerSheet, _ComponentPickerSheetState (+2 more)

### Community 134 - "discount_sheet.dart"
Cohesion: 0.20
Nodes (9): build, createState, _ctrl, currentDiscount, dispose, initState, isPercent, _parsed (+1 more)

### Community 135 - "country_step.dart"
Cohesion: 0.20
Nodes (9): build, countries, CountryStep, loading, onSearch, onSelect, searchController, selected (+1 more)

### Community 136 - "cart_calculator_test.dart"
Cohesion: 0.25
Nodes (7): package:pos_app/features/cart/domain/cart_calculator.dart, item, main, money, rate, roundTripsAt2dp, session

### Community 137 - "place_order_test.dart"
Cohesion: 0.25
Nodes (7): audit, db, main, makeItem, makeSession, makeSummary, seedProduct

### Community 138 - "build"
Cohesion: 0.40
Nodes (5): build, _loadTicket, Route /cart, Route /customers, Route /tables

### Community 139 - "business_name_step.dart"
Cohesion: 0.40
Nodes (4): build, BusinessNameStep, controller, TextEditingController

## Ambiguous Edges - Review These
- `Responsive Desktop POS Layout Rule` → `Platform Requirements (Android API 21+, iOS 12+)`  [AMBIGUOUS]
  .planning/codebase/CONVENTIONS.md · relation: conceptually_related_to
- `pos_app Package Manifest (v1.0.0+9)` → `v1 Phase 3 — Core Sales Loop`  [AMBIGUOUS]
  v1_roadmap.md · relation: references
- `pos_app Package Manifest (v1.0.0+9)` → `v1 Phase 7 — Customers, Loyalty & Audit`  [AMBIGUOUS]
  v1_roadmap.md · relation: references

## Knowledge Gaps
- **2266 isolated node(s):** `refresh`, `getKeyboardDismissBehavior`, `_slide`, `ping`, `_container` (+2261 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **2 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `Responsive Desktop POS Layout Rule` and `Platform Requirements (Android API 21+, iOS 12+)`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **What is the exact relationship between `pos_app Package Manifest (v1.0.0+9)` and `v1 Phase 3 — Core Sales Loop`?**
  _Edge tagged AMBIGUOUS (relation: references) - confidence is low._
- **What is the exact relationship between `pos_app Package Manifest (v1.0.0+9)` and `v1 Phase 7 — Customers, Loyalty & Audit`?**
  _Edge tagged AMBIGUOUS (relation: references) - confidence is low._
- **Why does `Return` connect `DataClass` to `app_database.dart`, `tron_border.dart`, `products_provider.dart`, `render_receipt.dart`, `money.dart`, `receipt_pdf_service.dart`, `package:pos_app/core/database/app_database.dart`?**
  _High betweenness centrality (0.031) - this node is a cross-community bridge._
- **Why does `CurrencyFormatter` connect `grid_product_tile.dart` to `receipt_body.dart`, `products_provider.dart`, `product_tile.dart`, `home.dart`, `expenses_screen.dart`, `ConsumerWidget`, `orders_screen.dart`, `order_detail_screen.dart`, `products_screen.dart`, `order_summary.dart`, `payment_screen.dart`, `receipt_screen.dart`?**
  _High betweenness centrality (0.008) - this node is a cross-community bridge._
- **Why does `Customer` connect `DataClass` to `app_database.dart`, `receipt_body.dart`, `customer_card.dart`, `customer_form.dart`, `order_detail_screen.dart`, `payment_screen.dart`, `receipt_screen.dart`?**
  _High betweenness centrality (0.008) - this node is a cross-community bridge._
- **What connects `refresh`, `getKeyboardDismissBehavior`, `_slide` to the rest of the system?**
  _2266 weakly-connected nodes found - possible documentation gaps or missing edges._