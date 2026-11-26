# Graph Report - agent-ad014bab3599f6896  (2026-11-26)

## Corpus Check
- 332 files · ~272,728 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 5684 nodes · 9051 edges · 187 communities (182 shown, 5 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `61bfc1fc`
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
- package:flutter_riverpod/flutter_riverpod.dart
- cart_notifier.dart
- snapshot_providers.dart
- usage_counter.dart
- package:pos_app/core/providers/database_provider.dart
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
- dart:io
- product_form_screen.dart
- products_provider.dart
- held_orders_notifier.dart
- held_tickets_bar.dart
- _grammar.dart
- backup_repository.dart
- review_controller.dart
- package:pos_app/core/theme/tokens.dart
- receipt_tax_labels_test.dart
- orders_screen.dart
- backup/share_origin_test.dart
- StatelessWidget
- restore_recovery_test.dart
- orders_dao.dart
- app.dart
- home.dart
- render_receipt.dart
- demo_data_service_test.dart
- learn_screen.dart
- app_root.dart
- csv_text.dart
- country_step.dart
- receipt_printer.dart
- Milestone 1: v1 (Foundation & Core POS)
- @DriftAccessor
- package:pos_app/core/database/app_database.dart
- settingsProvider
- shifts_dao_test.dart
- DateTimeColumn get
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
- IntColumn get
- products_dao.dart
- confirm_step.dart
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
- audit_log_table.dart
- restore_merge_test.dart
- payment_screen_test.dart
- escpos_raster.dart
- tax_settings_screen.dart
- order_taxes_table.dart
- bundled_fonts.dart
- String?
- schema.dart
- usage_providers.dart
- render_receipt_image.dart
- cart_item.dart
- audit_log_screen.dart
- databaseProvider
- dashboard_body.dart
- auto_print_test.dart
- escpos_raster_test.dart
- TextColumn get
- SettingsNotifier
- grid_product_tile.dart
- package:pos_app/core/providers/hive_provider.dart
- package:flutter/services.dart
- thermal_plugin_printer.dart
- review_policy.dart
- migration_test.dart
- sales.dart
- package:drift/drift.dart
- tax_rates_table.dart
- restore_merge_marker.dart
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
- dashboard_screen.dart
- expenses_table.dart
- app_sheet.dart
- Route /pos
- inventory_filter_bar.dart
- ConsumerState
- discount_sheet.dart
- _StoreProfileEditScreenState
- audit_service.dart
- currency_formatter.dart
- usage_screen_test.dart
- order_tax_override_table.dart
- receipt_roll_pdf_test.dart
- int?
- customers_dao.dart
- package:flutter/foundation.dart
- onboarding_state.dart
- onboarding_notifier.dart
- Return
- _
- tax_dao.dart
- store_review_prompter.dart
- percent.dart
- Projects Dependencies
- External Integrations
- package:pos_app/features/orders/domain/order_number.dart
- package:pos_app/core/utils/currency_formatter.dart
- Project Conventions
- Technology Stack
- audit_dao.dart
- tables_dao.dart
- usage_event.dart
- @immutable
- dart:convert
- int get
- printer_errors.dart
- install_macos.sh
- CLAUDE.md
- app_version.dart
- _DeflatedFile
- _FileSink
- currencies.dart

## God Nodes (most connected - your core abstractions)
1. `AppDatabase` - 51 edges
2. `databaseProvider` - 36 edges
3. `Return` - 31 edges
4. `_` - 28 edges
5. `cartSessionProvider` - 25 edges
6. `currencyFormatterProvider` - 22 edges
7. `DataClass` - 20 edges
8. `settingsProvider` - 20 edges
9. `usageCounterProvider` - 20 edges
10. `AuditService` - 19 edges

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

## Communities (187 total, 5 thin omitted)

### Community 0 - "app_database.dart"
Cohesion: 0.01
Nodes (292): class OrderTaxOverride extends, class ProductComponent extends, ColumnFilters, ColumnOrderings, backfillInvoiceNumbers, backfillV14, currentSchemaVersion, migration (+284 more)

### Community 1 - "schema_v16.dart"
Cohesion: 0.01
Nodes (148): Shifts, action, actualTableName, address, _alias, aliasedName, allSchemaEntities, allTables (+140 more)

### Community 2 - "schema_v15.dart"
Cohesion: 0.02
Nodes (127): action, actualTableName, address, _alias, aliasedName, allSchemaEntities, allTables, amount (+119 more)

### Community 3 - "schema_v14.dart"
Cohesion: 0.02
Nodes (116): action, actualTableName, address, _alias, aliasedName, allSchemaEntities, allTables, amount (+108 more)

### Community 4 - "schema_v11.dart"
Cohesion: 0.02
Nodes (113): Orders, action, actualTableName, address, _alias, aliasedName, allSchemaEntities, allTables (+105 more)

### Community 5 - "schema_v12.dart"
Cohesion: 0.02
Nodes (110): Customers, Index, StockAdjustments, action, actualTableName, address, _alias, aliasedName (+102 more)

### Community 6 - "schema_v10.dart"
Cohesion: 0.02
Nodes (110): GeneratedColumn, TaxGroupMembers, action, actualTableName, address, _alias, aliasedName, allSchemaEntities (+102 more)

### Community 7 - "schema_v13.dart"
Cohesion: 0.02
Nodes (111): OrderTaxes, OrderTaxOverrides, action, actualTableName, address, _alias, aliasedName, allSchemaEntities (+103 more)

### Community 8 - "schema_v9.dart"
Cohesion: 0.02
Nodes (109): TaxGroups, TaxRates, action, actualTableName, address, _alias, aliasedName, allSchemaEntities (+101 more)

### Community 9 - "schema_v7.dart"
Cohesion: 0.02
Nodes (104): OrderItems, Products, Returns, action, actualTableName, address, _alias, aliasedName (+96 more)

### Community 10 - "schema_v8.dart"
Cohesion: 0.02
Nodes (109): ProductModifiers, Tables, action, actualTableName, address, _alias, aliasedName, allSchemaEntities (+101 more)

### Community 11 - "schema_v4.dart"
Cohesion: 0.02
Nodes (104): AuditLog, Categories, ProductComponents, action, actualTableName, address, _alias, aliasedName (+96 more)

### Community 12 - "schema_v6.dart"
Cohesion: 0.02
Nodes (102): ExpenseCategories, Expenses, ProductTaxes, ProductVariants, action, actualTableName, address, _alias (+94 more)

### Community 13 - "snapshot_service.dart"
Cohesion: 0.02
Nodes (87): InputFileStream, _absentSuffix, add, _addDeflated, _addStored, assertNoPendingRestore, _bakSuffix, _baseName (+79 more)

### Community 14 - "hive_provider.dart"
Cohesion: 0.03
Nodes (74): autoBackupEnabled, autoBackupLastAt, _box, build, businessAddress, businessName, businessNameOrDefault, businessPan (+66 more)

### Community 15 - "Table"
Cohesion: 0.06
Nodes (68): Table, TableInfo, Categories, Customers, OrderItems, OrderTaxes, ProductComponents, ProductModifiers (+60 more)

### Community 16 - "AppDatabase"
Cohesion: 0.05
Nodes (51): _, @DriftDatabase, int tea,, AppDatabase, AuditService, transaction, voidOrder, package:pos_app/core/services/audit_service.dart (+43 more)

### Community 17 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.05
Nodes (45): CartNotifier get, db, add, _allowQty, _cart, _committed, _container, _messenger (+37 more)

### Community 18 - "cart_notifier.dart"
Cohesion: 0.04
Nodes (56): _box, formatTicketNumber, heldOrdersBoxProvider, kTicketSeqKey, next, TicketSequence, ticketSequenceProvider, CartSession (+48 more)

### Community 19 - "snapshot_providers.dart"
Cohesion: 0.06
Nodes (31): databaseFile, dir, kDatabaseFileName, openConnection, autoBackupDir, autoBackupLastError, create, createAndShare (+23 more)

### Community 20 - "usage_counter.dart"
Cohesion: 0.04
Nodes (47): bool?, after, askedVersion, _box, countingEnabled, countingOn, _counts, _defaultOpen (+39 more)

### Community 21 - "package:pos_app/core/providers/database_provider.dart"
Cohesion: 0.07
Nodes (24): build, _confirmReset, package:pos_app/core/providers/database_provider.dart, package:pos_app/features/reports/domain/report_data.dart, package:pos_app/features/reports/presentation/widgets/dashboard_body.dart, package:pos_app/features/tax/presentation/tax_settings_screen.dart, audit, c (+16 more)

### Community 22 - "package:pos_app/features/cart/presentation/providers/cart_notifier.dart"
Cohesion: 0.05
Nodes (44): customerId, customers, watch, package:pos_app/core/database/close_on_exit.dart, package:pos_app/features/cart/data/place_order.dart, package:pos_app/features/cart/data/ticket_sequence.dart, package:pos_app/features/cart/domain/cart_item.dart, package:pos_app/features/cart/presentation/providers/cart_notifier.dart (+36 more)

### Community 23 - "usage_summary.dart"
Cohesion: 0.04
Nodes (47): appInfo, appVersion, buildUsageSummary, bump, canSendUsageSummary, chars, count, currencyCode (+39 more)

### Community 24 - "calc_oracle.dart"
Cohesion: 0.04
Nodes (46): BigInt, int? discPermille,
  int, balance, base, baseOnHalfCent, bp, cents, d (+38 more)

### Community 25 - "report_data.dart"
Cohesion: 0.04
Nodes (46): avgOrder, changes, chartDates, chartHighlightIndex, chartTitle, chartTotals, costIsIncomplete, costOfGoods (+38 more)

### Community 26 - "usage_host.dart"
Cohesion: 0.05
Nodes (42): AppLifecycleListener?, dart:async, Duration, DatabaseExitGuard, dispose, _listener, timeout, onboardingCompleteProvider (+34 more)

### Community 27 - "shifts_dao.dart"
Cohesion: 0.03
Nodes (63): amount, byMethod, cash, cashRefunds, cashSales, cashTips, cashVoids, closedShifts (+55 more)

### Community 28 - "loyalty_section.dart"
Cohesion: 0.17
Nodes (14): loyaltyEarnRateProvider, loyaltyEnabledProvider, loyaltyPointValueProvider, build, createState, dispose, _earnCtrl, earnRate (+6 more)

### Community 29 - "package:hive_flutter/hive_flutter.dart"
Cohesion: 0.04
Nodes (53): Box, Directory, _box, _kFavoriteProductIds, toggle, attachUsageRouteCounter, last, onNavigate (+45 more)

### Community 30 - "DataClass"
Cohesion: 0.09
Nodes (41): Insertable, OrderNumberX, UpdateCompanion, AuditLogCompanion, AuditLogData, CategoriesCompanion, Category, Customer (+33 more)

### Community 31 - "backup_screen.dart"
Cohesion: 0.08
Nodes (34): autoBackupEnabledProvider, autoBackupLastAtProvider, backupRepositoryProvider, snapshotCoordinatorProvider, _AutoBackupTile, BackupScreen, _BackupScreenState, _BackupTile (+26 more)

### Community 32 - "receipt_screen.dart"
Cohesion: 0.09
Nodes (26): build, businessName, createState, customer, data, db, dispose, fmt (+18 more)

### Community 33 - "expenses_screen.dart"
Cohesion: 0.05
Nodes (47): _amountCtrl, build, categories, category, _CategoryChips, _categoryId, _check, _Chip (+39 more)

### Community 34 - "dart:io"
Cohesion: 0.06
Nodes (38): dart:io, countOf, currentUsageEnvironment, readShopSizeCounts, t, main, startup, fatal (+30 more)

### Community 35 - "product_form_screen.dart"
Cohesion: 0.05
Nodes (38): _categoryId, _ComponentEntry, _ComponentPickerSheet, _ComponentPickerSheetState, _components, _conversionCtrl, createState, _delete (+30 more)

### Community 36 - "products_provider.dart"
Cohesion: 0.06
Nodes (36): applyProductsFilter, categoriesStreamProvider, clearSearch, copyWith, list, mostSoldWindow, outOfStockOnly, productSalesCountProvider (+28 more)

### Community 37 - "held_orders_notifier.dart"
Cohesion: 0.08
Nodes (24): _createFullBackup, _runExport, HeldOrder, archive, archiveAll, _box, build, delete (+16 more)

### Community 38 - "held_tickets_bar.dart"
Cohesion: 0.08
Nodes (38): AnimationController, cartSessionProvider, clear, activeHeldOrdersProvider, archivedHeldOrdersProvider, heldOrdersProvider, build, _buildActiveList (+30 more)

### Community 39 - "_grammar.dart"
Cohesion: 0.18
Nodes (10): _bucket, _events, expectGrammar, fixed, i, kUsageLineGrammar, _labels, lines (+2 more)

### Community 40 - "backup_repository.dart"
Cohesion: 0.05
Nodes (43): @visibleForTesting, handleExitRequest, added, _csvEol, csvImportExplanation, CsvImportReport, customersCsv, db (+35 more)

### Community 41 - "review_controller.dart"
Cohesion: 0.06
Nodes (32): appVersion, _guard, _inFlight, onReceiptDismissed, prompter, ReviewCheck, ReviewController, settleDelay (+24 more)

### Community 42 - "package:pos_app/core/theme/tokens.dart"
Cohesion: 0.13
Nodes (13): build, icon, isDestructive, onTap, StepButton, build, emphasis, icon (+5 more)

### Community 43 - "receipt_tax_labels_test.dart"
Cohesion: 0.07
Nodes (28): dart:math, _, CartCalculator, compute, _roundingModeFor, package:pos_app/core/utils/tax_calculator.dart, package:pos_app/features/cart/domain/cart_calculator.dart, package:pos_app/features/cart/domain/cart_session.dart (+20 more)

### Community 44 - "orders_screen.dart"
Cohesion: 0.07
Nodes (33): orderHistoryProvider, _body, build, _clearQuery, createState, cs, customerName, _debounce (+25 more)

### Community 45 - "backup/share_origin_test.dart"
Cohesion: 0.06
Nodes (32): FormatException, BackupRepository, package:pos_app/features/backup/data/backup_repository.dart, package:pos_app/features/backup/data/csv_text.dart, package:pos_app/features/backup/presentation/backup_screen.dart, package:pos_app/features/receipts/presentation/receipt_pdf_service.dart, customers, db (+24 more)

### Community 46 - "StatelessWidget"
Cohesion: 0.06
Nodes (38): build, cs, key_, _KeyChip, keys, label, _SectionHeader, _ShortcutRow (+30 more)

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
Nodes (32): demoDataServiceProvider, posCatalogProvider, posFilterProvider, CartScreen, _CartScreenState, categories, _CategoryRow, _Chip (+24 more)

### Community 51 - "render_receipt.dart"
Cohesion: 0.14
Nodes (13): bytes, customerName, g, isCopy, _kv, method, methodLabel, profile (+5 more)

### Community 52 - "demo_data_service_test.dart"
Cohesion: 0.08
Nodes (23): package:pos_app/core/services/demo_data_service.dart, package:pos_app/features/review/review_providers.dart, QueryInterceptor, ../../_support/query_recorder.dart, db, expectIndexed, from, fullScan (+15 more)

### Community 53 - "learn_screen.dart"
Cohesion: 0.07
Nodes (27): ColorScheme, _Article, _ArticleCard, _articles, category, cs, description, icon (+19 more)

### Community 54 - "app_root.dart"
Cohesion: 0.05
Nodes (41): AppRoot, AppRootState, autoBackupDelay, _autoBackupRun, autoBackupScheduledForTest, _autoBackupTimer, build, child (+33 more)

### Community 55 - "csv_text.dart"
Cohesion: 0.07
Nodes (29): _bad, boolOf, cell, cellQuoted, _cells, _columns, CsvRow, CsvTable (+21 more)

### Community 56 - "country_step.dart"
Cohesion: 0.10
Nodes (18): build, BusinessNameStep, controller, build, countries, CountryStep, loading, onSearch (+10 more)

### Community 57 - "receipt_printer.dart"
Cohesion: 0.07
Nodes (28): address, data, devices, DiscoveredPrinter, driver, escPosPrinterProvider, fmt, fromKey (+20 more)

### Community 58 - "Milestone 1: v1 (Foundation & Core POS)"
Cohesion: 0.07
Nodes (26): 1. State Management (Riverpod), 2. Navigation (GoRouter), 3. Data Layer (Drift & Hive), 4. Hardware Integration, Core Pillars, Data Flow, Directory Structure, Overview (+18 more)

### Community 59 - "@DriftAccessor"
Cohesion: 0.14
Nodes (20): @DriftAccessor, _$AuditDaoMixin, _$CustomersDaoMixin, DatabaseAccessor, _$ExpensesDaoMixin, _$InventoryDaoMixin, AuditDao, CustomersDao (+12 more)

### Community 60 - "package:pos_app/core/database/app_database.dart"
Cohesion: 0.08
Nodes (19): components, cost, invoicePrefix, placeOrder, roundMoney, transaction, _unitCostNow, isLowStock (+11 more)

### Community 61 - "settingsProvider"
Cohesion: 0.10
Nodes (27): defaultTaxIdProvider, invoicePrefixProvider, settingsProvider, themeModeProvider, build, reset, skip, _selectDevice (+19 more)

### Community 62 - "shifts_dao_test.dart"
Cohesion: 0.17
Nodes (11): package:pos_app/core/database/daos/shifts_dao.dart, at, close, dao, day, db, main, order (+3 more)

### Community 63 - "DateTimeColumn get"
Cohesion: 0.11
Nodes (17): @DataClassName, DateTimeColumn get, Categories, createdAt, id, name, parentId, sortOrder (+9 more)

### Community 64 - "sell_screen_rebuild_test.dart"
Cohesion: 0.08
Nodes (25): AppBar, CustomPaint, FilterChip, GridView, build, ListView, MaterialPageRoute, NavigatorState (+17 more)

### Community 65 - "package:flutter/material.dart"
Cohesion: 0.07
Nodes (25): EditableText, build, SettingsSectionHeader, title, build, ThemePreviewScreen, build, child (+17 more)

### Community 66 - "settings_screen.dart"
Cohesion: 0.15
Nodes (12): build, SettingsScreen, package:pos_app/features/settings/presentation/widgets/appearance_section.dart, package:pos_app/features/settings/presentation/widgets/backup_section.dart, package:pos_app/features/settings/presentation/widgets/currency_section.dart, package:pos_app/features/settings/presentation/widgets/danger_section.dart, package:pos_app/features/settings/presentation/widgets/inventory_section.dart, package:pos_app/features/settings/presentation/widgets/loyalty_section.dart (+4 more)

### Community 67 - "pos_catalog_provider.dart"
Cohesion: 0.08
Nodes (24): AsyncValue, buildPosSearchIndex, cart, catalogEmpty, categoryId, committedMainUnits, favorites, favoritesOnly (+16 more)

### Community 68 - "product_tile.dart"
Cohesion: 0.15
Nodes (12): bg, color, cs, icon, onDecrement, onIncrement, onTap, product (+4 more)

### Community 69 - "customer_card.dart"
Cohesion: 0.11
Nodes (16): Color, _Badge, bg, customer, CustomerCard, fg, icon, label (+8 more)

### Community 70 - "order_detail_screen.dart"
Cohesion: 0.08
Nodes (24): auditServiceProvider, businessName, customer, data, db, _DetailBody, _DetailData, fmt (+16 more)

### Community 71 - "orders_table.dart"
Cohesion: 0.08
Nodes (25): changeAmount, createdAt, customerId, discountIsPercent, discountTotal, discountValue, id, invoiceNo (+17 more)

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
Nodes (21): File, package:sqlite3/sqlite3.dart, backupOf, dbFileIn, entriesOf, hasProduct, hivePathIn, _indexOf (+13 more)

### Community 76 - "money.dart"
Cohesion: 0.09
Nodes (22): allowZero, byLoss, cents, eps, exact, isRequired, kMaxMoneyAmount, kMaxMoneyAmountLabel (+14 more)

### Community 77 - "payment_screen.dart"
Cohesion: 0.05
Nodes (61): ConsumerWidget, currencyCodeProvider, currencySymbolProvider, cartMainUnitQtyProvider, build, CartDetailScreen, _ClearCartButton, _ListSeparator (+53 more)

### Community 78 - "onboarding_screen.dart"
Cohesion: 0.08
Nodes (29): onboardingNotifierProvider, _back, build, _businessNameCtrl, _canProceed, _countries, createState, dispose (+21 more)

### Community 79 - "products_screen.dart"
Cohesion: 0.09
Nodes (22): categories, _CategoryChips, categoryName, _Chip, createState, cs, dispose, fmt (+14 more)

### Community 80 - "pos_filter_provider.dart"
Cohesion: 0.12
Nodes (16): clearSearch, copyWith, favoritesOnly, isGrid, PosFilterNotifier, PosFilterState, PosSortMode, search (+8 more)

### Community 81 - "customers_screen.dart"
Cohesion: 0.12
Nodes (18): IconData get, build, createState, CustomersScreen, _CustomersScreenState, dispose, _filterAndSort, icon (+10 more)

### Community 82 - "IntColumn get"
Cohesion: 0.10
Nodes (19): IntColumn get, componentProductId, compositeProductId, id, ProductComponents, quantity, primaryKey, productId (+11 more)

### Community 83 - "products_dao.dart"
Cohesion: 0.09
Nodes (21): deductStock, deleteCategory, getAllCategories, getById, getBySku, getComponents, replaceComponents, restock (+13 more)

### Community 84 - "confirm_step.dart"
Cohesion: 0.12
Nodes (13): build, children, ConfirmStep, icon, isLast, label, state, _SummaryCard (+5 more)

### Community 85 - "tables_screen.dart"
Cohesion: 0.10
Nodes (21): _assignToCart, _capacityCtrl, createState, dispose, existing, initState, isCurrentCartTable, isOccupied (+13 more)

### Community 86 - "held_order.dart"
Cohesion: 0.10
Nodes (20): archivedAt, copyWith, createdAt, customerId, customerName, fromJson, id, isArchived (+12 more)

### Community 87 - "receipt_body.dart"
Cohesion: 0.10
Nodes (20): _BillRow, build, businessName, customer, data, _DataCell, fmt, _HeaderCell (+12 more)

### Community 88 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.09
Nodes (19): left, processReturn, refundableAmount, refunded, transaction, package:flutter_test/flutter_test.dart, package:pos_app/core/utils/money.dart, package:pos_app/features/products/domain/unit_conversion.dart (+11 more)

### Community 89 - "snapshot_service_test.dart"
Cohesion: 0.10
Nodes (19): ../../drift/generated/schema.dart, package:archive/archive.dart, craftZip, dbFileIn, expectLiveUntouched, expectRejected, hivePathIn, live (+11 more)

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
Cohesion: 0.09
Nodes (20): CurrencyFormatter, addColor, cs, fmt, label, onTap, ref, _showTaxPicker (+12 more)

### Community 95 - "inventory_card.dart"
Cohesion: 0.10
Nodes (19): _apply, badgeColor, build, canDecrement, canIncrement, cs, _decrement, icon (+11 more)

### Community 96 - "order_history.dart"
Cohesion: 0.11
Nodes (19): _changes, copyWith, _db, dispose, error, _generation, hasMore, isLoading (+11 more)

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
Nodes (17): _addressCtrl, build, createState, customer, CustomerForm, _CustomerFormState, _discountCtrl, _discountIsPercent (+9 more)

### Community 101 - "star_printer.dart"
Cohesion: 0.13
Nodes (14): _devices, _discovery, dispose, _events, _found, _isSupported, _methods, _printImages (+6 more)

### Community 102 - "receipt_roll_pdf.dart"
Cohesion: 0.11
Nodes (18): base, body, bold, buildReceiptRollPdf, buildTestPageRollPdf, dateFmt, doc, font (+10 more)

### Community 103 - "audit_log_table.dart"
Cohesion: 0.20
Nodes (9): action, AuditLog, createdAt, entityId, entityType, id, metadata, newValue (+1 more)

### Community 104 - "restore_merge_test.dart"
Cohesion: 0.11
Nodes (18): backupOf, dbFileIn, hivePathIn, installedLive, installedOld, live, liveState, main (+10 more)

### Community 105 - "payment_screen_test.dart"
Cohesion: 0.11
Nodes (17): Completer, package:pos_app/core/providers/audit_service_provider.dart, package:pos_app/features/cart/presentation/payment_screen.dart, app, c, confirm, db, gate (+9 more)

### Community 106 - "escpos_raster.dart"
Cohesion: 0.11
Nodes (17): dart:isolate, Future, bytes, cached, canvas, escPosProfile, escPosRasterBytes, escPosRasterBytesSync (+9 more)

### Community 107 - "tax_settings_screen.dart"
Cohesion: 0.12
Nodes (17): FormState, createState, dispose, existing, _formKey, _inclusionType, _nameCtrl, onAdd (+9 more)

### Community 108 - "order_taxes_table.dart"
Cohesion: 0.08
Nodes (24): @TableIndex, Expenses, OrderItems, id, isInclusive, orderId, OrderTaxes, taxableAmount (+16 more)

### Community 109 - "bundled_fonts.dart"
Cohesion: 0.18
Nodes (10): bundledFontData, bundledPdfFont, cached, _fontData, future, jetBrainsMonoBold, jetBrainsMonoItalic, jetBrainsMonoRegular (+2 more)

### Community 110 - "String?"
Cohesion: 0.06
Nodes (32): double?, IconData?, ArticleDetailScreen, ArticleSection, build, category, cs, heading (+24 more)

### Community 111 - "schema.dart"
Cohesion: 0.11
Nodes (17): package:drift/internal/migrations.dart, schema_v10.dart, schema_v11.dart, schema_v12.dart, schema_v13.dart, schema_v14.dart, schema_v15.dart, schema_v16.dart (+9 more)

### Community 112 - "usage_providers.dart"
Cohesion: 0.06
Nodes (38): dart:ui, ShareFiles, shareFilesProvider, shareFilesWithOs, _removeOldSummaryFile, build, _confirmReset, _counter (+30 more)

### Community 113 - "render_receipt_image.dart"
Cohesion: 0.17
Nodes (11): doc, escPosPrintWidthDots, isCopy, kReceiptDpi, pages, _rasterise, renderReceiptImages, renderTestPageImages (+3 more)

### Community 114 - "cart_item.dart"
Cohesion: 0.12
Nodes (16): copyWith, grossAmount, isSecondaryUnit, isTaxable, lineDiscount, lineSubtotal, mainUnitQty, name (+8 more)

### Community 115 - "audit_log_screen.dart"
Cohesion: 0.20
Nodes (11): action, _ActionChip, _actionColor, _actionIcon, AuditLogScreen, auditLogsProvider, build, color (+3 more)

### Community 116 - "databaseProvider"
Cohesion: 0.15
Nodes (16): databaseProvider, settingsBoxProvider, _delete, _delete, _showAddCategoryDialog, OnboardingState, finish, OnboardingNotifier (+8 more)

### Community 117 - "dashboard_body.dart"
Cohesion: 0.12
Nodes (16): ReportData, build, _buildKpiRows, cs, DashboardBody, data, _fmt, isCustomRange (+8 more)

### Community 118 - "auto_print_test.dart"
Cohesion: 0.12
Nodes (16): Object?, package:pos_app/features/printing/domain/auto_print.dart, box, db, devices, failWith, main, makeContainer (+8 more)

### Community 119 - "escpos_raster_test.dart"
Cohesion: 0.11
Nodes (16): dart:typed_data, package:image/image.dart, package:pos_app/core/utils/bundled_fonts.dart, package:pos_app/features/printing/domain/escpos_raster.dart, StateError, main, _blockPage, _countSequence (+8 more)

### Community 120 - "TextColumn get"
Cohesion: 0.10
Nodes (19): BoolColumn get, color, ExpenseCategories, id, isDefault, name, amount, createdAt (+11 more)

### Community 122 - "grid_product_tile.dart"
Cohesion: 0.17
Nodes (10): product, package:pos_app/features/cart/domain/pos_catalog_provider.dart, package:pos_app/features/cart/domain/pos_filter_provider.dart, package:pos_app/features/inventory/presentation/inventory_screen.dart, package:pos_app/features/products/domain/favorites_provider.dart, package:pos_app/shared/widgets/step_button.dart, ids, main (+2 more)

### Community 123 - "package:pos_app/core/providers/hive_provider.dart"
Cohesion: 0.04
Nodes (49): bool get, _db, DemoDataService, seed, _seedDatabase, _settings, maybeRequestReview, NoopReviewPrompter (+41 more)

### Community 124 - "package:flutter/services.dart"
Cohesion: 0.09
Nodes (20): AndroidSdk, _cached, _methods, _read, sdkInt, _devices, dispose, _methods (+12 more)

### Community 125 - "thermal_plugin_printer.dart"
Cohesion: 0.10
Nodes (20): SppPrinter, StarBluetoothPrinter, _connect, _connectTimeout, devices, _disconnect, _ftp, _pluginDevice (+12 more)

### Community 126 - "review_policy.dart"
Cohesion: 0.12
Nodes (15): at, first, firstLaunchAt, kMinDaysBetweenAnyPrompts, kReviewMinCompletedSales, kReviewMinDaysBetweenPrompts, kReviewMinDaysSinceInstall, last (+7 more)

### Community 127 - "migration_test.dart"
Cohesion: 0.10
Nodes (19): generated/schema.dart, package:drift_dev/api/migrations_common.dart, package:drift_dev/api/migrations_native.dart, package:drift/native.dart, SchemaVerifier, allIndexes, customStatement, _CutAfter (+11 more)

### Community 128 - "sales.dart"
Cohesion: 0.13
Nodes (14): int? customerId,
  int, line, loyaltyDiscount, paymentMethod, placeOrder, points, pointsRedeemed, pointsToEarn (+6 more)

### Community 129 - "package:drift/drift.dart"
Cohesion: 0.11
Nodes (16): getAdjustmentsForOrder, getAdjustmentsForProduct, logAdjustment, watchLowStock, package:drift/drift.dart, package:pos_app/core/database/tables/products_table.dart, package:pos_app/core/database/tables/stock_adjustments_table.dart, db (+8 more)

### Community 130 - "tax_rates_table.dart"
Cohesion: 0.18
Nodes (10): createdAt, id, inclusionType, isActive, isCompound, name, rate, roundingMode (+2 more)

### Community 131 - "restore_merge_marker.dart"
Cohesion: 0.13
Nodes (14): counts, d, deleteRestoreMergeMarker, finishPendingRestoreMerge, kRestoreMergeMarkerName, _markerFile, null, path (+6 more)

### Community 132 - "VoidCallback?"
Cohesion: 0.09
Nodes (20): CartItem, CartLineItem, fmt, icon, item, onPressed, _QtyButton, build (+12 more)

### Community 133 - "v1 Roadmap — Flutter Offline-First POS"
Cohesion: 0.13
Nodes (14): Architecture Decisions, Deferred to v2, Drift Schema — Full Table List (v1), Phase 0 — Foundation (No UI yet), Phase 1 — First-Run & Onboarding, Phase 2 — Product & Inventory Core, Phase 3 — Core Sales Loop, Phase 4 — Receipts & Hardware (+6 more)

### Community 134 - "cart_session.dart"
Cohesion: 0.15
Nodes (12): copyWith, customerId, fresh, heldTicketId, isEditingHeldTicket, loyaltyPointsToRedeem, openedAt, orderDiscount (+4 more)

### Community 135 - "_PrinterSetupScreenState"
Cohesion: 0.18
Nodes (17): printerDeviceAddressProvider, printerDeviceNameProvider, printerDriverProvider, printerPaperWidthProvider, build, _orderDetailProvider, OrderDetailScreen, printerForDriverProvider (+9 more)

### Community 136 - "store_profile_edit_screen.dart"
Cohesion: 0.15
Nodes (12): class, _addressCtrl, build, createState, dispose, _initialised, _label, _loading (+4 more)

### Community 137 - "DateTime"
Cohesion: 0.21
Nodes (11): DateTime, package:csv/csv.dart, bytesOf, db, legacyAllOrdersWithItems, legacyOrdersCsv, legacySalesReportCsv, main (+3 more)

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

### Community 145 - "dashboard_screen.dart"
Cohesion: 0.15
Nodes (14): DateTimeRange?, ReportPeriod, ReportPeriodX, reportProvider, build, createState, _customRange, DashboardScreen (+6 more)

### Community 146 - "expenses_table.dart"
Cohesion: 0.17
Nodes (11): amount, categoryId, createdAt, date, id, isRecurring, isTaxDeductible, notes (+3 more)

### Community 147 - "app_sheet.dart"
Cohesion: 0.17
Nodes (10): cs, failurePrefix, messenger, draggable, initialSize, minSize, package:pos_app/shared/widgets/keyboard_safe.dart, required WidgetBuilder builder,
  bool (+2 more)

### Community 148 - "Route /pos"
Cohesion: 0.40
Nodes (5): build, _finish, _skip, build, Route /pos

### Community 149 - "inventory_filter_bar.dart"
Cohesion: 0.17
Nodes (11): build, _Chip, color, InventoryFilterBar, label, lowCount, onSelect, onTap (+3 more)

### Community 150 - "ConsumerState"
Cohesion: 0.06
Nodes (37): ConsumerState, ConsumerStatefulWidget, Iterable, lowStockThresholdProvider, PaymentScreen, _fitsStock, _HeldTicketsSheet, build (+29 more)

### Community 151 - "discount_sheet.dart"
Cohesion: 0.18
Nodes (10): double get, build, createState, _ctrl, currentDiscount, dispose, initState, isPercent (+2 more)

### Community 152 - "_StoreProfileEditScreenState"
Cohesion: 0.42
Nodes (10): businessAddressProvider, businessNameProvider, businessPanProvider, businessPhoneProvider, businessTaglineProvider, didChangeDependencies, _StoreProfileEditScreenState, build (+2 more)

### Community 153 - "audit_service.dart"
Cohesion: 0.25
Nodes (7): _db, log, orderPlaced, orderRefunded, orderVoided, settingChanged, taxOverridden

### Community 154 - "currency_formatter.dart"
Cohesion: 0.20
Nodes (9): decimalDigits, _fmt, format, formatPlain, locale, _plainFmt, symbol, tryParse (+1 more)

### Community 155 - "usage_screen_test.dart"
Cohesion: 0.06
Nodes (34): ButtonStyleButton, _grammar.dart, bounds, box, fromLTWH, resolveShareOrigin, screen, shareOriginFor (+26 more)

### Community 156 - "order_tax_override_table.dart"
Cohesion: 0.22
Nodes (8): createdAt, id, orderId, OrderTaxOverrides, originalTax, overrideTax, reason, RealColumn get

### Community 157 - "receipt_roll_pdf_test.dart"
Cohesion: 0.18
Nodes (10): package:pdf/pdf.dart, package:pos_app/features/printing/domain/receipt_roll_pdf.dart, package:pos_app/features/printing/domain/render_receipt_image.dart, doc, fmt, main, order, _pageFormats (+2 more)

### Community 158 - "int?"
Cohesion: 0.14
Nodes (16): int?, build, createState, CustomerPickerSheet, _CustomerPickerSheetState, customers, onSelect, _search (+8 more)

### Community 159 - "customers_dao.dart"
Cohesion: 0.20
Nodes (9): addLoyaltyPoints, getAll, getById, redeemLoyaltyPoints, search, upsert, watchAll, package:pos_app/core/database/tables/customers_table.dart (+1 more)

### Community 161 - "package:flutter/foundation.dart"
Cohesion: 0.11
Nodes (16): restartNoticeShowing, apple, _encode, _lineBreak, mailtoLink, query, smsLink, target (+8 more)

### Community 162 - "onboarding_state.dart"
Cohesion: 0.11
Nodes (17): code, CountryDefault, currency, fromJson, name, symbol, taxName, taxRate (+9 more)

### Community 163 - "onboarding_notifier.dart"
Cohesion: 0.20
Nodes (9): back, build, next, setBusinessName, setCountry, setSaving, setTaxName, setTaxRate (+1 more)

### Community 165 - "Return"
Cohesion: 0.12
Nodes (14): initials, name, null, stockCapFor, isValidConversionRate, kMaxConversionRate, kMinConversionRate, null (+6 more)

### Community 167 - "_"
Cohesion: 0.33
Nodes (7): _, compoundTax, invoiceTax, lineItemTax, priceBeforeTax, _round, TaxCalculator

### Community 168 - "tax_dao.dart"
Cohesion: 0.22
Nodes (8): getAll, getById, getRatesForProduct, setProductTaxes, upsertRate, watchActive, package:pos_app/core/database/tables/product_taxes_table.dart, _

### Community 169 - "store_review_prompter.dart"
Cohesion: 0.14
Nodes (12): _kAndroidListingUrl, maybeRequestReview, openStoreListing, _review, package:in_app_review/in_app_review.dart, package:url_launcher/url_launcher.dart, InAppReview, instance (+4 more)

### Community 170 - "percent.dart"
Cohesion: 0.22
Nodes (8): formatPercent, formatPercentNumber, formatRateForEdit, formatRatePercent, kPercentDecimals, kPercentInputPattern, text, RegExp

### Community 172 - "Projects Dependencies"
Cohesion: 0.22
Nodes (8): Dev Dependencies, [Hardware] flutter_thermal_printer, Major Dependencies, Outdated / Deprecated Dependencies, Overview, [Persistence] drift, Projects Dependencies, [State Management] flutter_riverpod

### Community 173 - "External Integrations"
Cohesion: 0.22
Nodes (8): APIs & External Services, Authentication & Identity, CI/CD & Deployment, Data Storage, Environment Configuration, External Integrations, Monitoring & Observability, Webhooks & Callbacks

### Community 175 - "package:pos_app/features/orders/domain/order_number.dart"
Cohesion: 0.25
Nodes (7): addBack, customerId, items, label, restockOrderItems, reverseLoyalty, package:pos_app/features/orders/domain/order_number.dart

### Community 177 - "package:pos_app/core/utils/currency_formatter.dart"
Cohesion: 0.09
Nodes (20): AutoPrintService, printOrder, _ref, buildReceiptText, dateFmt, join, lines, o (+12 more)

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

## Knowledge Gaps
- **4159 isolated node(s):** `refresh`, `router`, `getKeyboardDismissBehavior`, `_slide`, `ping` (+4154 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **5 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Return` connect `Return` to `app_database.dart`, `restore_merge_marker.dart`, `tron_border.dart`, `package:flutter_riverpod/flutter_riverpod.dart`, `usage_counter.dart`, `usage_summary.dart`, `calc_oracle.dart`, `DataClass`, `products_provider.dart`, `review_controller.dart`, `percent.dart`, `app.dart`, `render_receipt.dart`, `csv_text.dart`, `receipt_printer.dart`, `printer_errors.dart`, `pos_catalog_provider.dart`, `receipt_pdf_service.dart`, `money.dart`, `receipt_roll_pdf.dart`, `escpos_raster.dart`, `bundled_fonts.dart`, `usage_providers.dart`, `render_receipt_image.dart`, `escpos_raster_test.dart`, `review_policy.dart`?**
  _High betweenness centrality (0.041) - this node is a cross-community bridge._
- **Why does `AppDatabase` connect `AppDatabase` to `app_database.dart`, `package:drift/drift.dart`, `DateTime`, `package:flutter_riverpod/flutter_riverpod.dart`, `package:pos_app/core/providers/database_provider.dart`, `package:pos_app/features/cart/presentation/providers/cart_notifier.dart`, `audit_service.dart`, `usage_screen_test.dart`, `package:hive_flutter/hive_flutter.dart`, `backup_repository.dart`, `receipt_tax_labels_test.dart`, `backup/share_origin_test.dart`, `demo_data_service_test.dart`, `@DriftAccessor`, `shifts_dao_test.dart`, `package:flutter_test/flutter_test.dart`, `order_history.dart`, `payment_screen_test.dart`, `auto_print_test.dart`, `package:pos_app/core/providers/hive_provider.dart`, `migration_test.dart`?**
  _High betweenness centrality (0.012) - this node is a cross-community bridge._
- **Why does `CountryDefault` connect `onboarding_state.dart` to `country_step.dart`?**
  _High betweenness centrality (0.011) - this node is a cross-community bridge._
- **What connects `refresh`, `router`, `getKeyboardDismissBehavior` to the rest of the system?**
  _4159 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `app_database.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.006825938566552901 - nodes in this community are weakly interconnected._
- **Should `schema_v16.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.013422818791946308 - nodes in this community are weakly interconnected._
- **Should `schema_v15.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.015625 - nodes in this community are weakly interconnected._