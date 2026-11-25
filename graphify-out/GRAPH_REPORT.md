# Graph Report - agent-a56494ea87981aeba  (2026-11-26)

## Corpus Check
- 340 files · ~267,534 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 5607 nodes · 9106 edges · 193 communities (188 shown, 5 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `56af4932`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- app_database.dart
- schema_v15.dart
- schema_v11.dart
- schema_v14.dart
- schema_v10.dart
- schema_v12.dart
- schema_v13.dart
- schema_v9.dart
- schema_v8.dart
- schema_v7.dart
- schema_v4.dart
- schema_v6.dart
- snapshot_service.dart
- hive_provider.dart
- AppDatabase
- Table
- usage_ask_test.dart
- usage_screen_test.dart
- package:pos_app/core/providers/hive_provider.dart
- usage_counter.dart
- report_data.dart
- cart_notifier.dart
- usage_summary.dart
- dart:io
- usage_host.dart
- calc_oracle.dart
- held_tickets_bar.dart
- package:drift/drift.dart
- settingsProvider
- expenses_screen.dart
- package:pos_app/features/cart/domain/cart_item.dart
- product_tile.dart
- ConsumerWidget
- sell_screen_rebuild_test.dart
- DataClass
- package:pos_app/core/database/app_database.dart
- package:flutter/material.dart
- product_form_screen.dart
- ConsumerState
- app_root.dart
- databaseProvider
- backup_repository.dart
- dashboard_body.dart
- feature_flags.dart
- orders_screen.dart
- backup_screen.dart
- products_screen.dart
- tables_dao.dart
- backup/share_origin_test.dart
- tax_settings_screen.dart
- snapshot_providers.dart
- onboarding_screen.dart
- printer_setup_screen.dart
- restore_recovery_test.dart
- orders_dao.dart
- gates_test.dart
- app.dart
- package:pos_app/core/utils/currency_formatter.dart
- features_screen_test.dart
- products_dao.dart
- csv_text.dart
- StatelessWidget
- receipt_printer.dart
- Milestone 1: v1 (Foundation & Core POS)
- home.dart
- package:flutter_test/flutter_test.dart
- build
- usage_constants.dart
- pos_catalog_provider.dart
- String?
- orders_screen_test.dart
- order_detail_screen.dart
- receipt_pdf_service.dart
- dashboard_screen.dart
- snapshot_photos_test.dart
- orders_table.dart
- money.dart
- payment_screen.dart
- receipt_screen.dart
- usage_host_test.dart
- IntColumn get
- tables_screen.dart
- products_table.dart
- held_order.dart
- inventory_card.dart
- products_provider.dart
- receipt_body.dart
- usage_providers.dart
- place_order.dart
- app_theme.dart
- _
- cart_summary.dart
- support_contact.dart
- order_history.dart
- Open POS
- customers_screen.dart
- tokens.dart
- audit_log_screen.dart
- customer_picker_sheet.dart
- customer_form.dart
- features_step.dart
- receipt_roll_pdf.dart
- snapshot_service_test.dart
- restore_merge_test.dart
- payment_screen_test.dart
- escpos_raster.dart
- onboarding_notifier.dart
- package:pos_app/core/providers/database_provider.dart
- article_detail_screen.dart
- learn_screen.dart
- confirm_step.dart
- package:flutter/services.dart
- render_receipt_image.dart
- inventory_screen.dart
- returns_table.dart
- Return
- cart_item.dart
- pos_filter_provider.dart
- order_summary.dart
- auto_print_test.dart
- schema.dart
- escpos_raster_test.dart
- side_nav.dart
- List
- onboarding_state.dart
- spp_printer.dart
- thermal_plugin_printer.dart
- review_policy.dart
- stock_adjustments_table.dart
- store_profile_edit_screen.dart
- loyalty_section.dart
- package:flutter/foundation.dart
- cart_line_item.dart
- restore_merge_marker.dart
- star_printer.dart
- v1 Roadmap — Flutter Offline-First POS
- TextColumn get
- pos_cart_actions.dart
- DateTime
- migration_test.dart
- customers_table.dart
- tron_border.dart
- discount_sheet.dart
- expenses_dao.dart
- order_items_table.dart
- _PrinterSetupScreenState
- cart_session.dart
- GeneratedDatabase
- expenses_table.dart
- app_sheet.dart
- settings_screen.dart
- _grammar.dart
- tax_rates_table.dart
- package:intl/intl.dart
- share_origin.dart
- receipt_roll_pdf_test.dart
- onboarding_test.dart
- report_figures_test.dart
- DateTimeColumn get
- customers_dao.dart
- _StoreProfileEditScreenState
- link_uris.dart
- country_default.dart
- unit_conversion.dart
- @immutable
- dismiss_keyboard_test.dart
- audit_log_table.dart
- categories_table.dart
- order_taxes_table.dart
- appearance_section.dart
- percent.dart
- wizard_nav_bar.dart
- Projects Dependencies
- External Integrations
- @visibleForTesting
- audit_service.dart
- package:pos_app/features/orders/domain/order_number.dart
- support_contact_test.dart
- Project Conventions
- Technology Stack
- _
- usage_event.dart
- dart:convert
- int get
- install_macos.sh
- review_policy_test.dart
- _ExpensesScreenState
- CLAUDE.md
- app_version.dart
- _DeflatedFile
- _FileSink
- currencies.dart
- @rebuzzpos

## God Nodes (most connected - your core abstractions)
1. `AppDatabase` - 50 edges
2. `featureOnProvider` - 41 edges
3. `databaseProvider` - 36 edges
4. `Return` - 33 edges
5. `_` - 28 edges
6. `settingsProvider` - 27 edges
7. `cartSessionProvider` - 26 edges
8. `currencyFormatterProvider` - 22 edges
9. `usageCounterProvider` - 20 edges
10. `DataClass` - 19 edges

## Surprising Connections (you probably didn't know these)
- `_GatedAudit` --inherits--> `AuditService`  [EXTRACTED]
  test/features/cart/payment_screen_test.dart → lib/core/services/audit_service.dart
- `_FixedSessionNotifier` --inherits--> `CartSessionNotifier`  [EXTRACTED]
  test/features/tables/occupied_tables_test.dart → lib/features/cart/presentation/providers/cart_notifier.dart
- `FakeReceiptPrinter` --implements--> `ReceiptPrinter`  [EXTRACTED]
  test/features/printing/auto_print_test.dart → lib/features/printing/domain/receipt_printer.dart
- `_FakePrompter` --implements--> `ReviewPrompter`  [EXTRACTED]
  test/features/review/review_controller_test.dart → lib/features/review/domain/review_prompter.dart
- `_Prompter` --implements--> `ReviewPrompter`  [EXTRACTED]
  test/features/usage/usage_ask_test.dart → lib/features/review/domain/review_prompter.dart

## Import Cycles
- None detected.

## Communities (193 total, 5 thin omitted)

### Community 0 - "app_database.dart"
Cohesion: 0.01
Nodes (259): class OrderTaxOverride extends, class ProductComponent extends, ColumnFilters, ColumnOrderings, backfillInvoiceNumbers, backfillV14, currentSchemaVersion, migration (+251 more)

### Community 1 - "schema_v15.dart"
Cohesion: 0.02
Nodes (127): action, actualTableName, address, _alias, aliasedName, allSchemaEntities, allTables, amount (+119 more)

### Community 2 - "schema_v11.dart"
Cohesion: 0.02
Nodes (114): ProductModifiers, action, actualTableName, address, _alias, aliasedName, allSchemaEntities, allTables (+106 more)

### Community 3 - "schema_v14.dart"
Cohesion: 0.02
Nodes (114): TaxGroups, action, actualTableName, address, _alias, aliasedName, allSchemaEntities, allTables (+106 more)

### Community 4 - "schema_v10.dart"
Cohesion: 0.02
Nodes (113): TaxGroupMembers, action, actualTableName, address, _alias, aliasedName, allSchemaEntities, allTables (+105 more)

### Community 5 - "schema_v12.dart"
Cohesion: 0.02
Nodes (112): Index, OrderTaxes, action, actualTableName, address, _alias, aliasedName, allSchemaEntities (+104 more)

### Community 6 - "schema_v13.dart"
Cohesion: 0.02
Nodes (111): Customers, OrderTaxOverrides, action, actualTableName, address, _alias, aliasedName, allSchemaEntities (+103 more)

### Community 7 - "schema_v9.dart"
Cohesion: 0.02
Nodes (108): GeneratedColumn, Products, action, actualTableName, address, _alias, aliasedName, allSchemaEntities (+100 more)

### Community 8 - "schema_v8.dart"
Cohesion: 0.02
Nodes (107): OrderItems, TaxRates, action, actualTableName, address, _alias, aliasedName, allSchemaEntities (+99 more)

### Community 9 - "schema_v7.dart"
Cohesion: 0.02
Nodes (105): ProductComponents, StockAdjustments, Tables, action, actualTableName, address, _alias, aliasedName (+97 more)

### Community 10 - "schema_v4.dart"
Cohesion: 0.02
Nodes (104): AuditLog, Categories, Orders, action, actualTableName, address, _alias, aliasedName (+96 more)

### Community 11 - "schema_v6.dart"
Cohesion: 0.02
Nodes (100): ExpenseCategories, Expenses, ProductTaxes, ProductVariants, Returns, action, actualTableName, address (+92 more)

### Community 12 - "snapshot_service.dart"
Cohesion: 0.02
Nodes (87): InputFileStream, _absentSuffix, add, _addDeflated, _addStored, assertNoPendingRestore, _bakSuffix, _baseName (+79 more)

### Community 13 - "hive_provider.dart"
Cohesion: 0.02
Nodes (86): autoBackupEnabled, autoBackupLastAt, _box, build, businessAddress, businessName, businessNameOrDefault, businessPan (+78 more)

### Community 14 - "AppDatabase"
Cohesion: 0.05
Nodes (60): _, @DriftDatabase, AppDatabase, AuditService, transaction, voidOrder, package:pos_app/core/services/audit_service.dart, package:pos_app/features/returns/domain/process_return.dart (+52 more)

### Community 15 - "Table"
Cohesion: 0.06
Nodes (68): Table, TableInfo, Orders, OrderTaxes, ProductComponents, Returns, Tables, TaxRates (+60 more)

### Community 16 - "usage_ask_test.dart"
Cohesion: 0.04
Nodes (51): bool get, appVersion, _guard, _inFlight, onReceiptDismissed, prompter, ReviewCheck, ReviewController (+43 more)

### Community 17 - "usage_screen_test.dart"
Cohesion: 0.04
Nodes (53): BusinessType? get, ButtonStyleButton, CheckboxListTile, _grammar.dart, UsageCounter, _businessType, _confirmReset, _counter (+45 more)

### Community 18 - "package:pos_app/core/providers/hive_provider.dart"
Cohesion: 0.04
Nodes (49): Box, Directory, _box, _kFavoriteProductIds, toggle, _box, _date, ensureFirstLaunch (+41 more)

### Community 19 - "usage_counter.dart"
Cohesion: 0.04
Nodes (54): bool?, DateTime? get, after, askedVersion, _box, countingEnabled, countingOn, _counts (+46 more)

### Community 20 - "report_data.dart"
Cohesion: 0.04
Nodes (53): all, avgOrder, changes, chartDates, chartHighlightIndex, chartTitle, chartTotals, costIsIncomplete (+45 more)

### Community 21 - "cart_notifier.dart"
Cohesion: 0.05
Nodes (51): ticketSequenceProvider, CartSession, addItem, addProduct, addProductInSecondaryUnit, CartNotifier, CartSessionNotifier, cartSessionProvider (+43 more)

### Community 22 - "usage_summary.dart"
Cohesion: 0.04
Nodes (49): appInfo, appVersion, buildUsageSummary, bump, businessType, canSendUsageSummary, chars, count (+41 more)

### Community 23 - "dart:io"
Cohesion: 0.06
Nodes (40): dart:io, databaseFile, dir, kDatabaseFileName, openConnection, countOf, currentUsageEnvironment, readShopSizeCounts (+32 more)

### Community 24 - "usage_host.dart"
Cohesion: 0.05
Nodes (43): AppLifecycleListener?, dart:async, Duration, DatabaseExitGuard, dispose, handleExitRequest, _listener, timeout (+35 more)

### Community 25 - "calc_oracle.dart"
Cohesion: 0.04
Nodes (46): BigInt, int? discPermille,
  int, balance, base, baseOnHalfCent, bp, cents, d (+38 more)

### Community 26 - "held_tickets_bar.dart"
Cohesion: 0.06
Nodes (42): AnimationController, _box, formatTicketNumber, heldOrdersBoxProvider, kTicketSeqKey, next, HeldOrder, activeHeldOrdersProvider (+34 more)

### Community 27 - "package:drift/drift.dart"
Cohesion: 0.05
Nodes (38): int tea,, package:drift/drift.dart, package:pos_app/core/services/demo_data_service.dart, package:pos_app/features/review/review_providers.dart, QueryInterceptor, ../../_support/query_recorder.dart, db, expectIndexed (+30 more)

### Community 28 - "settingsProvider"
Cohesion: 0.07
Nodes (42): autoBackupEnabledProvider, autoBackupLastAtProvider, featureFlagsProvider, featuresIntroSeenProvider, settingsBoxProvider, SettingsNotifier, settingsProvider, stockOffSinceProvider (+34 more)

### Community 29 - "expenses_screen.dart"
Cohesion: 0.05
Nodes (42): _amountCtrl, categories, category, _CategoryChips, _categoryId, _check, _Chip, color (+34 more)

### Community 30 - "package:pos_app/features/cart/domain/cart_item.dart"
Cohesion: 0.05
Nodes (37): int? customerId,
  int, package:pos_app/features/cart/data/place_order.dart, package:pos_app/features/cart/domain/cart_item.dart, package:pos_app/features/printing/domain/render_receipt.dart, package:pos_app/features/receipts/domain/receipt_text.dart, audit, db, main (+29 more)

### Community 31 - "product_tile.dart"
Cohesion: 0.05
Nodes (37): Color, bg, color, cs, icon, onDecrement, onIncrement, onTap (+29 more)

### Community 32 - "ConsumerWidget"
Cohesion: 0.10
Nodes (40): ConsumerWidget, featureOnProvider, cartMainUnitQtyProvider, build, CartDetailScreen, _ClearCartButton, _ListSeparator, PosBottomBars (+32 more)

### Community 33 - "sell_screen_rebuild_test.dart"
Cohesion: 0.06
Nodes (36): AppBar, CustomPaint, FilterChip, GridView, product, ListView, NavigatorState, package:pos_app/features/cart/domain/pos_catalog_provider.dart (+28 more)

### Community 34 - "DataClass"
Cohesion: 0.09
Nodes (39): Insertable, OrderNumberX, UpdateCompanion, AuditLogCompanion, AuditLogData, CategoriesCompanion, Category, Customer (+31 more)

### Community 35 - "package:pos_app/core/database/app_database.dart"
Cohesion: 0.07
Nodes (30): db, customerId, customers, watch, isLowStock, activeHeld, cartTableId, tableId (+22 more)

### Community 36 - "package:flutter/material.dart"
Cohesion: 0.06
Nodes (31): build, BusinessNameStep, controller, build, countries, CountryStep, loading, onSearch (+23 more)

### Community 37 - "product_form_screen.dart"
Cohesion: 0.06
Nodes (37): _categoryId, _ComponentEntry, _ComponentPickerSheet, _ComponentPickerSheetState, _components, _conversionCtrl, createState, _delete (+29 more)

### Community 38 - "ConsumerState"
Cohesion: 0.07
Nodes (36): ConsumerState, ConsumerStatefulWidget, businessTypeNameProvider, lowStockThresholdProvider, onboardingCompleteProvider, shareFilesProvider, BackupScreen, CartScreen (+28 more)

### Community 39 - "app_root.dart"
Cohesion: 0.06
Nodes (36): AppRoot, AppRootState, autoBackupDelay, _autoBackupRun, autoBackupScheduledForTest, _autoBackupTimer, build, child (+28 more)

### Community 40 - "databaseProvider"
Cohesion: 0.08
Nodes (35): auditServiceProvider, databaseProvider, invoicePrefixProvider, _PaymentScreenState, _placeOrder, _delete, _save, _showAddCategoryDialog (+27 more)

### Community 41 - "backup_repository.dart"
Cohesion: 0.06
Nodes (35): added, _csvEol, csvImportExplanation, CsvImportReport, db, exportCustomers, exportExpenses, exportOrders (+27 more)

### Community 42 - "dashboard_body.dart"
Cohesion: 0.06
Nodes (32): ColorScheme, ReportData, build, _buildKpiRows, cs, DashboardBody, data, _fmt (+24 more)

### Community 43 - "feature_flags.dart"
Cohesion: 0.06
Nodes (34): autoPrint, bundles, costProfit, csvImportExport, customers, dashboardExtras, defaultOn, defaults (+26 more)

### Community 44 - "orders_screen.dart"
Cohesion: 0.06
Nodes (34): orderHistoryProvider, _body, _clearQuery, createState, cs, customerName, _debounce, dispose (+26 more)

### Community 45 - "backup_screen.dart"
Cohesion: 0.06
Nodes (32): _BackupTile, _buildInfoCard, color, _confirmAndImport, _createFullBackup, createState, cs, files (+24 more)

### Community 46 - "products_screen.dart"
Cohesion: 0.06
Nodes (31): categories, _CategoryChips, categoryName, _Chip, createState, cs, dispose, fmt (+23 more)

### Community 47 - "tables_dao.dart"
Cohesion: 0.07
Nodes (31): @DriftAccessor, _$AuditDaoMixin, _$CustomersDaoMixin, DatabaseAccessor, _$ExpensesDaoMixin, _$InventoryDaoMixin, AuditDao, log (+23 more)

### Community 48 - "backup/share_origin_test.dart"
Cohesion: 0.06
Nodes (30): FormatException, package:pos_app/features/backup/data/backup_repository.dart, package:pos_app/features/backup/data/csv_text.dart, package:pos_app/features/backup/presentation/backup_screen.dart, package:pos_app/features/receipts/presentation/receipt_pdf_service.dart, customers, db, main (+22 more)

### Community 49 - "tax_settings_screen.dart"
Cohesion: 0.07
Nodes (31): FormState, int?, defaultTaxIdProvider, build, reset, taxRatesStreamProvider, build, currentId (+23 more)

### Community 50 - "snapshot_providers.dart"
Cohesion: 0.06
Nodes (31): autoBackupDir, autoBackupLastError, create, createAndShare, defaultHiveBoxPaths, docs, inspect, kAutoBackupInterval (+23 more)

### Community 51 - "onboarding_screen.dart"
Cohesion: 0.08
Nodes (32): build, onboardingNotifierProvider, _back, build, _businessNameCtrl, _countries, createState, dispose (+24 more)

### Community 52 - "printer_setup_screen.dart"
Cohesion: 0.07
Nodes (30): PrinterDriver, lastSdkNeedingLocationForBle, permissionsForScan, scanNeedsLocation, createState, _devices, _devicesSub, _disconnectSavedPrinter (+22 more)

### Community 53 - "restore_recovery_test.dart"
Cohesion: 0.07
Nodes (31): Exception, FileSystemException, RestoreJournalFormatException, PendingRestoreException, RestoreFatalException, RestoreRolledBackException, SnapshotFormatException, backupOf (+23 more)

### Community 54 - "orders_dao.dart"
Cohesion: 0.06
Nodes (31): completedOrderCount, _escapeLike, getById, getItems, getTaxBreakdown, hasRestockedReturn, historyPage, incrementPrintCount (+23 more)

### Community 55 - "gates_test.dart"
Cohesion: 0.07
Nodes (28): package:pos_app/core/theme/app_theme.dart, package:pos_app/features/cart/presentation/home.dart, package:pos_app/features/cart/presentation/widgets/cart_line_item.dart, package:pos_app/features/cart/presentation/widgets/grid_product_tile.dart, package:pos_app/features/cart/presentation/widgets/order_summary.dart, package:pos_app/features/cart/presentation/widgets/ticket_header.dart, package:pos_app/features/products/domain/products_provider.dart, package:pos_app/features/products/presentation/product_form_screen.dart (+20 more)

### Community 56 - "app.dart"
Cohesion: 0.07
Nodes (30): ChangeNotifier, GoRouter, appRedirect, AppScrollBehavior, featureRedirect, flags, getKeyboardDismissBehavior, location (+22 more)

### Community 57 - "package:pos_app/core/utils/currency_formatter.dart"
Cohesion: 0.07
Nodes (28): bytes, customerName, g, isCopy, _kv, method, methodLabel, profile (+20 more)

### Community 58 - "features_screen_test.dart"
Cohesion: 0.07
Nodes (27): dart:math, _, CartCalculator, compute, _roundingModeFor, package:pos_app/core/utils/tax_calculator.dart, package:pos_app/features/cart/domain/cart_calculator.dart, package:pos_app/features/cart/domain/cart_session.dart (+19 more)

### Community 59 - "products_dao.dart"
Cohesion: 0.07
Nodes (28): deductStock, deleteCategory, getAllCategories, getById, getBySku, getComponents, replaceComponents, restock (+20 more)

### Community 60 - "csv_text.dart"
Cohesion: 0.07
Nodes (29): _bad, boolOf, cell, cellQuoted, _cells, _columns, CsvRow, CsvTable (+21 more)

### Community 61 - "StatelessWidget"
Cohesion: 0.08
Nodes (28): build, cs, key_, _KeyChip, keys, label, _SectionHeader, _ShortcutRow (+20 more)

### Community 62 - "receipt_printer.dart"
Cohesion: 0.07
Nodes (28): address, data, devices, DiscoveredPrinter, driver, escPosPrinterProvider, fmt, fromKey (+20 more)

### Community 63 - "Milestone 1: v1 (Foundation & Core POS)"
Cohesion: 0.07
Nodes (26): 1. State Management (Riverpod), 2. Navigation (GoRouter), 3. Data Layer (Drift & Hive), 4. Hardware Integration, Core Pillars, Data Flow, Directory Structure, Overview (+18 more)

### Community 64 - "home.dart"
Cohesion: 0.08
Nodes (27): demoDataServiceProvider, categories, _CategoryRow, _Chip, createState, dispose, _EmptyProductsState, _EmptyProductsStateState (+19 more)

### Community 65 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.08
Nodes (22): left, processReturn, refundableAmount, refunded, transaction, package:flutter_test/flutter_test.dart, package:pos_app/core/utils/money.dart, package:pos_app/features/products/domain/stock_level.dart (+14 more)

### Community 66 - "build"
Cohesion: 0.10
Nodes (26): build, posCatalogProvider, posFilterProvider, build, _ProductArea, build, build, build (+18 more)

### Community 67 - "usage_constants.dart"
Cohesion: 0.08
Nodes (25): kFeedbackAreaQuestion, kFeedbackAskAction, kFeedbackAskText, kFeedbackInstruction, kFeedbackMessageMaxLength, kFeedbackSupportRowSubtitle, kFeedbackSupportRowTitle, kOfflineFirstLine (+17 more)

### Community 68 - "pos_catalog_provider.dart"
Cohesion: 0.08
Nodes (24): AsyncValue, buildPosSearchIndex, cart, catalogEmpty, categoryId, committedMainUnits, favorites, favoritesOnly (+16 more)

### Community 69 - "String?"
Cohesion: 0.08
Nodes (22): double?, IconData?, action, AppEmptyState, build, icon, subtitle, title (+14 more)

### Community 70 - "orders_screen_test.dart"
Cohesion: 0.08
Nodes (22): package:pos_app/features/audit/presentation/audit_log_screen.dart, package:pos_app/features/expenses/presentation/expenses_screen.dart, package:pos_app/features/orders/domain/order_history.dart, package:pos_app/features/orders/presentation/orders_screen.dart, ProviderContainer, add, c, cart (+14 more)

### Community 71 - "order_detail_screen.dart"
Cohesion: 0.09
Nodes (23): build, businessName, customer, data, db, _DetailData, fmt, isPartlyRefunded (+15 more)

### Community 72 - "receipt_pdf_service.dart"
Cohesion: 0.08
Nodes (23): baseStyle, billRow, boldStyle, buildReceiptPdf, bytes, customerName, _dataCell, dateFmt (+15 more)

### Community 73 - "dashboard_screen.dart"
Cohesion: 0.11
Nodes (21): DateTimeRange?, currencyCodeProvider, currencySymbolProvider, reportProvider, reportSectionsProvider, build, createState, _customRange (+13 more)

### Community 74 - "snapshot_photos_test.dart"
Cohesion: 0.09
Nodes (21): File, package:sqlite3/sqlite3.dart, backupOf, dbFileIn, entriesOf, hasProduct, hivePathIn, _indexOf (+13 more)

### Community 75 - "orders_table.dart"
Cohesion: 0.09
Nodes (22): changeAmount, createdAt, customerId, discountIsPercent, discountTotal, discountValue, id, invoiceNo (+14 more)

### Community 76 - "money.dart"
Cohesion: 0.09
Nodes (22): allowZero, byLoss, cents, eps, exact, isRequired, kMaxMoneyAmount, kMaxMoneyAmountLabel (+14 more)

### Community 77 - "payment_screen.dart"
Cohesion: 0.09
Nodes (22): createState, customer, dispose, endsWith, fmt, icon, initState, label (+14 more)

### Community 78 - "receipt_screen.dart"
Cohesion: 0.09
Nodes (22): build, businessName, createState, customer, data, db, dispose, fmt (+14 more)

### Community 79 - "usage_host_test.dart"
Cohesion: 0.09
Nodes (20): main, startup, ListTile, package:flutter/gestures.dart, package:pos_app/app_root.dart, package:pos_app/core/restart_notice.dart, package:pos_app/features/help/presentation/support_screen.dart, package:pos_app/features/usage/presentation/usage_host.dart (+12 more)

### Community 80 - "IntColumn get"
Cohesion: 0.10
Nodes (19): IntColumn get, componentProductId, compositeProductId, id, ProductComponents, quantity, primaryKey, productId (+11 more)

### Community 81 - "tables_screen.dart"
Cohesion: 0.10
Nodes (21): _assignToCart, _capacityCtrl, createState, dispose, existing, initState, isCurrentCartTable, isOccupied (+13 more)

### Community 82 - "products_table.dart"
Cohesion: 0.10
Nodes (20): categoryId, conversionRate, createdAt, id, imagePath, isActive, isComposite, isHiddenInPos (+12 more)

### Community 83 - "held_order.dart"
Cohesion: 0.10
Nodes (20): archivedAt, copyWith, createdAt, customerId, customerName, fromJson, id, isArchived (+12 more)

### Community 84 - "inventory_card.dart"
Cohesion: 0.10
Nodes (20): _apply, badgeColor, build, canDecrement, canIncrement, cs, _decrement, icon (+12 more)

### Community 85 - "products_provider.dart"
Cohesion: 0.10
Nodes (20): applyProductsFilter, clearSearch, copyWith, list, mostSoldWindow, outOfStockOnly, productSalesCountProvider, ProductsFilterNotifier (+12 more)

### Community 86 - "receipt_body.dart"
Cohesion: 0.10
Nodes (20): _BillRow, build, businessName, customer, data, _DataCell, fmt, _HeaderCell (+12 more)

### Community 87 - "usage_providers.dart"
Cohesion: 0.11
Nodes (18): dart:ui, ShareFiles, shareFilesWithOs, c, f, launch, link, LinkLauncher (+10 more)

### Community 88 - "place_order.dart"
Cohesion: 0.09
Nodes (17): getAdjustmentsForProduct, logAdjustment, watchLowStock, components, cost, invoicePrefix, placeOrder, roundMoney (+9 more)

### Community 89 - "app_theme.dart"
Cohesion: 0.10
Nodes (19): AppTheme, backgroundGradient, _build, ctaButtonStyle, _dark, _darkGrad, _darkScheme, _fontFamily (+11 more)

### Community 90 - "_"
Cohesion: 0.11
Nodes (20): _, _abs, bak, begin, cleanup, committed, markCommitted, message (+12 more)

### Community 91 - "cart_summary.dart"
Cohesion: 0.10
Nodes (19): amount, CartSummary, isInclusive, loyaltyDiscount, maxRedeemablePoints, name, orderDiscount, pointsRedeemed (+11 more)

### Community 92 - "support_contact.dart"
Cohesion: 0.09
Nodes (18): canLaunch, kLinkFailureMessageDuration, _kSupportWhatsAppDigits, kSupportWhatsAppDisplay, kSupportWhatsAppUnavailable, launch, messenger, native (+10 more)

### Community 93 - "order_history.dart"
Cohesion: 0.11
Nodes (19): _changes, copyWith, _db, dispose, error, _generation, hasMore, isLoading (+11 more)

### Community 94 - "Open POS"
Cohesion: 0.10
Nodes (19): Build from source, Contributing, Customers, Features, Get Open POS, License, macOS, Money and reports (+11 more)

### Community 95 - "customers_screen.dart"
Cohesion: 0.12
Nodes (18): IconData get, build, createState, CustomersScreen, _CustomersScreenState, dispose, _filterAndSort, icon (+10 more)

### Community 96 - "tokens.dart"
Cohesion: 0.11
Nodes (18): AppFonts, AppOpacity, heavy, lg, md, medium, mono, Radii (+10 more)

### Community 97 - "audit_log_screen.dart"
Cohesion: 0.12
Nodes (17): action, _ActionChip, _actionColor, _actionIcon, AuditLogScreen, auditLogsProvider, build, color (+9 more)

### Community 98 - "customer_picker_sheet.dart"
Cohesion: 0.11
Nodes (17): build, createState, CustomerPickerSheet, _CustomerPickerSheetState, customers, onSelect, _search, selectedId (+9 more)

### Community 99 - "customer_form.dart"
Cohesion: 0.11
Nodes (18): _addressCtrl, build, createState, customer, CustomerForm, _CustomerFormState, _delete, _discountCtrl (+10 more)

### Community 100 - "features_step.dart"
Cohesion: 0.11
Nodes (17): _app, kPresets, label, parseBusinessType, presetSwitches, usageLabel, build, FeaturesStep (+9 more)

### Community 101 - "receipt_roll_pdf.dart"
Cohesion: 0.11
Nodes (18): base, body, bold, buildReceiptRollPdf, buildTestPageRollPdf, dateFmt, doc, font (+10 more)

### Community 102 - "snapshot_service_test.dart"
Cohesion: 0.11
Nodes (18): package:archive/archive.dart, craftZip, dbFileIn, expectLiveUntouched, expectRejected, hivePathIn, live, main (+10 more)

### Community 103 - "restore_merge_test.dart"
Cohesion: 0.11
Nodes (18): backupOf, dbFileIn, hivePathIn, installedLive, installedOld, live, liveState, main (+10 more)

### Community 104 - "payment_screen_test.dart"
Cohesion: 0.11
Nodes (17): Completer, package:pos_app/core/providers/audit_service_provider.dart, package:pos_app/features/cart/presentation/payment_screen.dart, app, c, confirm, db, gate (+9 more)

### Community 105 - "escpos_raster.dart"
Cohesion: 0.11
Nodes (17): dart:isolate, Future, bytes, cached, canvas, escPosProfile, escPosRasterBytes, escPosRasterBytesSync (+9 more)

### Community 106 - "onboarding_notifier.dart"
Cohesion: 0.11
Nodes (17): FeatureFlags get, back, build, _defaults, next, _passed, _saveFeatures, setBusinessName (+9 more)

### Community 107 - "package:pos_app/core/providers/database_provider.dart"
Cohesion: 0.11
Nodes (15): _db, DemoDataService, seed, _seedDatabase, _settings, build, _confirmReset, package:pos_app/core/providers/database_provider.dart (+7 more)

### Community 108 - "article_detail_screen.dart"
Cohesion: 0.11
Nodes (17): ArticleDetailScreen, ArticleSection, build, category, cs, heading, icon, readTime (+9 more)

### Community 109 - "learn_screen.dart"
Cohesion: 0.11
Nodes (17): _Article, _ArticleCard, _articles, build, category, cs, description, icon (+9 more)

### Community 110 - "confirm_step.dart"
Cohesion: 0.11
Nodes (15): OnboardingState, build, children, ConfirmStep, icon, isLast, label, state (+7 more)

### Community 111 - "package:flutter/services.dart"
Cohesion: 0.11
Nodes (15): AndroidSdk, _cached, _methods, _read, sdkInt, friendlyPrinterError, known, _match (+7 more)

### Community 112 - "render_receipt_image.dart"
Cohesion: 0.12
Nodes (15): dart:typed_data, doc, escPosPrintWidthDots, isCopy, kReceiptDpi, pages, _rasterise, renderReceiptImages (+7 more)

### Community 113 - "inventory_screen.dart"
Cohesion: 0.12
Nodes (16): Iterable, createState, dispose, _filter, _filtered, filterInventoryProducts, InventoryScreen, _InventoryScreenState (+8 more)

### Community 114 - "returns_table.dart"
Cohesion: 0.12
Nodes (15): createdAt, id, orderId, OrderTaxOverrides, originalTax, overrideTax, reason, amount (+7 more)

### Community 115 - "Return"
Cohesion: 0.12
Nodes (14): bundledFontData, bundledPdfFont, cached, _fontData, future, jetBrainsMonoBold, jetBrainsMonoItalic, jetBrainsMonoRegular (+6 more)

### Community 116 - "cart_item.dart"
Cohesion: 0.12
Nodes (16): copyWith, grossAmount, isSecondaryUnit, isTaxable, lineDiscount, lineSubtotal, mainUnitQty, name (+8 more)

### Community 117 - "pos_filter_provider.dart"
Cohesion: 0.12
Nodes (16): clearSearch, copyWith, favoritesOnly, isGrid, PosFilterNotifier, PosFilterState, PosSortMode, search (+8 more)

### Community 118 - "order_summary.dart"
Cohesion: 0.12
Nodes (16): addColor, cs, fmt, label, onTap, ref, _showDiscountSheet, _showTaxPicker (+8 more)

### Community 119 - "auto_print_test.dart"
Cohesion: 0.12
Nodes (16): Object?, package:pos_app/features/printing/domain/auto_print.dart, box, db, devices, failWith, main, makeContainer (+8 more)

### Community 120 - "schema.dart"
Cohesion: 0.12
Nodes (16): package:drift/internal/migrations.dart, schema_v10.dart, schema_v11.dart, schema_v12.dart, schema_v13.dart, schema_v14.dart, schema_v15.dart, schema_v4.dart (+8 more)

### Community 121 - "escpos_raster_test.dart"
Cohesion: 0.12
Nodes (15): package:image/image.dart, package:pos_app/core/utils/bundled_fonts.dart, package:pos_app/features/printing/domain/escpos_raster.dart, StateError, main, _blockPage, _countSequence, _firstRaster (+7 more)

### Community 122 - "side_nav.dart"
Cohesion: 0.12
Nodes (15): Feature, f, feature, featureForLocation, featureRedirect, group, icon, kFeaturesIntroText (+7 more)

### Community 123 - "List"
Cohesion: 0.12
Nodes (14): TicketSequence, build, labels, onSkip, step, WizardHeader, List, build (+6 more)

### Community 124 - "onboarding_state.dart"
Cohesion: 0.12
Nodes (15): businessName, businessType, copyWith, country, current, isLast, kOnboardingSteps, label (+7 more)

### Community 125 - "spp_printer.dart"
Cohesion: 0.12
Nodes (15): _devices, dispose, _methods, _print, printReceipt, printTestPage, _requireAndroid, SppPrinter (+7 more)

### Community 126 - "thermal_plugin_printer.dart"
Cohesion: 0.12
Nodes (15): _connect, _connectTimeout, devices, _disconnect, _ftp, _pluginDevice, _printPages, printReceipt (+7 more)

### Community 127 - "review_policy.dart"
Cohesion: 0.12
Nodes (15): at, first, firstLaunchAt, kMinDaysBetweenAnyPrompts, kReviewMinCompletedSales, kReviewMinDaysBetweenPrompts, kReviewMinDaysSinceInstall, last (+7 more)

### Community 128 - "stock_adjustments_table.dart"
Cohesion: 0.13
Nodes (14): @TableIndex, AuditLog, Expenses, OrderItems, OrderTaxes, Orders, Returns, createdAt (+6 more)

### Community 129 - "store_profile_edit_screen.dart"
Cohesion: 0.13
Nodes (14): class, _addressCtrl, build, createState, dispose, _initialised, _label, _loading (+6 more)

### Community 130 - "loyalty_section.dart"
Cohesion: 0.17
Nodes (14): loyaltyEarnRateProvider, loyaltyEnabledProvider, loyaltyPointValueProvider, build, createState, dispose, _earnCtrl, earnRate (+6 more)

### Community 131 - "package:flutter/foundation.dart"
Cohesion: 0.13
Nodes (12): restartNoticeShowing, attachUsageRouteCounter, last, onNavigate, topRouteOf, package:flutter/foundation.dart, package:pos_app/core/utils/link_uris.dart, package:pos_app/features/usage/data/usage_counter.dart (+4 more)

### Community 132 - "cart_line_item.dart"
Cohesion: 0.13
Nodes (13): CurrencyFormatter, CartItem, build, fmt, icon, item, onPressed, _QtyButton (+5 more)

### Community 133 - "restore_merge_marker.dart"
Cohesion: 0.13
Nodes (14): counts, d, deleteRestoreMergeMarker, finishPendingRestoreMerge, kRestoreMergeMarkerName, _markerFile, null, path (+6 more)

### Community 134 - "star_printer.dart"
Cohesion: 0.13
Nodes (14): _devices, _discovery, dispose, _events, _found, _isSupported, _methods, _printImages (+6 more)

### Community 135 - "v1 Roadmap — Flutter Offline-First POS"
Cohesion: 0.13
Nodes (14): Architecture Decisions, Deferred to v2, Drift Schema — Full Table List (v1), Phase 0 — Foundation (No UI yet), Phase 1 — First-Run & Onboarding, Phase 2 — Product & Inventory Core, Phase 3 — Core Sales Loop, Phase 4 — Receipts & Hardware (+6 more)

### Community 136 - "TextColumn get"
Cohesion: 0.15
Nodes (12): BoolColumn get, color, ExpenseCategories, id, isDefault, name, createdAt, id (+4 more)

### Community 137 - "pos_cart_actions.dart"
Cohesion: 0.14
Nodes (13): CartNotifier get, add, _allowQty, _cart, _committed, _container, _messenger, pickUnit (+5 more)

### Community 138 - "DateTime"
Cohesion: 0.18
Nodes (13): DateTime, BackupRepository, package:csv/csv.dart, bytesOf, db, legacyAllOrdersWithItems, legacyOrdersCsv, legacySalesReportCsv (+5 more)

### Community 139 - "migration_test.dart"
Cohesion: 0.14
Nodes (12): generated/schema.dart, package:drift_dev/api/migrations_common.dart, package:drift_dev/api/migrations_native.dart, package:drift/native.dart, SchemaVerifier, indexes, main, seedV13 (+4 more)

### Community 140 - "customers_table.dart"
Cohesion: 0.14
Nodes (13): address, createdAt, Customers, defaultDiscount, defaultDiscountIsPercent, email, id, isTaxExempt (+5 more)

### Community 141 - "tron_border.dart"
Cohesion: 0.15
Nodes (12): CustomPainter, color, e, extractWrappedPath, f, len, p, paint (+4 more)

### Community 142 - "discount_sheet.dart"
Cohesion: 0.17
Nodes (12): double get, build, createState, _ctrl, currentDiscount, DiscountSheet, _DiscountSheetState, dispose (+4 more)

### Community 143 - "expenses_dao.dart"
Cohesion: 0.15
Nodes (12): getAll, getAllCategories, insert, insertCategory, totalForPeriod, updateExpense, upsertCategory, watchAll (+4 more)

### Community 144 - "order_items_table.dart"
Cohesion: 0.15
Nodes (12): discount, id, lineTotal, orderId, productId, productName, quantity, taxAmount (+4 more)

### Community 145 - "_PrinterSetupScreenState"
Cohesion: 0.27
Nodes (12): printerDeviceAddressProvider, printerDeviceNameProvider, printerDriverProvider, printerPaperWidthProvider, printerForDriverProvider, receiptPrinterProvider, build, _PrinterSetupScreenState (+4 more)

### Community 146 - "cart_session.dart"
Cohesion: 0.15
Nodes (12): copyWith, customerId, fresh, heldTicketId, isEditingHeldTicket, loyaltyPointsToRedeem, openedAt, orderDiscount (+4 more)

### Community 147 - "GeneratedDatabase"
Cohesion: 0.17
Nodes (12): GeneratedDatabase, DatabaseAtV10, DatabaseAtV11, DatabaseAtV12, DatabaseAtV13, DatabaseAtV14, DatabaseAtV15, DatabaseAtV4 (+4 more)

### Community 148 - "expenses_table.dart"
Cohesion: 0.17
Nodes (11): amount, categoryId, createdAt, date, id, isRecurring, isTaxDeductible, notes (+3 more)

### Community 149 - "app_sheet.dart"
Cohesion: 0.17
Nodes (10): cs, failurePrefix, messenger, draggable, initialSize, minSize, package:pos_app/shared/widgets/keyboard_safe.dart, required WidgetBuilder builder,
  bool (+2 more)

### Community 150 - "settings_screen.dart"
Cohesion: 0.17
Nodes (11): build, package:pos_app/features/settings/presentation/widgets/appearance_section.dart, package:pos_app/features/settings/presentation/widgets/backup_section.dart, package:pos_app/features/settings/presentation/widgets/currency_section.dart, package:pos_app/features/settings/presentation/widgets/danger_section.dart, package:pos_app/features/settings/presentation/widgets/inventory_section.dart, package:pos_app/features/settings/presentation/widgets/loyalty_section.dart, package:pos_app/features/settings/presentation/widgets/printer_section.dart (+3 more)

### Community 151 - "_grammar.dart"
Cohesion: 0.17
Nodes (11): _bucket, _businessTypes, _events, expectGrammar, fixed, i, kUsageLineGrammar, _labels (+3 more)

### Community 152 - "tax_rates_table.dart"
Cohesion: 0.18
Nodes (10): createdAt, id, inclusionType, isActive, isCompound, name, rate, roundingMode (+2 more)

### Community 153 - "package:intl/intl.dart"
Cohesion: 0.18
Nodes (10): decimalDigits, _fmt, format, formatPlain, locale, _plainFmt, symbol, tryParse (+2 more)

### Community 154 - "share_origin.dart"
Cohesion: 0.18
Nodes (10): bounds, box, fromLTWH, resolveShareOrigin, screen, shareOriginFor, view, widgetRect (+2 more)

### Community 155 - "receipt_roll_pdf_test.dart"
Cohesion: 0.18
Nodes (10): package:pdf/pdf.dart, package:pos_app/features/printing/domain/receipt_roll_pdf.dart, package:pos_app/features/printing/domain/render_receipt_image.dart, doc, fmt, main, order, _pageFormats (+2 more)

### Community 156 - "onboarding_test.dart"
Cohesion: 0.18
Nodes (10): package:pos_app/features/onboarding/presentation/onboarding_notifier.dart, package:pos_app/features/onboarding/presentation/onboarding_screen.dart, package:pos_app/features/onboarding/presentation/widgets/features_step.dart, ScaffoldState, box, container, db, kOnboardingCompleteKeyForTest (+2 more)

### Community 157 - "report_figures_test.dart"
Cohesion: 0.18
Nodes (10): audit, c, db, expense, item, main, place, product (+2 more)

### Community 158 - "DateTimeColumn get"
Cohesion: 0.20
Nodes (9): @DataClassName, DateTimeColumn get, capacity, createdAt, id, name, notes, Tables (+1 more)

### Community 159 - "customers_dao.dart"
Cohesion: 0.20
Nodes (9): addLoyaltyPoints, getAll, getById, redeemLoyaltyPoints, search, upsert, watchAll, package:pos_app/core/database/tables/customers_table.dart (+1 more)

### Community 160 - "_StoreProfileEditScreenState"
Cohesion: 0.42
Nodes (10): businessAddressProvider, businessNameProvider, businessPanProvider, businessPhoneProvider, businessTaglineProvider, didChangeDependencies, _StoreProfileEditScreenState, build (+2 more)

### Community 161 - "link_uris.dart"
Cohesion: 0.20
Nodes (9): apple, _encode, _lineBreak, mailtoLink, query, smsLink, target, to (+1 more)

### Community 162 - "country_default.dart"
Cohesion: 0.20
Nodes (9): code, CountryDefault, currency, fromJson, name, symbol, taxName, taxRate (+1 more)

### Community 163 - "unit_conversion.dart"
Cohesion: 0.20
Nodes (9): isValidConversionRate, kMaxConversionRate, kMinConversionRate, null, parseConversionRate, text, toInt, validateConversionRate (+1 more)

### Community 164 - "@immutable"
Cohesion: 0.22
Nodes (9): @immutable, FeatureFlags, AppSettings, ReportSections, ReviewState, ShopSizeCounts, UsageCount, UsageEnvironment (+1 more)

### Community 165 - "dismiss_keyboard_test.dart"
Cohesion: 0.22
Nodes (7): EditableText, package:pos_app/app.dart, package:pos_app/shared/widgets/dismiss_keyboard.dart, harness, main, main, textFieldHasFocus

### Community 166 - "audit_log_table.dart"
Cohesion: 0.22
Nodes (8): action, createdAt, entityId, entityType, id, metadata, newValue, oldValue

### Community 167 - "categories_table.dart"
Cohesion: 0.22
Nodes (8): Categories, createdAt, id, name, parentId, sortOrder, taxRateId, updatedAt

### Community 168 - "order_taxes_table.dart"
Cohesion: 0.22
Nodes (8): id, isInclusive, orderId, taxableAmount, taxAmount, taxRateId, taxRateName, taxRatePercent

### Community 169 - "appearance_section.dart"
Cohesion: 0.25
Nodes (8): themeModeProvider, AppearanceSection, build, current, _options, _showThemePicker, _ThemePickerSheet, ThemeMode

### Community 170 - "percent.dart"
Cohesion: 0.22
Nodes (8): formatPercent, formatPercentNumber, formatRateForEdit, formatRatePercent, kPercentDecimals, kPercentInputPattern, text, RegExp

### Community 171 - "wizard_nav_bar.dart"
Cohesion: 0.22
Nodes (8): build, canNext, isLast, onBack, OnboardingNavBar, onNext, saving, step

### Community 172 - "Projects Dependencies"
Cohesion: 0.22
Nodes (8): Dev Dependencies, [Hardware] flutter_thermal_printer, Major Dependencies, Outdated / Deprecated Dependencies, Overview, [Persistence] drift, Projects Dependencies, [State Management] flutter_riverpod

### Community 173 - "External Integrations"
Cohesion: 0.22
Nodes (8): APIs & External Services, Authentication & Identity, CI/CD & Deployment, Data Storage, Environment Configuration, External Integrations, Monitoring & Observability, Webhooks & Callbacks

### Community 174 - "@visibleForTesting"
Cohesion: 0.25
Nodes (8): @visibleForTesting, customersCsv, expensesCsv, productsCsv, writeOrdersCsv, writeSalesReportCsv, exactAmountText, runCheck

### Community 175 - "audit_service.dart"
Cohesion: 0.25
Nodes (7): _db, log, orderPlaced, orderRefunded, orderVoided, settingChanged, taxOverridden

### Community 176 - "package:pos_app/features/orders/domain/order_number.dart"
Cohesion: 0.25
Nodes (7): addBack, customerId, items, label, restockOrderItems, reverseLoyalty, package:pos_app/features/orders/domain/order_number.dart

### Community 177 - "support_contact_test.dart"
Cohesion: 0.25
Nodes (7): package:pos_app/features/help/support_contact.dart, main, no, opened, record, throws, yes

### Community 178 - "Project Conventions"
Cohesion: 0.25
Nodes (7): Database (Drift), External Integrations, Feature Architecture, General Standards, Project Conventions, State Management (Riverpod), UI & UX

### Community 179 - "Technology Stack"
Cohesion: 0.25
Nodes (7): Configuration, Frameworks, Key Dependencies, Languages, Platform Requirements, Runtime, Technology Stack

### Community 180 - "_"
Cohesion: 0.33
Nodes (7): _, compoundTax, invoiceTax, lineItemTax, priceBeforeTax, _round, TaxCalculator

### Community 181 - "usage_event.dart"
Cohesion: 0.29
Nodes (6): area, FeatureArea, label, of, UsageEvent, usageEventForRoute

### Community 182 - "dart:convert"
Cohesion: 0.33
Nodes (5): dart:convert, _cache, CountryRepository, load, static List

### Community 183 - "int get"
Cohesion: 0.33
Nodes (5): int get, billNo, displayNo, paymentLabel, String get

### Community 185 - "review_policy_test.dart"
Cohesion: 0.33
Nodes (5): decide, main, now, passing, v

### Community 186 - "_ExpensesScreenState"
Cohesion: 0.50
Nodes (5): build, expenseCategoriesStreamProvider, ExpensesScreen, _ExpensesScreenState, expensesStreamProvider

### Community 187 - "CLAUDE.md"
Cohesion: 0.50
Nodes (3): Database schema changes, graphify, Offline-first (non-negotiable)

### Community 188 - "app_version.dart"
Cohesion: 0.50
Nodes (3): kAppBuildNumber, kAppVersion, kAppVersionFull

## Knowledge Gaps
- **4062 isolated node(s):** `refresh`, `router`, `flags`, `location`, `getKeyboardDismissBehavior` (+4057 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **5 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Return` connect `Return` to `app_database.dart`, `restore_merge_marker.dart`, `tron_border.dart`, `usage_ask_test.dart`, `usage_counter.dart`, `usage_summary.dart`, `calc_oracle.dart`, `DataClass`, `package:pos_app/core/database/app_database.dart`, `unit_conversion.dart`, `percent.dart`, `app.dart`, `package:pos_app/core/utils/currency_formatter.dart`, `csv_text.dart`, `receipt_printer.dart`, `pos_catalog_provider.dart`, `receipt_pdf_service.dart`, `money.dart`, `products_provider.dart`, `usage_providers.dart`, `receipt_roll_pdf.dart`, `escpos_raster.dart`, `package:flutter/services.dart`, `render_receipt_image.dart`, `escpos_raster_test.dart`, `side_nav.dart`, `review_policy.dart`?**
  _High betweenness centrality (0.031) - this node is a cross-community bridge._
- **Why does `AppDatabase` connect `AppDatabase` to `app_database.dart`, `DateTime`, `usage_screen_test.dart`, `package:drift/drift.dart`, `onboarding_test.dart`, `report_figures_test.dart`, `package:pos_app/features/cart/domain/cart_item.dart`, `package:pos_app/core/database/app_database.dart`, `backup_repository.dart`, `audit_service.dart`, `tables_dao.dart`, `backup/share_origin_test.dart`, `gates_test.dart`, `package:flutter_test/flutter_test.dart`, `orders_screen_test.dart`, `usage_host_test.dart`, `place_order.dart`, `order_history.dart`, `payment_screen_test.dart`, `package:pos_app/core/providers/database_provider.dart`, `auto_print_test.dart`?**
  _High betweenness centrality (0.017) - this node is a cross-community bridge._
- **Why does `HeldOrdersNotifier` connect `held_tickets_bar.dart` to `ConsumerWidget`, `databaseProvider`, `cart_notifier.dart`, `List`, `settingsProvider`?**
  _High betweenness centrality (0.005) - this node is a cross-community bridge._
- **What connects `refresh`, `router`, `flags` to the rest of the system?**
  _4062 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `app_database.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.007692307692307693 - nodes in this community are weakly interconnected._
- **Should `schema_v15.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.015625 - nodes in this community are weakly interconnected._
- **Should `schema_v11.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.017391304347826087 - nodes in this community are weakly interconnected._