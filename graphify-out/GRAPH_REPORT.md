# Graph Report - agent-ad014bab3599f6896  (2026-11-26)

## Corpus Check
- 333 files · ~273,741 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 5694 nodes · 9070 edges · 198 communities (194 shown, 4 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `da164ec2`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- app_database.dart
- schema_v16.dart
- schema_v15.dart
- schema_v14.dart
- schema_v11.dart
- schema_v12.dart
- schema_v10.dart
- schema_v13.dart
- schema_v9.dart
- schema_v7.dart
- schema_v8.dart
- schema_v4.dart
- schema_v6.dart
- snapshot_service.dart
- hive_provider.dart
- Table
- AppDatabase
- screen_providers_dispose_test.dart
- cart_notifier.dart
- snapshot_providers.dart
- usage_counter.dart
- report_figures_test.dart
- package:pos_app/features/cart/presentation/providers/cart_notifier.dart
- usage_summary.dart
- calc_oracle.dart
- report_data.dart
- usage_host.dart
- shifts_dao.dart
- loyalty_section.dart
- package:hive_flutter/hive_flutter.dart
- DataClass
- backup_screen.dart
- receipt_screen.dart
- expenses_screen.dart
- restore_merge_marker_test.dart
- product_form_screen.dart
- products_provider.dart
- cartSessionProvider
- held_tickets_bar.dart
- _grammar.dart
- backup_repository.dart
- review_controller.dart
- String?
- _
- orders_screen.dart
- backup/share_origin_test.dart
- StatelessWidget
- restore_recovery_test.dart
- orders_dao.dart
- app.dart
- home.dart
- render_receipt.dart
- most_sold_test.dart
- learn_screen.dart
- app_root.dart
- csv_text.dart
- country_step.dart
- receipt_printer.dart
- Milestone 1: v1 (Foundation & Core POS)
- @DriftAccessor
- package:pos_app/core/services/audit_service.dart
- defaultTaxIdProvider
- shifts_dao_test.dart
- IntColumn get
- sell_screen_rebuild_test.dart
- package:flutter/material.dart
- settings_screen.dart
- pos_catalog_provider.dart
- product_tile.dart
- customer_card.dart
- order_detail_screen.dart
- orders_table.dart
- printer_setup_screen.dart
- receipt_pdf_service.dart
- usage_constants.dart
- snapshot_photos_test.dart
- money.dart
- payment_screen.dart
- onboarding_screen.dart
- products_screen.dart
- pos_filter_provider.dart
- customers_screen.dart
- tax_dao.dart
- products_dao.dart
- ConsumerWidget
- tables_screen.dart
- held_order.dart
- receipt_body.dart
- package:flutter_test/flutter_test.dart
- snapshot_service_test.dart
- products_table.dart
- app_theme.dart
- _
- cart_summary.dart
- order_summary.dart
- inventory_card.dart
- order_history.dart
- Open POS
- build
- tokens.dart
- customer_form.dart
- star_printer.dart
- receipt_roll_pdf.dart
- usage_ask_controller.dart
- restore_merge_test.dart
- payment_screen_test.dart
- escpos_raster.dart
- tax_settings_screen.dart
- order_taxes_table.dart
- bundled_fonts.dart
- article_detail_screen.dart
- schema.dart
- ConsumerState
- render_receipt_image.dart
- cart_item.dart
- audit_log_screen.dart
- databaseProvider
- dashboard_body.dart
- auto_print_test.dart
- escpos_raster_test.dart
- package:flutter_riverpod/flutter_riverpod.dart
- table_selector.dart
- tax_section.dart
- review_controller_test.dart
- package:flutter/services.dart
- thermal_plugin_printer.dart
- review_policy.dart
- migration_test.dart
- sales.dart
- package:drift/drift.dart
- tax_rates_table.dart
- dart:io
- VoidCallback?
- v1 Roadmap — Flutter Offline-First POS
- cart_session.dart
- _PrinterSetupScreenState
- store_profile_edit_screen.dart
- DateTime
- customers_table.dart
- tron_border.dart
- GeneratedDatabase
- expenses_dao.dart
- order_items_table.dart
- shifts_table.dart
- support_contact.dart
- support_screen.dart
- expenses_table.dart
- app_sheet.dart
- cart_line_item.dart
- inventory_filter_bar.dart
- inventory_screen.dart
- discount_sheet.dart
- _StoreProfileEditScreenState
- package:pos_app/core/database/app_database.dart
- package:intl/intl.dart
- usage_screen_test.dart
- returns_table.dart
- receipt_roll_pdf_test.dart
- int?
- customers_dao.dart
- pos_cart_actions.dart
- package:flutter/foundation.dart
- onboarding_state.dart
- settingsProvider
- usage_host_test.dart
- unit_conversion.dart
- held_orders_notifier.dart
- _
- share_origin.dart
- store_review_prompter.dart
- Return
- occupied_tables_test.dart
- Projects Dependencies
- External Integrations
- receipt_tax_labels_test.dart
- package:pos_app/features/orders/domain/order_number.dart
- @visibleForTesting
- package:pos_app/core/utils/currency_formatter.dart
- Project Conventions
- Technology Stack
- audit_dao.dart
- tables_dao.dart
- usage_event.dart
- appearance_section.dart
- @immutable
- dart:convert
- int get
- printer_errors.dart
- install_macos.sh
- CLAUDE.md
- app_version.dart
- _DeflatedFile
- _FileSink
- support_contact_test.dart
- currencies.dart
- dart:async
- ReceiptPrinter
- review_prompter.dart

## God Nodes (most connected - your core abstractions)
1. `AppDatabase` - 52 edges
2. `databaseProvider` - 36 edges
3. `Return` - 31 edges
4. `_` - 28 edges
5. `cartSessionProvider` - 25 edges
6. `currencyFormatterProvider` - 22 edges
7. `DataClass` - 20 edges
8. `settingsProvider` - 20 edges
9. `AuditService` - 20 edges
10. `usageCounterProvider` - 20 edges

## Surprising Connections (you probably didn't know these)
- `_CutAfter` --inherits--> `AppDatabase`  [EXTRACTED]
  test/drift/migration_test.dart → lib/core/database/app_database.dart
- `_GatedAudit` --inherits--> `AuditService`  [EXTRACTED]
  test/features/cart/payment_screen_test.dart → lib/core/services/audit_service.dart
- `_FixedSessionNotifier` --inherits--> `CartSessionNotifier`  [EXTRACTED]
  test/features/tables/occupied_tables_test.dart → lib/features/cart/presentation/providers/cart_notifier.dart
- `FakeReceiptPrinter` --implements--> `ReceiptPrinter`  [EXTRACTED]
  test/features/printing/auto_print_test.dart → lib/features/printing/domain/receipt_printer.dart
- `_FakePrompter` --implements--> `ReviewPrompter`  [EXTRACTED]
  test/features/review/review_controller_test.dart → lib/features/review/domain/review_prompter.dart

## Import Cycles
- None detected.

## Communities (198 total, 4 thin omitted)

### Community 0 - "app_database.dart"
Cohesion: 0.01
Nodes (294): class OrderTaxOverride extends, class ProductComponent extends, ColumnFilters, ColumnOrderings, backfillInvoiceNumbers, backfillV14, currentSchemaVersion, migration (+286 more)

### Community 1 - "schema_v16.dart"
Cohesion: 0.02
Nodes (130): Shifts, action, actualTableName, address, _alias, aliasedName, allSchemaEntities, allTables (+122 more)

### Community 2 - "schema_v15.dart"
Cohesion: 0.02
Nodes (109): action, actualTableName, address, _alias, aliasedName, allSchemaEntities, allTables, amount (+101 more)

### Community 3 - "schema_v14.dart"
Cohesion: 0.02
Nodes (102): Returns, action, actualTableName, address, _alias, aliasedName, allSchemaEntities, allTables (+94 more)

### Community 4 - "schema_v11.dart"
Cohesion: 0.02
Nodes (118): TaxGroups, action, actualTableName, address, _alias, aliasedName, allSchemaEntities, allTables (+110 more)

### Community 5 - "schema_v12.dart"
Cohesion: 0.02
Nodes (116): Orders, ProductComponents, action, actualTableName, address, _alias, aliasedName, allSchemaEntities (+108 more)

### Community 6 - "schema_v10.dart"
Cohesion: 0.02
Nodes (118): Index, action, actualTableName, address, _alias, aliasedName, allSchemaEntities, allTables (+110 more)

### Community 7 - "schema_v13.dart"
Cohesion: 0.02
Nodes (116): Customers, ExpenseCategories, action, actualTableName, address, _alias, aliasedName, allSchemaEntities (+108 more)

### Community 8 - "schema_v9.dart"
Cohesion: 0.02
Nodes (115): OrderTaxes, action, actualTableName, address, _alias, aliasedName, allSchemaEntities, allTables (+107 more)

### Community 9 - "schema_v7.dart"
Cohesion: 0.02
Nodes (109): OrderItems, OrderTaxOverrides, ProductTaxes, action, actualTableName, address, _alias, aliasedName (+101 more)

### Community 10 - "schema_v8.dart"
Cohesion: 0.02
Nodes (112): Categories, Expenses, Tables, action, actualTableName, address, _alias, aliasedName (+104 more)

### Community 11 - "schema_v4.dart"
Cohesion: 0.02
Nodes (110): AuditLog, ProductVariants, StockAdjustments, action, actualTableName, address, _alias, aliasedName (+102 more)

### Community 12 - "schema_v6.dart"
Cohesion: 0.02
Nodes (107): GeneratedColumn, ProductModifiers, Products, TaxGroupMembers, TaxRates, action, actualTableName, address (+99 more)

### Community 13 - "snapshot_service.dart"
Cohesion: 0.02
Nodes (87): InputFileStream, _absentSuffix, add, _addDeflated, _addStored, assertNoPendingRestore, _bakSuffix, _baseName (+79 more)

### Community 14 - "hive_provider.dart"
Cohesion: 0.03
Nodes (76): AppSettings, autoBackupEnabled, autoBackupLastAt, _box, build, businessAddress, businessName, businessNameOrDefault (+68 more)

### Community 15 - "Table"
Cohesion: 0.06
Nodes (70): Table, TableInfo, OrderTaxes, Orders, ProductTaxes, ProductVariants, Returns, Products (+62 more)

### Community 16 - "AppDatabase"
Cohesion: 0.06
Nodes (47): _, @DriftDatabase, AppDatabase, AuditService, package:pos_app/features/returns/domain/process_return.dart, package:pos_app/features/returns/domain/void_order.dart, ../../_support/sales.dart, ../../_support/test_db.dart (+39 more)

### Community 17 - "screen_providers_dispose_test.dart"
Cohesion: 0.13
Nodes (13): package:pos_app/features/audit/presentation/audit_log_screen.dart, package:pos_app/features/expenses/presentation/expenses_screen.dart, package:pos_app/features/orders/domain/order_history.dart, ProviderContainer, add, c, cart, line (+5 more)

### Community 18 - "cart_notifier.dart"
Cohesion: 0.07
Nodes (34): ticketSequenceProvider, CartSession, addItem, addProduct, addProductInSecondaryUnit, allRates, CartNotifier, CartSessionNotifier (+26 more)

### Community 19 - "snapshot_providers.dart"
Cohesion: 0.04
Nodes (53): dart:ui, databaseFile, dir, kDatabaseFileName, openConnection, ShareFiles, shareFilesWithOs, autoBackupDir (+45 more)

### Community 20 - "usage_counter.dart"
Cohesion: 0.04
Nodes (47): bool?, after, askedVersion, _box, countingEnabled, countingOn, _counts, _defaultOpen (+39 more)

### Community 21 - "report_figures_test.dart"
Cohesion: 0.12
Nodes (14): package:pos_app/features/reports/domain/report_data.dart, package:pos_app/features/reports/presentation/widgets/dashboard_body.dart, audit, c, db, expense, item, main (+6 more)

### Community 22 - "package:pos_app/features/cart/presentation/providers/cart_notifier.dart"
Cohesion: 0.05
Nodes (41): customerId, customers, watch, package:pos_app/features/cart/data/place_order.dart, package:pos_app/features/cart/data/ticket_sequence.dart, package:pos_app/features/cart/domain/cart_item.dart, package:pos_app/features/cart/presentation/providers/cart_notifier.dart, item (+33 more)

### Community 23 - "usage_summary.dart"
Cohesion: 0.04
Nodes (47): appInfo, appVersion, buildUsageSummary, bump, canSendUsageSummary, chars, count, currencyCode (+39 more)

### Community 24 - "calc_oracle.dart"
Cohesion: 0.04
Nodes (46): BigInt, int? discPermille,
  int, balance, base, baseOnHalfCent, bp, cents, d (+38 more)

### Community 25 - "report_data.dart"
Cohesion: 0.04
Nodes (48): avgOrder, changes, chartDates, chartHighlightIndex, chartTitle, chartTotals, costIsIncomplete, costOfGoods (+40 more)

### Community 26 - "usage_host.dart"
Cohesion: 0.11
Nodes (20): onboardingCompleteProvider, _ask, build, child, _counter, createState, _disclosing, dispose (+12 more)

### Community 27 - "shifts_dao.dart"
Cohesion: 0.03
Nodes (63): amount, byMethod, cash, cashRefunds, cashSales, cashTips, cashVoids, closedShifts (+55 more)

### Community 28 - "loyalty_section.dart"
Cohesion: 0.17
Nodes (14): loyaltyEarnRateProvider, loyaltyEnabledProvider, loyaltyPointValueProvider, build, createState, dispose, _earnCtrl, earnRate (+6 more)

### Community 29 - "package:hive_flutter/hive_flutter.dart"
Cohesion: 0.05
Nodes (47): Box, dart:typed_data, Directory, _box, formatTicketNumber, heldOrdersBoxProvider, kTicketSeqKey, next (+39 more)

### Community 30 - "DataClass"
Cohesion: 0.09
Nodes (41): Insertable, OrderNumberX, UpdateCompanion, AuditLogCompanion, AuditLogData, CategoriesCompanion, Category, Customer (+33 more)

### Community 31 - "backup_screen.dart"
Cohesion: 0.06
Nodes (39): autoBackupEnabledProvider, autoBackupLastAtProvider, backupRepositoryProvider, snapshotCoordinatorProvider, _AutoBackupTile, BackupScreen, _BackupScreenState, _BackupTile (+31 more)

### Community 32 - "receipt_screen.dart"
Cohesion: 0.08
Nodes (29): build, build, businessName, createState, customer, data, db, dispose (+21 more)

### Community 33 - "expenses_screen.dart"
Cohesion: 0.05
Nodes (49): _amountCtrl, build, categories, category, _CategoryChips, _categoryId, _check, _Chip (+41 more)

### Community 34 - "restore_merge_marker_test.dart"
Cohesion: 0.07
Nodes (32): attachUsageRouteCounter, last, onNavigate, topRouteOf, main, startup, fatal, notice (+24 more)

### Community 35 - "product_form_screen.dart"
Cohesion: 0.06
Nodes (36): _categoryId, _ComponentEntry, _components, _conversionCtrl, createState, _delete, didChangeDependencies, dispose (+28 more)

### Community 36 - "products_provider.dart"
Cohesion: 0.10
Nodes (20): applyProductsFilter, clearSearch, copyWith, list, mostSoldWindow, outOfStockOnly, productSalesCountProvider, ProductsFilterNotifier (+12 more)

### Community 37 - "cartSessionProvider"
Cohesion: 0.14
Nodes (18): _createFullBackup, _runExport, cartSessionProvider, clear, holdCurrentCart, _loadTicket, _showDiscountSheet, build (+10 more)

### Community 38 - "held_tickets_bar.dart"
Cohesion: 0.12
Nodes (21): AnimationController, archivedHeldOrdersProvider, heldOrdersProvider, CheckoutBar, build, _buildActiveList, _buildArchivedList, createState (+13 more)

### Community 39 - "_grammar.dart"
Cohesion: 0.18
Nodes (10): _bucket, _events, expectGrammar, fixed, i, kUsageLineGrammar, _labels, lines (+2 more)

### Community 40 - "backup_repository.dart"
Cohesion: 0.06
Nodes (34): added, _csvEol, csvImportExplanation, CsvImportReport, db, exportCustomers, exportExpenses, exportOrders (+26 more)

### Community 41 - "review_controller.dart"
Cohesion: 0.10
Nodes (19): Duration, appVersion, _guard, _inFlight, onReceiptDismissed, prompter, ReviewCheck, ReviewController (+11 more)

### Community 42 - "String?"
Cohesion: 0.06
Nodes (34): double?, IconData?, build, cs, highlightIndex, labels, MiniBarChart, values (+26 more)

### Community 43 - "_"
Cohesion: 0.10
Nodes (20): dart:math, _, CartCalculator, compute, _roundingModeFor, package:pos_app/core/utils/tax_calculator.dart, package:pos_app/features/cart/domain/cart_calculator.dart, package:pos_app/features/cart/domain/cart_session.dart (+12 more)

### Community 44 - "orders_screen.dart"
Cohesion: 0.07
Nodes (32): orderHistoryProvider, _body, build, _clearQuery, createState, cs, customerName, _debounce (+24 more)

### Community 45 - "backup/share_origin_test.dart"
Cohesion: 0.06
Nodes (30): FormatException, package:pos_app/features/backup/data/backup_repository.dart, package:pos_app/features/backup/data/csv_text.dart, package:pos_app/features/backup/presentation/backup_screen.dart, package:pos_app/features/receipts/presentation/receipt_pdf_service.dart, customers, db, main (+22 more)

### Community 46 - "StatelessWidget"
Cohesion: 0.08
Nodes (27): build, cs, key_, _KeyChip, keys, label, _SectionHeader, _ShortcutRow (+19 more)

### Community 47 - "restore_recovery_test.dart"
Cohesion: 0.07
Nodes (32): Exception, FileSystemException, ShiftStateException, RestoreJournalFormatException, PendingRestoreException, RestoreFatalException, RestoreRolledBackException, SnapshotFormatException (+24 more)

### Community 48 - "orders_dao.dart"
Cohesion: 0.06
Nodes (32): completedOrderCount, _escapeLike, getById, getItems, getTaxBreakdown, hasRestockedReturn, historyPage, incrementPrintCount (+24 more)

### Community 49 - "app.dart"
Cohesion: 0.07
Nodes (30): ChangeNotifier, GoRouter, AppScrollBehavior, getKeyboardDismissBehavior, ping, POSApp, refresh, router (+22 more)

### Community 50 - "home.dart"
Cohesion: 0.07
Nodes (30): demoDataServiceProvider, posCatalogProvider, posFilterProvider, CartScreen, _CartScreenState, categories, _CategoryRow, _Chip (+22 more)

### Community 51 - "render_receipt.dart"
Cohesion: 0.14
Nodes (13): bytes, customerName, g, isCopy, _kv, method, methodLabel, profile (+5 more)

### Community 52 - "most_sold_test.dart"
Cohesion: 0.06
Nodes (33): int tea,, package:drift/native.dart, package:pos_app/core/services/demo_data_service.dart, package:pos_app/features/review/review_providers.dart, QueryInterceptor, ../../_support/query_recorder.dart, db, expectIndexed (+25 more)

### Community 53 - "learn_screen.dart"
Cohesion: 0.13
Nodes (14): _Article, _ArticleCard, _articles, category, cs, description, icon, LearnScreen (+6 more)

### Community 54 - "app_root.dart"
Cohesion: 0.06
Nodes (34): AppRoot, AppRootState, autoBackupDelay, _autoBackupRun, autoBackupScheduledForTest, _autoBackupTimer, build, child (+26 more)

### Community 55 - "csv_text.dart"
Cohesion: 0.07
Nodes (29): _bad, boolOf, cell, cellQuoted, _cells, _columns, CsvRow, CsvTable (+21 more)

### Community 56 - "country_step.dart"
Cohesion: 0.10
Nodes (18): build, BusinessNameStep, controller, build, countries, CountryStep, loading, onSearch (+10 more)

### Community 57 - "receipt_printer.dart"
Cohesion: 0.06
Nodes (30): address, data, devices, DiscoveredPrinter, driver, escPosPrinterProvider, fmt, fromKey (+22 more)

### Community 58 - "Milestone 1: v1 (Foundation & Core POS)"
Cohesion: 0.07
Nodes (26): 1. State Management (Riverpod), 2. Navigation (GoRouter), 3. Data Layer (Drift & Hive), 4. Hardware Integration, Core Pillars, Data Flow, Directory Structure, Overview (+18 more)

### Community 59 - "@DriftAccessor"
Cohesion: 0.14
Nodes (20): @DriftAccessor, _$AuditDaoMixin, _$CustomersDaoMixin, DatabaseAccessor, _$ExpensesDaoMixin, _$InventoryDaoMixin, AuditDao, CustomersDao (+12 more)

### Community 60 - "package:pos_app/core/services/audit_service.dart"
Cohesion: 0.11
Nodes (17): components, cost, invoicePrefix, placeOrder, roundMoney, transaction, _unitCostNow, left (+9 more)

### Community 61 - "defaultTaxIdProvider"
Cohesion: 0.33
Nodes (9): defaultTaxIdProvider, invoicePrefixProvider, build, reset, taxRatesStreamProvider, build, TaxSection, build (+1 more)

### Community 62 - "shifts_dao_test.dart"
Cohesion: 0.17
Nodes (11): package:pos_app/core/database/daos/shifts_dao.dart, at, close, dao, day, db, main, order (+3 more)

### Community 63 - "IntColumn get"
Cohesion: 0.07
Nodes (32): @DataClassName, DateTimeColumn get, IntColumn get, action, createdAt, entityId, entityType, id (+24 more)

### Community 64 - "sell_screen_rebuild_test.dart"
Cohesion: 0.05
Nodes (42): AppBar, CustomPaint, FilterChip, GridView, product, build, ListView, MaterialPageRoute (+34 more)

### Community 65 - "package:flutter/material.dart"
Cohesion: 0.09
Nodes (20): EditableText, build, SettingsSectionHeader, title, build, ThemePreviewScreen, build, child (+12 more)

### Community 66 - "settings_screen.dart"
Cohesion: 0.15
Nodes (12): build, SettingsScreen, package:pos_app/features/settings/presentation/widgets/appearance_section.dart, package:pos_app/features/settings/presentation/widgets/backup_section.dart, package:pos_app/features/settings/presentation/widgets/currency_section.dart, package:pos_app/features/settings/presentation/widgets/danger_section.dart, package:pos_app/features/settings/presentation/widgets/inventory_section.dart, package:pos_app/features/settings/presentation/widgets/loyalty_section.dart (+4 more)

### Community 67 - "pos_catalog_provider.dart"
Cohesion: 0.08
Nodes (24): AsyncValue, buildPosSearchIndex, cart, catalogEmpty, categoryId, committedMainUnits, favorites, favoritesOnly (+16 more)

### Community 68 - "product_tile.dart"
Cohesion: 0.10
Nodes (19): ColorScheme, bg, color, cs, icon, onDecrement, onIncrement, onTap (+11 more)

### Community 69 - "customer_card.dart"
Cohesion: 0.11
Nodes (16): Color, _Badge, bg, customer, CustomerCard, fg, icon, label (+8 more)

### Community 70 - "order_detail_screen.dart"
Cohesion: 0.09
Nodes (22): auditServiceProvider, businessName, customer, data, db, _DetailBody, _DetailData, fmt (+14 more)

### Community 71 - "orders_table.dart"
Cohesion: 0.07
Nodes (26): changeAmount, createdAt, customerId, discountIsPercent, discountTotal, discountValue, id, invoiceNo (+18 more)

### Community 72 - "printer_setup_screen.dart"
Cohesion: 0.07
Nodes (29): PrinterDriver, lastSdkNeedingLocationForBle, permissionsForScan, scanNeedsLocation, createState, _devices, _devicesSub, _disconnectSavedPrinter (+21 more)

### Community 73 - "receipt_pdf_service.dart"
Cohesion: 0.08
Nodes (23): baseStyle, billRow, boldStyle, buildReceiptPdf, bytes, customerName, _dataCell, dateFmt (+15 more)

### Community 74 - "usage_constants.dart"
Cohesion: 0.08
Nodes (23): kFeedbackAreaQuestion, kFeedbackAskAction, kFeedbackAskText, kFeedbackInstruction, kFeedbackMessageMaxLength, kFeedbackSupportRowSubtitle, kFeedbackSupportRowTitle, kOfflineFirstLine (+15 more)

### Community 75 - "snapshot_photos_test.dart"
Cohesion: 0.09
Nodes (21): File, package:archive/archive.dart, backupOf, dbFileIn, entriesOf, hasProduct, hivePathIn, _indexOf (+13 more)

### Community 76 - "money.dart"
Cohesion: 0.09
Nodes (22): allowZero, byLoss, cents, eps, exact, isRequired, kMaxMoneyAmount, kMaxMoneyAmountLabel (+14 more)

### Community 77 - "payment_screen.dart"
Cohesion: 0.06
Nodes (33): createState, customer, dispose, endsWith, fmt, icon, label, _loyaltyCtrl (+25 more)

### Community 78 - "onboarding_screen.dart"
Cohesion: 0.08
Nodes (31): onboardingNotifierProvider, _back, build, _businessNameCtrl, _canProceed, _countries, createState, dispose (+23 more)

### Community 79 - "products_screen.dart"
Cohesion: 0.09
Nodes (22): categories, _CategoryChips, categoryName, _Chip, createState, cs, dispose, fmt (+14 more)

### Community 80 - "pos_filter_provider.dart"
Cohesion: 0.12
Nodes (16): clearSearch, copyWith, favoritesOnly, isGrid, PosFilterNotifier, PosFilterState, PosSortMode, search (+8 more)

### Community 81 - "customers_screen.dart"
Cohesion: 0.12
Nodes (18): IconData get, build, createState, CustomersScreen, _CustomersScreenState, dispose, _filterAndSort, icon (+10 more)

### Community 82 - "tax_dao.dart"
Cohesion: 0.09
Nodes (21): getAll, getById, getRatesForProduct, setProductTaxes, upsertRate, watchActive, primaryKey, productId (+13 more)

### Community 83 - "products_dao.dart"
Cohesion: 0.09
Nodes (21): deductStock, deleteCategory, getAllCategories, getById, getBySku, getComponents, replaceComponents, restock (+13 more)

### Community 84 - "ConsumerWidget"
Cohesion: 0.12
Nodes (31): ConsumerWidget, cartMainUnitQtyProvider, build, CartDetailScreen, _ClearCartButton, _ListSeparator, build, initState (+23 more)

### Community 85 - "tables_screen.dart"
Cohesion: 0.10
Nodes (19): _assignToCart, _capacityCtrl, createState, dispose, existing, initState, isCurrentCartTable, isOccupied (+11 more)

### Community 86 - "held_order.dart"
Cohesion: 0.10
Nodes (20): archivedAt, copyWith, createdAt, customerId, customerName, fromJson, id, isArchived (+12 more)

### Community 87 - "receipt_body.dart"
Cohesion: 0.10
Nodes (20): _BillRow, build, businessName, customer, data, _DataCell, fmt, _HeaderCell (+12 more)

### Community 88 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.10
Nodes (16): package:flutter_test/flutter_test.dart, package:pos_app/core/utils/money.dart, package:pos_app/features/products/domain/stock_level.dart, package:pos_app/features/products/domain/unit_conversion.dart, main, main, audit, db (+8 more)

### Community 89 - "snapshot_service_test.dart"
Cohesion: 0.10
Nodes (19): ../../drift/generated/schema.dart, package:sqlite3/sqlite3.dart, craftZip, dbFileIn, expectLiveUntouched, expectRejected, hivePathIn, live (+11 more)

### Community 90 - "products_table.dart"
Cohesion: 0.10
Nodes (19): categoryId, conversionRate, createdAt, id, imagePath, isActive, isComposite, isHiddenInPos (+11 more)

### Community 91 - "app_theme.dart"
Cohesion: 0.10
Nodes (19): AppTheme, backgroundGradient, _build, ctaButtonStyle, _dark, _darkGrad, _darkScheme, _fontFamily (+11 more)

### Community 92 - "_"
Cohesion: 0.11
Nodes (20): _, _abs, bak, begin, cleanup, committed, markCommitted, message (+12 more)

### Community 93 - "cart_summary.dart"
Cohesion: 0.10
Nodes (19): amount, CartSummary, isInclusive, loyaltyDiscount, maxRedeemablePoints, name, orderDiscount, pointsRedeemed (+11 more)

### Community 94 - "order_summary.dart"
Cohesion: 0.10
Nodes (17): addColor, cs, fmt, label, onTap, ref, _showTaxPicker, summary (+9 more)

### Community 95 - "inventory_card.dart"
Cohesion: 0.10
Nodes (19): _apply, badgeColor, build, canDecrement, canIncrement, cs, _decrement, icon (+11 more)

### Community 96 - "order_history.dart"
Cohesion: 0.10
Nodes (20): _changes, copyWith, _db, dispose, error, _generation, hasMore, isLoading (+12 more)

### Community 97 - "Open POS"
Cohesion: 0.10
Nodes (19): Build from source, Contributing, Customers, Features, Get Open POS, License, macOS, Money and reports (+11 more)

### Community 98 - "build"
Cohesion: 0.13
Nodes (22): build, build, build, build, build, Route /cart, Route /categories, Route /customers (+14 more)

### Community 99 - "tokens.dart"
Cohesion: 0.11
Nodes (18): AppFonts, AppOpacity, heavy, lg, md, medium, mono, Radii (+10 more)

### Community 100 - "customer_form.dart"
Cohesion: 0.12
Nodes (15): _addressCtrl, build, createState, customer, _discountCtrl, _discountIsPercent, dispose, _emailCtrl (+7 more)

### Community 101 - "star_printer.dart"
Cohesion: 0.13
Nodes (14): _devices, _discovery, dispose, _events, _found, _isSupported, _methods, _printImages (+6 more)

### Community 102 - "receipt_roll_pdf.dart"
Cohesion: 0.09
Nodes (21): base, body, bold, buildReceiptRollPdf, buildTestPageRollPdf, dateFmt, doc, font (+13 more)

### Community 103 - "usage_ask_controller.dart"
Cohesion: 0.07
Nodes (26): afterReviewCheck, appVersion, counter, dispose, evaluate, _inFlight, markShown, pending (+18 more)

### Community 104 - "restore_merge_test.dart"
Cohesion: 0.06
Nodes (29): first, kUsageAskMinCompletedSales, kUsageAskMinDaysSinceInstall, shouldAskForFeedback, true, package:pos_app/features/review/domain/review_policy.dart, backupOf, dbFileIn (+21 more)

### Community 105 - "payment_screen_test.dart"
Cohesion: 0.11
Nodes (17): Completer, package:pos_app/core/providers/audit_service_provider.dart, package:pos_app/features/cart/presentation/payment_screen.dart, app, c, confirm, db, gate (+9 more)

### Community 106 - "escpos_raster.dart"
Cohesion: 0.11
Nodes (17): dart:isolate, Future, bytes, cached, canvas, escPosProfile, escPosRasterBytes, escPosRasterBytesSync (+9 more)

### Community 107 - "tax_settings_screen.dart"
Cohesion: 0.13
Nodes (14): FormState, createState, dispose, existing, _formKey, _inclusionType, _nameCtrl, onAdd (+6 more)

### Community 108 - "order_taxes_table.dart"
Cohesion: 0.12
Nodes (16): @TableIndex, AuditLog, Expenses, OrderItems, id, isInclusive, orderId, OrderTaxes (+8 more)

### Community 109 - "bundled_fonts.dart"
Cohesion: 0.18
Nodes (10): bundledFontData, bundledPdfFont, cached, _fontData, future, jetBrainsMonoBold, jetBrainsMonoItalic, jetBrainsMonoRegular (+2 more)

### Community 110 - "article_detail_screen.dart"
Cohesion: 0.11
Nodes (17): ArticleDetailScreen, ArticleSection, build, category, cs, heading, icon, readTime (+9 more)

### Community 111 - "schema.dart"
Cohesion: 0.11
Nodes (17): package:drift/internal/migrations.dart, schema_v10.dart, schema_v11.dart, schema_v12.dart, schema_v13.dart, schema_v14.dart, schema_v15.dart, schema_v16.dart (+9 more)

### Community 112 - "ConsumerState"
Cohesion: 0.11
Nodes (26): ConsumerState, ConsumerStatefulWidget, currencyCodeProvider, currencySymbolProvider, shareFilesProvider, _EmptyProductsState, _EmptyProductsStateState, CustomerForm (+18 more)

### Community 113 - "render_receipt_image.dart"
Cohesion: 0.17
Nodes (11): doc, escPosPrintWidthDots, isCopy, kReceiptDpi, pages, _rasterise, renderReceiptImages, renderTestPageImages (+3 more)

### Community 114 - "cart_item.dart"
Cohesion: 0.12
Nodes (16): copyWith, grossAmount, isSecondaryUnit, isTaxable, lineDiscount, lineSubtotal, mainUnitQty, name (+8 more)

### Community 115 - "audit_log_screen.dart"
Cohesion: 0.10
Nodes (19): DateTimeRange?, action, _ActionChip, _actionColor, _actionIcon, AuditLogScreen, auditLogsProvider, build (+11 more)

### Community 116 - "databaseProvider"
Cohesion: 0.09
Nodes (26): databaseProvider, _delete, _delete, _showAddCategoryDialog, categoriesStreamProvider, productsByCategoryProvider, build, CategoriesScreen (+18 more)

### Community 117 - "dashboard_body.dart"
Cohesion: 0.12
Nodes (16): ReportData, build, _buildKpiRows, cs, DashboardBody, data, _fmt, isCustomRange (+8 more)

### Community 118 - "auto_print_test.dart"
Cohesion: 0.12
Nodes (15): package:pos_app/features/printing/domain/auto_print.dart, box, db, devices, failWith, main, makeContainer, printed (+7 more)

### Community 119 - "escpos_raster_test.dart"
Cohesion: 0.15
Nodes (12): package:image/image.dart, StateError, _blockPage, _countSequence, _firstRaster, found, fromList, gsV (+4 more)

### Community 120 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.10
Nodes (20): bool get, db, _db, DemoDataService, seed, _seedDatabase, _settings, AutoPrintService (+12 more)

### Community 121 - "table_selector.dart"
Cohesion: 0.13
Nodes (20): activeHeldOrdersProvider, build, occupied, onSelect, _pickTable, selectedId, session, _TablePickerSheet (+12 more)

### Community 122 - "tax_section.dart"
Cohesion: 0.11
Nodes (17): _CurrencyPickerSheet, current, _showCurrencyPicker, createState, _ctrl, current, dispose, _editThreshold (+9 more)

### Community 123 - "review_controller_test.dart"
Cohesion: 0.07
Nodes (25): _box, _date, ensureFirstLaunch, markAnyPromptShown, markPrompted, mergeAfterRestore, mergeReviewStateAfterRestore, read (+17 more)

### Community 124 - "package:flutter/services.dart"
Cohesion: 0.09
Nodes (20): AndroidSdk, _cached, _methods, _read, sdkInt, _devices, dispose, _methods (+12 more)

### Community 125 - "thermal_plugin_printer.dart"
Cohesion: 0.12
Nodes (15): _connect, _connectTimeout, devices, _disconnect, _ftp, _pluginDevice, _printPages, printReceipt (+7 more)

### Community 126 - "review_policy.dart"
Cohesion: 0.12
Nodes (15): at, first, firstLaunchAt, kMinDaysBetweenAnyPrompts, kReviewMinCompletedSales, kReviewMinDaysBetweenPrompts, kReviewMinDaysSinceInstall, last (+7 more)

### Community 127 - "migration_test.dart"
Cohesion: 0.11
Nodes (17): generated/schema.dart, package:drift_dev/api/migrations_common.dart, package:drift_dev/api/migrations_native.dart, SchemaVerifier, allIndexes, customStatement, _CutAfter, failAt (+9 more)

### Community 128 - "sales.dart"
Cohesion: 0.13
Nodes (14): int? customerId,
  int, line, loyaltyDiscount, paymentMethod, placeOrder, points, pointsRedeemed, pointsToEarn (+6 more)

### Community 129 - "package:drift/drift.dart"
Cohesion: 0.07
Nodes (29): getAdjustmentsForOrder, getAdjustmentsForProduct, logAdjustment, stockToRestock, watchLowStock, componentProductId, compositeProductId, id (+21 more)

### Community 130 - "tax_rates_table.dart"
Cohesion: 0.11
Nodes (16): BoolColumn get, color, ExpenseCategories, id, isDefault, name, createdAt, id (+8 more)

### Community 131 - "dart:io"
Cohesion: 0.07
Nodes (25): dart:io, counts, d, deleteRestoreMergeMarker, finishPendingRestoreMerge, kRestoreMergeMarkerName, _markerFile, null (+17 more)

### Community 132 - "VoidCallback?"
Cohesion: 0.13
Nodes (13): build, _labels, onSkip, step, WizardHeader, build, canNext, onBack (+5 more)

### Community 133 - "v1 Roadmap — Flutter Offline-First POS"
Cohesion: 0.13
Nodes (14): Architecture Decisions, Deferred to v2, Drift Schema — Full Table List (v1), Phase 0 — Foundation (No UI yet), Phase 1 — First-Run & Onboarding, Phase 2 — Product & Inventory Core, Phase 3 — Core Sales Loop, Phase 4 — Receipts & Hardware (+6 more)

### Community 134 - "cart_session.dart"
Cohesion: 0.15
Nodes (12): copyWith, customerId, fresh, heldTicketId, isEditingHeldTicket, loyaltyPointsToRedeem, openedAt, orderDiscount (+4 more)

### Community 135 - "_PrinterSetupScreenState"
Cohesion: 0.30
Nodes (11): printerDeviceAddressProvider, printerDeviceNameProvider, printerDriverProvider, printerPaperWidthProvider, receiptPrinterProvider, build, PrinterSetupScreen, _PrinterSetupScreenState (+3 more)

### Community 136 - "store_profile_edit_screen.dart"
Cohesion: 0.14
Nodes (13): class, _addressCtrl, build, createState, dispose, _initialised, _label, _loading (+5 more)

### Community 137 - "DateTime"
Cohesion: 0.18
Nodes (13): DateTime, BackupRepository, package:csv/csv.dart, bytesOf, db, legacyAllOrdersWithItems, legacyOrdersCsv, legacySalesReportCsv (+5 more)

### Community 138 - "customers_table.dart"
Cohesion: 0.14
Nodes (13): address, createdAt, Customers, defaultDiscount, defaultDiscountIsPercent, email, id, isTaxExempt (+5 more)

### Community 139 - "tron_border.dart"
Cohesion: 0.15
Nodes (12): CustomPainter, color, e, extractWrappedPath, f, len, p, paint (+4 more)

### Community 140 - "GeneratedDatabase"
Cohesion: 0.15
Nodes (13): GeneratedDatabase, DatabaseAtV10, DatabaseAtV11, DatabaseAtV12, DatabaseAtV13, DatabaseAtV14, DatabaseAtV15, DatabaseAtV16 (+5 more)

### Community 141 - "expenses_dao.dart"
Cohesion: 0.15
Nodes (12): getAll, getAllCategories, insert, insertCategory, totalForPeriod, updateExpense, upsertCategory, watchAll (+4 more)

### Community 142 - "order_items_table.dart"
Cohesion: 0.15
Nodes (12): discount, id, lineTotal, orderId, productId, productName, quantity, taxAmount (+4 more)

### Community 143 - "shifts_table.dart"
Cohesion: 0.13
Nodes (14): cashRefunds, cashSales, cashTips, cashVoids, closedAt, countedCash, expectedCash, id (+6 more)

### Community 144 - "support_contact.dart"
Cohesion: 0.15
Nodes (12): canLaunch, kLinkFailureMessageDuration, _kSupportWhatsAppDigits, kSupportWhatsAppDisplay, kSupportWhatsAppUnavailable, launch, messenger, native (+4 more)

### Community 145 - "support_screen.dart"
Cohesion: 0.12
Nodes (15): build, cs, gradient, icon, _InfoRow, label, onTap, _SectionHeader (+7 more)

### Community 146 - "expenses_table.dart"
Cohesion: 0.17
Nodes (11): amount, categoryId, createdAt, date, id, isRecurring, isTaxDeductible, notes (+3 more)

### Community 147 - "app_sheet.dart"
Cohesion: 0.17
Nodes (10): cs, failurePrefix, messenger, draggable, initialSize, minSize, package:pos_app/shared/widgets/keyboard_safe.dart, required WidgetBuilder builder,
  bool (+2 more)

### Community 148 - "cart_line_item.dart"
Cohesion: 0.13
Nodes (13): CurrencyFormatter, CartItem, build, fmt, icon, item, onPressed, _QtyButton (+5 more)

### Community 149 - "inventory_filter_bar.dart"
Cohesion: 0.17
Nodes (11): build, _Chip, color, InventoryFilterBar, label, lowCount, onSelect, onTap (+3 more)

### Community 150 - "inventory_screen.dart"
Cohesion: 0.09
Nodes (25): Iterable, lowStockThresholdProvider, _fitsStock, build, createState, dispose, _filter, _filtered (+17 more)

### Community 151 - "discount_sheet.dart"
Cohesion: 0.17
Nodes (12): double get, build, createState, _ctrl, currentDiscount, DiscountSheet, _DiscountSheetState, dispose (+4 more)

### Community 152 - "_StoreProfileEditScreenState"
Cohesion: 0.42
Nodes (10): businessAddressProvider, businessNameProvider, businessPanProvider, businessPhoneProvider, businessTaglineProvider, didChangeDependencies, _StoreProfileEditScreenState, build (+2 more)

### Community 153 - "package:pos_app/core/database/app_database.dart"
Cohesion: 0.10
Nodes (17): _db, log, orderPlaced, orderRefunded, orderVoided, settingChanged, taxOverridden, isLowStock (+9 more)

### Community 154 - "package:intl/intl.dart"
Cohesion: 0.18
Nodes (10): decimalDigits, _fmt, format, formatPlain, locale, _plainFmt, symbol, tryParse (+2 more)

### Community 155 - "usage_screen_test.dart"
Cohesion: 0.04
Nodes (47): ButtonStyleButton, _grammar.dart, UsageCounter, _confirmReset, _counter, createState, dispose, initState (+39 more)

### Community 156 - "returns_table.dart"
Cohesion: 0.12
Nodes (15): createdAt, id, orderId, OrderTaxOverrides, originalTax, overrideTax, reason, amount (+7 more)

### Community 157 - "receipt_roll_pdf_test.dart"
Cohesion: 0.18
Nodes (10): package:pdf/pdf.dart, package:pos_app/features/printing/domain/receipt_roll_pdf.dart, package:pos_app/features/printing/domain/render_receipt_image.dart, doc, fmt, main, order, _pageFormats (+2 more)

### Community 158 - "int?"
Cohesion: 0.15
Nodes (14): int?, build, createState, CustomerPickerSheet, _CustomerPickerSheetState, customers, onSelect, _search (+6 more)

### Community 159 - "customers_dao.dart"
Cohesion: 0.20
Nodes (9): addLoyaltyPoints, getAll, getById, redeemLoyaltyPoints, search, upsert, watchAll, package:pos_app/core/database/tables/customers_table.dart (+1 more)

### Community 160 - "pos_cart_actions.dart"
Cohesion: 0.14
Nodes (13): CartNotifier get, add, _allowQty, _cart, _committed, _container, _messenger, pickUnit (+5 more)

### Community 161 - "package:flutter/foundation.dart"
Cohesion: 0.11
Nodes (16): restartNoticeShowing, apple, _encode, _lineBreak, mailtoLink, query, smsLink, target (+8 more)

### Community 162 - "onboarding_state.dart"
Cohesion: 0.10
Nodes (18): code, CountryDefault, currency, fromJson, name, symbol, taxName, taxRate (+10 more)

### Community 163 - "settingsProvider"
Cohesion: 0.13
Nodes (18): settingsBoxProvider, settingsProvider, back, build, finish, next, OnboardingNotifier, setBusinessName (+10 more)

### Community 164 - "usage_host_test.dart"
Cohesion: 0.14
Nodes (13): package:flutter/gestures.dart, package:pos_app/core/restart_notice.dart, package:pos_app/features/help/presentation/support_screen.dart, package:pos_app/features/usage/presentation/usage_host.dart, package:pos_app/features/usage/presentation/usage_screen.dart, db, expectChargeUncovered, main (+5 more)

### Community 165 - "unit_conversion.dart"
Cohesion: 0.20
Nodes (9): isValidConversionRate, kMaxConversionRate, kMinConversionRate, null, parseConversionRate, text, toInt, validateConversionRate (+1 more)

### Community 166 - "held_orders_notifier.dart"
Cohesion: 0.15
Nodes (12): HeldOrder, archive, archiveAll, _box, build, delete, deleteAllArchived, hold (+4 more)

### Community 167 - "_"
Cohesion: 0.33
Nodes (7): _, compoundTax, invoiceTax, lineItemTax, priceBeforeTax, _round, TaxCalculator

### Community 168 - "share_origin.dart"
Cohesion: 0.18
Nodes (10): bounds, box, fromLTWH, resolveShareOrigin, screen, shareOriginFor, view, widgetRect (+2 more)

### Community 169 - "store_review_prompter.dart"
Cohesion: 0.14
Nodes (12): _kAndroidListingUrl, maybeRequestReview, openStoreListing, _review, package:in_app_review/in_app_review.dart, package:url_launcher/url_launcher.dart, InAppReview, instance (+4 more)

### Community 170 - "Return"
Cohesion: 0.12
Nodes (13): formatPercent, formatPercentNumber, formatRateForEdit, formatRatePercent, kPercentDecimals, kPercentInputPattern, text, initials (+5 more)

### Community 171 - "occupied_tables_test.dart"
Cohesion: 0.20
Nodes (9): TicketSequence, package:pos_app/features/tables/domain/tables_provider.dart, build, _container, heldOrders, main, _MemorySequence, _n (+1 more)

### Community 172 - "Projects Dependencies"
Cohesion: 0.22
Nodes (8): Dev Dependencies, [Hardware] flutter_thermal_printer, Major Dependencies, Outdated / Deprecated Dependencies, Overview, [Persistence] drift, Projects Dependencies, [State Management] flutter_riverpod

### Community 173 - "External Integrations"
Cohesion: 0.22
Nodes (8): APIs & External Services, Authentication & Identity, CI/CD & Deployment, Data Storage, Environment Configuration, External Integrations, Monitoring & Observability, Webhooks & Callbacks

### Community 174 - "receipt_tax_labels_test.dart"
Cohesion: 0.20
Nodes (9): package:pos_app/features/printing/domain/render_receipt.dart, package:pos_app/features/receipts/domain/receipt_text.dart, audit, db, fmt, main, sale, seq (+1 more)

### Community 175 - "package:pos_app/features/orders/domain/order_number.dart"
Cohesion: 0.25
Nodes (7): addBack, customerId, items, label, restockOrderItems, reverseLoyalty, package:pos_app/features/orders/domain/order_number.dart

### Community 176 - "@visibleForTesting"
Cohesion: 0.22
Nodes (9): @visibleForTesting, handleExitRequest, customersCsv, expensesCsv, productsCsv, writeOrdersCsv, writeSalesReportCsv, exactAmountText (+1 more)

### Community 177 - "package:pos_app/core/utils/currency_formatter.dart"
Cohesion: 0.12
Nodes (15): buildReceiptText, dateFmt, join, lines, o, package:pos_app/core/utils/currency_formatter.dart, package:pos_app/features/receipts/domain/receipt_labels.dart, package:pos_app/features/receipts/presentation/receipt_body.dart (+7 more)

### Community 178 - "Project Conventions"
Cohesion: 0.25
Nodes (7): Database (Drift), External Integrations, Feature Architecture, General Standards, Project Conventions, State Management (Riverpod), UI & UX

### Community 179 - "Technology Stack"
Cohesion: 0.25
Nodes (7): Configuration, Frameworks, Key Dependencies, Languages, Platform Requirements, Runtime, Technology Stack

### Community 180 - "audit_dao.dart"
Cohesion: 0.29
Nodes (6): log, queryByDateRange, queryByEntity, watchRecent, package:pos_app/core/database/tables/audit_log_table.dart, _

### Community 181 - "tables_dao.dart"
Cohesion: 0.25
Nodes (7): deleteById, getAll, getById, upsert, watchAll, package:pos_app/core/database/tables/tables_table.dart, _

### Community 182 - "usage_event.dart"
Cohesion: 0.29
Nodes (6): area, FeatureArea, label, of, UsageEvent, usageEventForRoute

### Community 183 - "appearance_section.dart"
Cohesion: 0.25
Nodes (8): themeModeProvider, AppearanceSection, build, current, _options, _showThemePicker, _ThemePickerSheet, ThemeMode

### Community 184 - "@immutable"
Cohesion: 0.33
Nodes (6): @immutable, ReviewState, ShopSizeCounts, UsageCount, UsageEnvironment, UsageSelection

### Community 185 - "dart:convert"
Cohesion: 0.33
Nodes (5): dart:convert, _cache, CountryRepository, load, static List

### Community 186 - "int get"
Cohesion: 0.33
Nodes (5): int get, billNo, displayNo, paymentLabel, String get

### Community 187 - "printer_errors.dart"
Cohesion: 0.33
Nodes (5): friendlyPrinterError, known, _match, null, raw

### Community 189 - "CLAUDE.md"
Cohesion: 0.50
Nodes (3): Database schema changes, graphify, Offline-first (non-negotiable)

### Community 190 - "app_version.dart"
Cohesion: 0.50
Nodes (3): kAppBuildNumber, kAppVersion, kAppVersionFull

### Community 193 - "support_contact_test.dart"
Cohesion: 0.25
Nodes (7): package:pos_app/features/help/support_contact.dart, main, no, opened, record, throws, yes

### Community 195 - "dart:async"
Cohesion: 0.29
Nodes (6): AppLifecycleListener?, dart:async, DatabaseExitGuard, dispose, _listener, timeout

### Community 196 - "ReceiptPrinter"
Cohesion: 0.40
Nodes (5): SppPrinter, StarBluetoothPrinter, ThermalPluginPrinter, ReceiptPrinter, FakeReceiptPrinter

### Community 197 - "review_prompter.dart"
Cohesion: 0.40
Nodes (4): kAndroidPackage, kAppStoreId, maybeRequestReview, openStoreListing

## Knowledge Gaps
- **4168 isolated node(s):** `refresh`, `router`, `getKeyboardDismissBehavior`, `_slide`, `ping` (+4163 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **4 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Return` connect `Return` to `app_database.dart`, `dart:io`, `tron_border.dart`, `snapshot_providers.dart`, `usage_counter.dart`, `usage_summary.dart`, `calc_oracle.dart`, `DataClass`, `products_provider.dart`, `unit_conversion.dart`, `app.dart`, `render_receipt.dart`, `csv_text.dart`, `receipt_printer.dart`, `printer_errors.dart`, `pos_catalog_provider.dart`, `receipt_pdf_service.dart`, `money.dart`, `receipt_roll_pdf.dart`, `restore_merge_test.dart`, `escpos_raster.dart`, `bundled_fonts.dart`, `render_receipt_image.dart`, `escpos_raster_test.dart`, `package:flutter_riverpod/flutter_riverpod.dart`, `review_policy.dart`?**
  _High betweenness centrality (0.041) - this node is a cross-community bridge._
- **Why does `AppDatabase` connect `AppDatabase` to `app_database.dart`, `package:drift/drift.dart`, `DateTime`, `screen_providers_dispose_test.dart`, `report_figures_test.dart`, `package:pos_app/features/cart/presentation/providers/cart_notifier.dart`, `package:pos_app/core/database/app_database.dart`, `usage_screen_test.dart`, `package:hive_flutter/hive_flutter.dart`, `usage_host_test.dart`, `backup_repository.dart`, `backup/share_origin_test.dart`, `receipt_tax_labels_test.dart`, `most_sold_test.dart`, `@DriftAccessor`, `shifts_dao_test.dart`, `package:flutter_test/flutter_test.dart`, `order_history.dart`, `payment_screen_test.dart`, `auto_print_test.dart`, `package:flutter_riverpod/flutter_riverpod.dart`, `migration_test.dart`?**
  _High betweenness centrality (0.015) - this node is a cross-community bridge._
- **Why does `HeldOrdersNotifier` connect `cart_notifier.dart` to `cartSessionProvider`, `ConsumerWidget`, `package:hive_flutter/hive_flutter.dart`, `held_orders_notifier.dart`?**
  _High betweenness centrality (0.011) - this node is a cross-community bridge._
- **What connects `refresh`, `router`, `getKeyboardDismissBehavior` to the rest of the system?**
  _4168 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `app_database.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.006779661016949152 - nodes in this community are weakly interconnected._
- **Should `schema_v16.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.015267175572519083 - nodes in this community are weakly interconnected._
- **Should `schema_v15.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.01818181818181818 - nodes in this community are weakly interconnected._