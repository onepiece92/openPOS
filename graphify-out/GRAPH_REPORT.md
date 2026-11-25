# Graph Report - agent-a56494ea87981aeba  (2026-11-26)

## Corpus Check
- 342 files · ~269,998 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 5637 nodes · 9176 edges · 205 communities (198 shown, 7 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `7ea0f7ec`
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
- review_controller_test.dart
- usage_screen_test.dart
- package:pos_app/core/providers/hive_provider.dart
- usage_counter.dart
- report_data.dart
- cart_notifier.dart
- usage_summary.dart
- dart:io
- usage_host.dart
- calc_oracle.dart
- held_orders_notifier.dart
- most_sold_test.dart
- features_screen.dart
- expenses_screen.dart
- package:drift/drift.dart
- IconData?
- ConsumerWidget
- sell_screen_rebuild_test.dart
- DataClass
- package:pos_app/core/database/app_database.dart
- package:flutter/material.dart
- product_form_screen.dart
- featureOnProvider
- app_root.dart
- databaseProvider
- backup_repository.dart
- dashboard_body.dart
- feature_flags.dart
- orders_screen.dart
- backup_screen.dart
- products_screen.dart
- inventory_dao.dart
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
- receipt_tax_labels_test.dart
- products_dao.dart
- csv_text.dart
- support_screen.dart
- receipt_printer.dart
- Milestone 1: v1 (Foundation & Core POS)
- home.dart
- package:flutter_test/flutter_test.dart
- build
- usage_constants.dart
- pos_catalog_provider.dart
- String?
- ticket_header.dart
- order_detail_screen.dart
- receipt_pdf_service.dart
- dashboard_screen.dart
- snapshot_photos_test.dart
- orders_table.dart
- money.dart
- payment_screen.dart
- receipt_screen.dart
- usage_host_test.dart
- tax_group_members_table.dart
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
- cartSessionProvider
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
- StatelessWidget
- Return
- render_receipt_image.dart
- inventory_screen.dart
- returns_table.dart
- bundled_fonts.dart
- cart_item.dart
- pos_filter_provider.dart
- order_summary.dart
- auto_print_test.dart
- schema.dart
- escpos_raster_test.dart
- side_nav.dart
- held_tickets_bar.dart
- onboarding_state.dart
- spp_printer.dart
- thermal_plugin_printer.dart
- review_policy.dart
- IntColumn get
- store_profile_edit_screen.dart
- loyalty_section.dart
- package:flutter/foundation.dart
- cart_line_item.dart
- restore_merge_marker.dart
- package:flutter/services.dart
- v1 Roadmap — Flutter Offline-First POS
- tax_section.dart
- usage_screen.dart
- DateTime
- product_tile.dart
- customers_table.dart
- tron_border.dart
- discount_sheet.dart
- expenses_dao.dart
- order_items_table.dart
- _PrinterSetupScreenState
- bool get
- GeneratedDatabase
- expenses_table.dart
- app_sheet.dart
- settings_screen.dart
- _grammar.dart
- tax_rates_table.dart
- package:intl/intl.dart
- share_origin.dart
- receipt_roll_pdf_test.dart
- package:go_router/go_router.dart
- usageCounterProvider
- TextColumn get
- customers_dao.dart
- _StoreProfileEditScreenState
- link_uris.dart
- country_default.dart
- unit_conversion.dart
- @immutable
- render_receipt.dart
- audit_log_table.dart
- categories_table.dart
- order_taxes_table.dart
- appearance_section.dart
- percent.dart
- VoidCallback?
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
- review_state_store.dart
- inventory_filter_bar.dart
- CLAUDE.md
- app_version.dart
- _DeflatedFile
- _FileSink
- currencies.dart
- @rebuzzpos
- tax_step.dart
- country_step.dart
- package:pos_app/features/printing/domain/receipt_printer.dart
- tax_dao.dart
- business_type_step.dart
- tables_dao.dart
- audit_dao.dart
- in_app_review.dart
- StateNotifier
- ReceiptPrinter
- SettingsNotifier
- ReportPeriod

## God Nodes (most connected - your core abstractions)
1. `AppDatabase` - 51 edges
2. `featureOnProvider` - 38 edges
3. `databaseProvider` - 35 edges
4. `Return` - 34 edges
5. `_` - 28 edges
6. `cartSessionProvider` - 28 edges
7. `settingsProvider` - 27 edges
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

## Communities (205 total, 7 thin omitted)

### Community 0 - "app_database.dart"
Cohesion: 0.01
Nodes (259): class OrderTaxOverride extends, class ProductComponent extends, ColumnFilters, ColumnOrderings, backfillInvoiceNumbers, backfillV14, currentSchemaVersion, migration (+251 more)

### Community 1 - "schema_v15.dart"
Cohesion: 0.02
Nodes (109): action, actualTableName, address, _alias, aliasedName, allSchemaEntities, allTables, amount (+101 more)

### Community 2 - "schema_v11.dart"
Cohesion: 0.02
Nodes (115): TaxRates, action, actualTableName, address, _alias, aliasedName, allSchemaEntities, allTables (+107 more)

### Community 3 - "schema_v14.dart"
Cohesion: 0.02
Nodes (116): Categories, action, actualTableName, address, _alias, aliasedName, allSchemaEntities, allTables (+108 more)

### Community 4 - "schema_v10.dart"
Cohesion: 0.02
Nodes (114): TaxGroupMembers, action, actualTableName, address, _alias, aliasedName, allSchemaEntities, allTables (+106 more)

### Community 5 - "schema_v12.dart"
Cohesion: 0.02
Nodes (115): Index, Orders, action, actualTableName, address, _alias, aliasedName, allSchemaEntities (+107 more)

### Community 6 - "schema_v13.dart"
Cohesion: 0.02
Nodes (113): OrderTaxes, ProductTaxes, action, actualTableName, address, _alias, aliasedName, allSchemaEntities (+105 more)

### Community 7 - "schema_v9.dart"
Cohesion: 0.02
Nodes (109): ExpenseCategories, ProductComponents, Tables, action, actualTableName, address, _alias, aliasedName (+101 more)

### Community 8 - "schema_v8.dart"
Cohesion: 0.02
Nodes (107): AuditLog, OrderItems, OrderTaxOverrides, action, actualTableName, address, _alias, aliasedName (+99 more)

### Community 9 - "schema_v7.dart"
Cohesion: 0.02
Nodes (107): ProductModifiers, Returns, TaxGroups, action, actualTableName, address, _alias, aliasedName (+99 more)

### Community 10 - "schema_v4.dart"
Cohesion: 0.02
Nodes (107): GeneratedColumn, Products, ProductVariants, action, actualTableName, address, _alias, aliasedName (+99 more)

### Community 11 - "schema_v6.dart"
Cohesion: 0.02
Nodes (106): Customers, Expenses, StockAdjustments, action, actualTableName, address, _alias, aliasedName (+98 more)

### Community 12 - "snapshot_service.dart"
Cohesion: 0.02
Nodes (87): InputFileStream, _absentSuffix, add, _addDeflated, _addStored, assertNoPendingRestore, _bakSuffix, _baseName (+79 more)

### Community 13 - "hive_provider.dart"
Cohesion: 0.02
Nodes (89): autoBackupEnabled, autoBackupLastAt, _box, build, businessAddress, businessName, businessNameOrDefault, businessPan (+81 more)

### Community 14 - "AppDatabase"
Cohesion: 0.05
Nodes (53): _, @DriftDatabase, AppDatabase, AuditService, package:pos_app/core/database/close_on_exit.dart, package:pos_app/features/returns/domain/process_return.dart, package:pos_app/features/returns/domain/void_order.dart, ../../_support/sales.dart (+45 more)

### Community 15 - "Table"
Cohesion: 0.06
Nodes (65): Table, TableInfo, Categories, Customers, OrderItems, Orders, TaxRates, OrderItems (+57 more)

### Community 16 - "review_controller_test.dart"
Cohesion: 0.04
Nodes (48): appVersion, _guard, _inFlight, onReceiptDismissed, prompter, ReviewCheck, ReviewController, settleDelay (+40 more)

### Community 17 - "usage_screen_test.dart"
Cohesion: 0.08
Nodes (24): ButtonStyleButton, CheckboxListTile, _grammar.dart, counter, db, enabled, expected, files (+16 more)

### Community 18 - "package:pos_app/core/providers/hive_provider.dart"
Cohesion: 0.05
Nodes (46): Box, Directory, AutoPrintService, printOrder, _ref, _box, _kFavoriteProductIds, toggle (+38 more)

### Community 19 - "usage_counter.dart"
Cohesion: 0.04
Nodes (54): bool?, DateTime? get, after, askedVersion, _box, countingEnabled, countingOn, _counts (+46 more)

### Community 20 - "report_data.dart"
Cohesion: 0.04
Nodes (51): all, avgOrder, changes, chartDates, chartHighlightIndex, chartTitle, chartTotals, costIsIncomplete (+43 more)

### Community 21 - "cart_notifier.dart"
Cohesion: 0.05
Nodes (51): _box, formatTicketNumber, heldOrdersBoxProvider, kTicketSeqKey, next, TicketSequence, ticketSequenceProvider, CartSession (+43 more)

### Community 22 - "usage_summary.dart"
Cohesion: 0.04
Nodes (49): appInfo, appVersion, buildUsageSummary, bump, businessType, canSendUsageSummary, chars, count (+41 more)

### Community 23 - "dart:io"
Cohesion: 0.06
Nodes (39): dart:io, databaseFile, dir, kDatabaseFileName, openConnection, countOf, currentUsageEnvironment, readShopSizeCounts (+31 more)

### Community 24 - "usage_host.dart"
Cohesion: 0.05
Nodes (39): AppLifecycleListener?, dart:async, Duration, DatabaseExitGuard, dispose, _listener, timeout, afterReviewCheck (+31 more)

### Community 25 - "calc_oracle.dart"
Cohesion: 0.04
Nodes (46): BigInt, int? discPermille,
  int, balance, base, baseOnHalfCent, bp, cents, d (+38 more)

### Community 26 - "held_orders_notifier.dart"
Cohesion: 0.08
Nodes (22): HeldOrder, archive, archiveAll, archivedHeldOrdersProvider, _box, build, delete, deleteAllArchived (+14 more)

### Community 27 - "most_sold_test.dart"
Cohesion: 0.05
Nodes (37): int tea,, package:drift/native.dart, package:pos_app/core/services/demo_data_service.dart, package:pos_app/features/review/review_providers.dart, QueryInterceptor, ../../_support/query_recorder.dart, db, expectIndexed (+29 more)

### Community 28 - "features_screen.dart"
Cohesion: 0.07
Nodes (36): featureFlagsProvider, featuresIntroFreshProvider, featuresIntroSeenProvider, settingsBoxProvider, settingsProvider, stockOffSinceProvider, build, createState (+28 more)

### Community 29 - "expenses_screen.dart"
Cohesion: 0.05
Nodes (47): _amountCtrl, build, categories, category, _CategoryChips, _categoryId, _check, _Chip (+39 more)

### Community 30 - "package:drift/drift.dart"
Cohesion: 0.03
Nodes (71): int? customerId,
  int, left, processReturn, refundableAmount, refunded, transaction, transaction, voidOrder (+63 more)

### Community 31 - "IconData?"
Cohesion: 0.07
Nodes (29): Color, IconData?, _Badge, bg, customer, fg, icon, label (+21 more)

### Community 32 - "ConsumerWidget"
Cohesion: 0.14
Nodes (26): ConsumerWidget, cartMainUnitQtyProvider, build, CartDetailScreen, _ClearCartButton, _ListSeparator, PosBottomBars, _PosProductGrid (+18 more)

### Community 33 - "sell_screen_rebuild_test.dart"
Cohesion: 0.08
Nodes (24): AppBar, CustomPaint, FilterChip, GridView, build, ListView, MaterialPageRoute, NavigatorState (+16 more)

### Community 34 - "DataClass"
Cohesion: 0.09
Nodes (39): Insertable, OrderNumberX, UpdateCompanion, AuditLogCompanion, AuditLogData, CategoriesCompanion, Category, Customer (+31 more)

### Community 35 - "package:pos_app/core/database/app_database.dart"
Cohesion: 0.04
Nodes (54): CartNotifier get, db, add, _allowQty, _cart, _committed, _container, _messenger (+46 more)

### Community 36 - "package:flutter/material.dart"
Cohesion: 0.09
Nodes (20): EditableText, build, SettingsSectionHeader, title, build, ThemePreviewScreen, build, child (+12 more)

### Community 37 - "product_form_screen.dart"
Cohesion: 0.06
Nodes (33): _categoryId, _ComponentEntry, _components, _conversionCtrl, createState, _delete, didChangeDependencies, dispose (+25 more)

### Community 38 - "featureOnProvider"
Cohesion: 0.06
Nodes (51): ConsumerState, ConsumerStatefulWidget, featureOnProvider, lowStockThresholdProvider, onboardingCompleteProvider, CartScreen, _CartScreenState, _fitsStock (+43 more)

### Community 39 - "app_root.dart"
Cohesion: 0.06
Nodes (32): AppRoot, AppRootState, autoBackupDelay, _autoBackupRun, autoBackupScheduledForTest, _autoBackupTimer, build, child (+24 more)

### Community 40 - "databaseProvider"
Cohesion: 0.09
Nodes (24): databaseProvider, _delete, _save, _delete, _showAddCategoryDialog, productsByCategoryProvider, build, category (+16 more)

### Community 41 - "backup_repository.dart"
Cohesion: 0.06
Nodes (35): added, _csvEol, csvImportExplanation, CsvImportReport, db, exportCustomers, exportExpenses, exportOrders (+27 more)

### Community 42 - "dashboard_body.dart"
Cohesion: 0.11
Nodes (17): ReportData, build, _buildKpiRows, cs, DashboardBody, data, _fmt, isCustomRange (+9 more)

### Community 43 - "feature_flags.dart"
Cohesion: 0.06
Nodes (34): autoPrint, bundles, costProfit, csvImportExport, customers, dashboardExtras, defaultOn, defaults (+26 more)

### Community 44 - "orders_screen.dart"
Cohesion: 0.07
Nodes (29): orderHistoryProvider, _body, _clearQuery, createState, cs, customerName, _debounce, dispose (+21 more)

### Community 45 - "backup_screen.dart"
Cohesion: 0.06
Nodes (39): autoBackupEnabledProvider, autoBackupLastAtProvider, backupRepositoryProvider, snapshotCoordinatorProvider, _AutoBackupTile, BackupScreen, _BackupScreenState, _BackupTile (+31 more)

### Community 46 - "products_screen.dart"
Cohesion: 0.08
Nodes (23): categories, _CategoryChips, categoryName, _Chip, createState, cs, dispose, fmt (+15 more)

### Community 47 - "inventory_dao.dart"
Cohesion: 0.11
Nodes (23): @DriftAccessor, _$AuditDaoMixin, _$CustomersDaoMixin, DatabaseAccessor, _$ExpensesDaoMixin, _$InventoryDaoMixin, AuditDao, CustomersDao (+15 more)

### Community 48 - "backup/share_origin_test.dart"
Cohesion: 0.06
Nodes (30): FormatException, package:pos_app/features/backup/data/backup_repository.dart, package:pos_app/features/backup/data/csv_text.dart, package:pos_app/features/backup/presentation/backup_screen.dart, package:pos_app/features/receipts/presentation/receipt_pdf_service.dart, customers, db, main (+22 more)

### Community 49 - "tax_settings_screen.dart"
Cohesion: 0.12
Nodes (17): FormState, createState, dispose, existing, _formKey, _inclusionType, _nameCtrl, onAdd (+9 more)

### Community 50 - "snapshot_providers.dart"
Cohesion: 0.07
Nodes (27): autoBackupDir, autoBackupLastError, create, createAndShare, defaultHiveBoxPaths, docs, inspect, kAutoBackupInterval (+19 more)

### Community 51 - "onboarding_screen.dart"
Cohesion: 0.08
Nodes (32): build, onboardingNotifierProvider, _back, build, _businessNameCtrl, _countries, createState, dispose (+24 more)

### Community 52 - "printer_setup_screen.dart"
Cohesion: 0.09
Nodes (21): PrinterDriver, createState, _devices, _devicesSub, _disconnectSavedPrinter, dispose, _driver, _driverHelp (+13 more)

### Community 53 - "restore_recovery_test.dart"
Cohesion: 0.07
Nodes (31): Exception, FileSystemException, RestoreJournalFormatException, PendingRestoreException, RestoreFatalException, RestoreRolledBackException, SnapshotFormatException, backupOf (+23 more)

### Community 54 - "orders_dao.dart"
Cohesion: 0.06
Nodes (31): completedOrderCount, _escapeLike, getById, getItems, getTaxBreakdown, hasRestockedReturn, historyPage, incrementPrintCount (+23 more)

### Community 55 - "gates_test.dart"
Cohesion: 0.07
Nodes (27): package:pos_app/features/cart/presentation/home.dart, package:pos_app/features/cart/presentation/payment_screen.dart, package:pos_app/features/cart/presentation/widgets/grid_product_tile.dart, package:pos_app/features/printing/domain/auto_print.dart, package:pos_app/features/products/presentation/product_form_screen.dart, package:pos_app/features/receipts/presentation/receipt_screen.dart, package:pos_app/features/reports/domain/report_data.dart, package:pos_app/features/reports/presentation/widgets/dashboard_body.dart (+19 more)

### Community 56 - "app.dart"
Cohesion: 0.04
Nodes (48): ChangeNotifier, GoRouter, appRedirect, AppScrollBehavior, featureRedirect, flags, getKeyboardDismissBehavior, location (+40 more)

### Community 57 - "package:pos_app/core/utils/currency_formatter.dart"
Cohesion: 0.12
Nodes (15): buildReceiptText, dateFmt, join, lines, o, package:pos_app/core/utils/currency_formatter.dart, package:pos_app/features/receipts/domain/receipt_labels.dart, package:pos_app/features/receipts/presentation/receipt_body.dart (+7 more)

### Community 58 - "receipt_tax_labels_test.dart"
Cohesion: 0.07
Nodes (29): dart:math, _, CartCalculator, compute, _roundingModeFor, package:pos_app/core/utils/tax_calculator.dart, package:pos_app/features/cart/domain/cart_calculator.dart, package:pos_app/features/cart/domain/cart_session.dart (+21 more)

### Community 59 - "products_dao.dart"
Cohesion: 0.09
Nodes (21): deductStock, deleteCategory, getAllCategories, getById, getBySku, getComponents, replaceComponents, restock (+13 more)

### Community 60 - "csv_text.dart"
Cohesion: 0.07
Nodes (29): _bad, boolOf, cell, cellQuoted, _cells, _columns, CsvRow, CsvTable (+21 more)

### Community 61 - "support_screen.dart"
Cohesion: 0.12
Nodes (16): build, cs, gradient, icon, _InfoRow, label, onTap, _SectionHeader (+8 more)

### Community 62 - "receipt_printer.dart"
Cohesion: 0.07
Nodes (28): address, data, devices, DiscoveredPrinter, driver, escPosPrinterProvider, fmt, fromKey (+20 more)

### Community 63 - "Milestone 1: v1 (Foundation & Core POS)"
Cohesion: 0.07
Nodes (26): 1. State Management (Riverpod), 2. Navigation (GoRouter), 3. Data Layer (Drift & Hive), 4. Hardware Integration, Core Pillars, Data Flow, Directory Structure, Overview (+18 more)

### Community 64 - "home.dart"
Cohesion: 0.08
Nodes (28): demoDataServiceProvider, posCatalogProvider, posFilterProvider, categories, _CategoryRow, _Chip, createState, dispose (+20 more)

### Community 65 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.07
Nodes (26): generated/schema.dart, package:drift_dev/api/migrations_common.dart, package:drift_dev/api/migrations_native.dart, package:flutter_test/flutter_test.dart, package:pos_app/core/utils/money.dart, package:pos_app/features/products/domain/stock_level.dart, package:pos_app/features/products/domain/unit_conversion.dart, SchemaVerifier (+18 more)

### Community 66 - "build"
Cohesion: 0.11
Nodes (26): build, build, build, categoriesStreamProvider, CategoriesScreen, build, build, build (+18 more)

### Community 67 - "usage_constants.dart"
Cohesion: 0.08
Nodes (25): kFeedbackAreaQuestion, kFeedbackAskAction, kFeedbackAskText, kFeedbackInstruction, kFeedbackMessageMaxLength, kFeedbackSupportRowSubtitle, kFeedbackSupportRowTitle, kOfflineFirstLine (+17 more)

### Community 68 - "pos_catalog_provider.dart"
Cohesion: 0.08
Nodes (24): AsyncValue, buildPosSearchIndex, cart, catalogEmpty, categoryId, committedMainUnits, favorites, favoritesOnly (+16 more)

### Community 69 - "String?"
Cohesion: 0.12
Nodes (14): double?, action, AppEmptyState, build, icon, subtitle, title, build (+6 more)

### Community 70 - "ticket_header.dart"
Cohesion: 0.10
Nodes (22): businessTypeNameProvider, currencyCodeProvider, currencySymbolProvider, shareFilesProvider, session, TicketHeader, build, _CurrencyPickerSheet (+14 more)

### Community 71 - "order_detail_screen.dart"
Cohesion: 0.09
Nodes (21): businessName, customer, data, db, _DetailData, fmt, isPartlyRefunded, items (+13 more)

### Community 72 - "receipt_pdf_service.dart"
Cohesion: 0.08
Nodes (23): baseStyle, billRow, boldStyle, buildReceiptPdf, bytes, customerName, _dataCell, dateFmt (+15 more)

### Community 73 - "dashboard_screen.dart"
Cohesion: 0.19
Nodes (12): DateTimeRange?, reportProvider, reportSectionsProvider, build, createState, _customRange, DashboardScreen, _DashboardScreenState (+4 more)

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

### Community 80 - "tax_group_members_table.dart"
Cohesion: 0.14
Nodes (13): primaryKey, productId, ProductTaxes, taxRateId, groupId, primaryKey, sortOrder, TaxGroupMembers (+5 more)

### Community 81 - "tables_screen.dart"
Cohesion: 0.10
Nodes (21): _assignToCart, _capacityCtrl, createState, dispose, existing, initState, isCurrentCartTable, isOccupied (+13 more)

### Community 82 - "products_table.dart"
Cohesion: 0.10
Nodes (19): categoryId, conversionRate, createdAt, id, imagePath, isActive, isComposite, isHiddenInPos (+11 more)

### Community 83 - "held_order.dart"
Cohesion: 0.10
Nodes (20): archivedAt, copyWith, createdAt, customerId, customerName, fromJson, id, isArchived (+12 more)

### Community 84 - "inventory_card.dart"
Cohesion: 0.10
Nodes (20): _apply, badgeColor, build, canDecrement, canIncrement, cs, _decrement, icon (+12 more)

### Community 85 - "products_provider.dart"
Cohesion: 0.11
Nodes (18): applyProductsFilter, clearSearch, copyWith, list, mostSoldWindow, outOfStockOnly, productSalesCountProvider, ref (+10 more)

### Community 86 - "receipt_body.dart"
Cohesion: 0.10
Nodes (19): _BillRow, build, businessName, customer, data, _DataCell, fmt, _HeaderCell (+11 more)

### Community 87 - "usage_providers.dart"
Cohesion: 0.07
Nodes (28): dart:ui, ShareFiles, shareFilesWithOs, c, f, launch, link, LinkLauncher (+20 more)

### Community 88 - "place_order.dart"
Cohesion: 0.20
Nodes (9): components, cost, invoicePrefix, placeOrder, roundMoney, trackStock, transaction, _unitCostNow (+1 more)

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
Cohesion: 0.15
Nodes (12): canLaunch, kLinkFailureMessageDuration, _kSupportWhatsAppDigits, kSupportWhatsAppDisplay, kSupportWhatsAppUnavailable, launch, messenger, native (+4 more)

### Community 93 - "order_history.dart"
Cohesion: 0.11
Nodes (19): _changes, copyWith, _db, dispose, error, _generation, hasMore, isLoading (+11 more)

### Community 94 - "Open POS"
Cohesion: 0.10
Nodes (19): Build from source, Contributing, Customers, Features, Get Open POS, License, macOS, Money and reports (+11 more)

### Community 95 - "customers_screen.dart"
Cohesion: 0.12
Nodes (16): IconData get, build, createState, dispose, _filterAndSort, icon, label, _openForm (+8 more)

### Community 96 - "tokens.dart"
Cohesion: 0.11
Nodes (18): AppFonts, AppOpacity, heavy, lg, md, medium, mono, Radii (+10 more)

### Community 97 - "audit_log_screen.dart"
Cohesion: 0.20
Nodes (11): action, _ActionChip, _actionColor, _actionIcon, AuditLogScreen, auditLogsProvider, build, color (+3 more)

### Community 98 - "cartSessionProvider"
Cohesion: 0.08
Nodes (32): int?, cartSessionProvider, activeHeldOrdersProvider, build, createState, customers, onSelect, _search (+24 more)

### Community 99 - "customer_form.dart"
Cohesion: 0.12
Nodes (16): _addressCtrl, build, createState, customer, CustomerForm, _CustomerFormState, _discountCtrl, _discountIsPercent (+8 more)

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
Cohesion: 0.12
Nodes (16): Completer, package:pos_app/core/providers/audit_service_provider.dart, app, c, confirm, db, gate, heldBox (+8 more)

### Community 105 - "escpos_raster.dart"
Cohesion: 0.11
Nodes (17): dart:isolate, Future, bytes, cached, canvas, escPosProfile, escPosRasterBytes, escPosRasterBytesSync (+9 more)

### Community 106 - "onboarding_notifier.dart"
Cohesion: 0.11
Nodes (17): FeatureFlags get, back, build, _defaults, next, _passed, _saveFeatures, _saveProfile (+9 more)

### Community 107 - "package:pos_app/core/providers/database_provider.dart"
Cohesion: 0.11
Nodes (15): _db, DemoDataService, seed, _seedDatabase, _settings, build, _confirmReset, package:pos_app/core/providers/database_provider.dart (+7 more)

### Community 108 - "article_detail_screen.dart"
Cohesion: 0.11
Nodes (17): ArticleDetailScreen, ArticleSection, build, category, cs, heading, icon, readTime (+9 more)

### Community 109 - "learn_screen.dart"
Cohesion: 0.07
Nodes (27): ColorScheme, _Article, _ArticleCard, _articles, category, cs, description, icon (+19 more)

### Community 110 - "StatelessWidget"
Cohesion: 0.09
Nodes (25): cs, key_, _KeyChip, keys, label, _SectionHeader, _ShortcutRow, text (+17 more)

### Community 111 - "Return"
Cohesion: 0.15
Nodes (10): initials, name, null, stockCapFor, friendlyPrinterError, known, _match, null (+2 more)

### Community 112 - "render_receipt_image.dart"
Cohesion: 0.17
Nodes (11): doc, escPosPrintWidthDots, isCopy, kReceiptDpi, pages, _rasterise, renderReceiptImages, renderTestPageImages (+3 more)

### Community 113 - "inventory_screen.dart"
Cohesion: 0.13
Nodes (14): Iterable, createState, dispose, _filter, _filtered, filterInventoryProducts, list, _search (+6 more)

### Community 114 - "returns_table.dart"
Cohesion: 0.12
Nodes (15): createdAt, id, orderId, OrderTaxOverrides, originalTax, overrideTax, reason, amount (+7 more)

### Community 115 - "bundled_fonts.dart"
Cohesion: 0.20
Nodes (9): bundledFontData, bundledPdfFont, cached, _fontData, future, jetBrainsMonoBold, jetBrainsMonoItalic, jetBrainsMonoRegular (+1 more)

### Community 116 - "cart_item.dart"
Cohesion: 0.12
Nodes (16): copyWith, grossAmount, isSecondaryUnit, isTaxable, lineDiscount, lineSubtotal, mainUnitQty, name (+8 more)

### Community 117 - "pos_filter_provider.dart"
Cohesion: 0.14
Nodes (13): clearSearch, copyWith, favoritesOnly, isGrid, PosSortMode, search, selectedCategoryId, setCategory (+5 more)

### Community 118 - "order_summary.dart"
Cohesion: 0.10
Nodes (18): addColor, cs, fmt, label, onTap, ref, _showTaxPicker, summary (+10 more)

### Community 119 - "auto_print_test.dart"
Cohesion: 0.12
Nodes (15): Object?, box, db, devices, failWith, main, makeContainer, printed (+7 more)

### Community 120 - "schema.dart"
Cohesion: 0.12
Nodes (16): package:drift/internal/migrations.dart, schema_v10.dart, schema_v11.dart, schema_v12.dart, schema_v13.dart, schema_v14.dart, schema_v15.dart, schema_v4.dart (+8 more)

### Community 121 - "escpos_raster_test.dart"
Cohesion: 0.11
Nodes (16): dart:typed_data, package:image/image.dart, StateError, _blockPage, _countSequence, _firstRaster, found, fromList (+8 more)

### Community 122 - "side_nav.dart"
Cohesion: 0.12
Nodes (16): Feature, f, feature, featureForLocation, featureRedirect, group, icon, kFeaturesIntroFreshText (+8 more)

### Community 123 - "held_tickets_bar.dart"
Cohesion: 0.14
Nodes (15): AnimationController, heldOrdersProvider, CheckoutBar, _buildActiveList, _buildArchivedList, createState, _ctrl, dispose (+7 more)

### Community 124 - "onboarding_state.dart"
Cohesion: 0.12
Nodes (15): businessName, businessType, copyWith, country, current, isLast, kOnboardingSteps, label (+7 more)

### Community 125 - "spp_printer.dart"
Cohesion: 0.13
Nodes (13): _devices, dispose, _methods, _print, printReceipt, printTestPage, _requireAndroid, startScan (+5 more)

### Community 126 - "thermal_plugin_printer.dart"
Cohesion: 0.12
Nodes (15): _connect, _connectTimeout, devices, _disconnect, _ftp, _pluginDevice, _printPages, printReceipt (+7 more)

### Community 127 - "review_policy.dart"
Cohesion: 0.12
Nodes (15): at, first, firstLaunchAt, kMinDaysBetweenAnyPrompts, kReviewMinCompletedSales, kReviewMinDaysBetweenPrompts, kReviewMinDaysSinceInstall, last (+7 more)

### Community 128 - "IntColumn get"
Cohesion: 0.11
Nodes (16): IntColumn get, componentProductId, compositeProductId, id, ProductComponents, quantity, createdAt, delta (+8 more)

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

### Community 134 - "package:flutter/services.dart"
Cohesion: 0.08
Nodes (24): AndroidSdk, _cached, _methods, _read, sdkInt, _devices, _discovery, dispose (+16 more)

### Community 135 - "v1 Roadmap — Flutter Offline-First POS"
Cohesion: 0.13
Nodes (14): Architecture Decisions, Deferred to v2, Drift Schema — Full Table List (v1), Phase 0 — Foundation (No UI yet), Phase 1 — First-Run & Onboarding, Phase 2 — Product & Inventory Core, Phase 3 — Core Sales Loop, Phase 4 — Receipts & Hardware (+6 more)

### Community 136 - "tax_section.dart"
Cohesion: 0.15
Nodes (16): defaultTaxIdProvider, invoicePrefixProvider, build, reset, taxRatesStreamProvider, build, currentId, _DefaultTaxTile (+8 more)

### Community 137 - "usage_screen.dart"
Cohesion: 0.12
Nodes (15): BusinessType? get, UsageCounter, _businessType, _confirmReset, _counter, createState, dispose, _message (+7 more)

### Community 138 - "DateTime"
Cohesion: 0.18
Nodes (13): DateTime, BackupRepository, package:csv/csv.dart, bytesOf, db, legacyAllOrdersWithItems, legacyOrdersCsv, legacySalesReportCsv (+5 more)

### Community 139 - "product_tile.dart"
Cohesion: 0.13
Nodes (14): bg, color, cs, icon, onDecrement, onIncrement, onTap, product (+6 more)

### Community 140 - "customers_table.dart"
Cohesion: 0.14
Nodes (13): address, createdAt, Customers, defaultDiscount, defaultDiscountIsPercent, email, id, isTaxExempt (+5 more)

### Community 141 - "tron_border.dart"
Cohesion: 0.15
Nodes (12): CustomPainter, color, e, extractWrappedPath, f, len, p, paint (+4 more)

### Community 142 - "discount_sheet.dart"
Cohesion: 0.11
Nodes (22): double get, RestartNoticeOverlay, RestartNoticeOverlayState, CustomerPickerSheet, _CustomerPickerSheetState, build, createState, _ctrl (+14 more)

### Community 143 - "expenses_dao.dart"
Cohesion: 0.15
Nodes (12): getAll, getAllCategories, insert, insertCategory, totalForPeriod, updateExpense, upsertCategory, watchAll (+4 more)

### Community 144 - "order_items_table.dart"
Cohesion: 0.15
Nodes (12): discount, id, lineTotal, orderId, productId, productName, quantity, taxAmount (+4 more)

### Community 145 - "_PrinterSetupScreenState"
Cohesion: 0.21
Nodes (15): printerDeviceAddressProvider, printerDeviceNameProvider, printerDriverProvider, printerPaperWidthProvider, build, _orderDetailProvider, printerForDriverProvider, receiptPrinterProvider (+7 more)

### Community 146 - "bool get"
Cohesion: 0.14
Nodes (13): bool get, copyWith, customerId, fresh, heldTicketId, isEditingHeldTicket, loyaltyPointsToRedeem, openedAt (+5 more)

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

### Community 156 - "package:go_router/go_router.dart"
Cohesion: 0.10
Nodes (19): BackupSection, package:go_router/go_router.dart, package:pos_app/features/onboarding/domain/onboarding_state.dart, package:pos_app/features/onboarding/presentation/onboarding_notifier.dart, package:pos_app/features/onboarding/presentation/onboarding_screen.dart, package:pos_app/features/onboarding/presentation/widgets/features_step.dart, package:pos_app/features/side_nav/presentation/side_nav.dart, ScaffoldState (+11 more)

### Community 157 - "usageCounterProvider"
Cohesion: 0.20
Nodes (14): auditServiceProvider, _createFullBackup, _runExport, PaymentScreen, _PaymentScreenState, _placeOrder, _showDiscountSheet, _pickCustomer (+6 more)

### Community 158 - "TextColumn get"
Cohesion: 0.12
Nodes (15): @DataClassName, DateTimeColumn get, capacity, createdAt, id, name, notes, Tables (+7 more)

### Community 159 - "customers_dao.dart"
Cohesion: 0.18
Nodes (10): addLoyaltyPoints, getAll, getById, namesFor, redeemLoyaltyPoints, search, upsert, watchAll (+2 more)

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
Cohesion: 0.25
Nodes (8): @immutable, FeatureFlags, ReportSections, ReviewState, ShopSizeCounts, UsageCount, UsageEnvironment, UsageSelection

### Community 165 - "render_receipt.dart"
Cohesion: 0.14
Nodes (13): bytes, customerName, g, isCopy, _kv, method, methodLabel, profile (+5 more)

### Community 166 - "audit_log_table.dart"
Cohesion: 0.12
Nodes (15): @TableIndex, action, AuditLog, createdAt, entityId, entityType, id, metadata (+7 more)

### Community 167 - "categories_table.dart"
Cohesion: 0.22
Nodes (8): Categories, createdAt, id, name, parentId, sortOrder, taxRateId, updatedAt

### Community 168 - "order_taxes_table.dart"
Cohesion: 0.12
Nodes (14): BoolColumn get, color, ExpenseCategories, id, isDefault, name, id, isInclusive (+6 more)

### Community 169 - "appearance_section.dart"
Cohesion: 0.25
Nodes (8): themeModeProvider, AppearanceSection, build, current, _options, _showThemePicker, _ThemePickerSheet, ThemeMode

### Community 170 - "percent.dart"
Cohesion: 0.22
Nodes (8): formatPercent, formatPercentNumber, formatRateForEdit, formatRatePercent, kPercentDecimals, kPercentInputPattern, text, RegExp

### Community 171 - "VoidCallback?"
Cohesion: 0.12
Nodes (14): build, labels, onSkip, step, WizardHeader, build, canNext, isLast (+6 more)

### Community 172 - "Projects Dependencies"
Cohesion: 0.22
Nodes (8): Dev Dependencies, [Hardware] flutter_thermal_printer, Major Dependencies, Outdated / Deprecated Dependencies, Overview, [Persistence] drift, Projects Dependencies, [State Management] flutter_riverpod

### Community 173 - "External Integrations"
Cohesion: 0.22
Nodes (8): APIs & External Services, Authentication & Identity, CI/CD & Deployment, Data Storage, Environment Configuration, External Integrations, Monitoring & Observability, Webhooks & Callbacks

### Community 174 - "@visibleForTesting"
Cohesion: 0.22
Nodes (9): @visibleForTesting, handleExitRequest, customersCsv, expensesCsv, productsCsv, writeOrdersCsv, writeSalesReportCsv, exactAmountText (+1 more)

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

### Community 185 - "review_state_store.dart"
Cohesion: 0.08
Nodes (22): _box, _date, ensureFirstLaunch, markAnyPromptShown, markPrompted, mergeAfterRestore, mergeReviewStateAfterRestore, read (+14 more)

### Community 186 - "inventory_filter_bar.dart"
Cohesion: 0.17
Nodes (11): build, _Chip, color, InventoryFilterBar, label, lowCount, onSelect, onTap (+3 more)

### Community 187 - "CLAUDE.md"
Cohesion: 0.50
Nodes (3): Database schema changes, graphify, Offline-first (non-negotiable)

### Community 188 - "app_version.dart"
Cohesion: 0.50
Nodes (3): kAppBuildNumber, kAppVersion, kAppVersionFull

### Community 193 - "tax_step.dart"
Cohesion: 0.18
Nodes (9): build, BusinessNameStep, controller, build, currencySymbol, nameController, rateController, TaxStep (+1 more)

### Community 194 - "country_step.dart"
Cohesion: 0.20
Nodes (9): build, countries, CountryStep, loading, onSearch, onSelect, searchController, selected (+1 more)

### Community 195 - "package:pos_app/features/printing/domain/receipt_printer.dart"
Cohesion: 0.22
Nodes (8): lastSdkNeedingLocationForBle, permissionsForScan, scanNeedsLocation, package:permission_handler/permission_handler.dart, package:pos_app/features/printing/domain/receipt_printer.dart, package:pos_app/features/printing/domain/scan_permissions.dart, bluetooth, main

### Community 196 - "tax_dao.dart"
Cohesion: 0.22
Nodes (8): getAll, getById, getRatesForProduct, setProductTaxes, upsertRate, watchActive, package:pos_app/core/database/tables/product_taxes_table.dart, _

### Community 197 - "business_type_step.dart"
Cohesion: 0.22
Nodes (8): BusinessType, build, BusinessTypeStep, kBusinessTypeSubtitle, kBusinessTypeTitle, onPick, selected, package:pos_app/features/onboarding/domain/business_type.dart

### Community 198 - "tables_dao.dart"
Cohesion: 0.25
Nodes (7): deleteById, getAll, getById, upsert, watchAll, package:pos_app/core/database/tables/tables_table.dart, _

### Community 199 - "audit_dao.dart"
Cohesion: 0.29
Nodes (6): log, queryByDateRange, queryByEntity, watchRecent, package:pos_app/core/database/tables/audit_log_table.dart, _

### Community 200 - "in_app_review.dart"
Cohesion: 0.29
Nodes (6): InAppReview, instance, isAvailable, openStoreListing, requestReview, static final InAppReview

### Community 201 - "StateNotifier"
Cohesion: 0.40
Nodes (5): PosFilterNotifier, PosFilterState, ProductsFilterNotifier, ProductsFilterState, StateNotifier

### Community 202 - "ReceiptPrinter"
Cohesion: 0.40
Nodes (5): SppPrinter, StarBluetoothPrinter, ThermalPluginPrinter, ReceiptPrinter, FakeReceiptPrinter

## Knowledge Gaps
- **4085 isolated node(s):** `refresh`, `router`, `flags`, `location`, `getKeyboardDismissBehavior` (+4080 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **7 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Return` connect `Return` to `app_database.dart`, `restore_merge_marker.dart`, `tron_border.dart`, `usage_counter.dart`, `usage_summary.dart`, `calc_oracle.dart`, `held_orders_notifier.dart`, `DataClass`, `package:pos_app/core/database/app_database.dart`, `unit_conversion.dart`, `render_receipt.dart`, `percent.dart`, `app.dart`, `review_state_store.dart`, `csv_text.dart`, `receipt_printer.dart`, `pos_catalog_provider.dart`, `receipt_pdf_service.dart`, `money.dart`, `products_provider.dart`, `usage_providers.dart`, `receipt_roll_pdf.dart`, `escpos_raster.dart`, `render_receipt_image.dart`, `bundled_fonts.dart`, `escpos_raster_test.dart`, `side_nav.dart`, `review_policy.dart`?**
  _High betweenness centrality (0.030) - this node is a cross-community bridge._
- **Why does `AppDatabase` connect `AppDatabase` to `app_database.dart`, `IntColumn get`, `DateTime`, `usage_screen_test.dart`, `package:pos_app/core/providers/hive_provider.dart`, `most_sold_test.dart`, `package:go_router/go_router.dart`, `package:drift/drift.dart`, `package:pos_app/core/database/app_database.dart`, `backup_repository.dart`, `audit_service.dart`, `inventory_dao.dart`, `backup/share_origin_test.dart`, `gates_test.dart`, `app.dart`, `receipt_tax_labels_test.dart`, `package:flutter_test/flutter_test.dart`, `usage_host_test.dart`, `order_history.dart`, `payment_screen_test.dart`, `package:pos_app/core/providers/database_provider.dart`, `auto_print_test.dart`?**
  _High betweenness centrality (0.013) - this node is a cross-community bridge._
- **Why does `InAppReview` connect `in_app_review.dart` to `review_controller_test.dart`?**
  _High betweenness centrality (0.011) - this node is a cross-community bridge._
- **What connects `refresh`, `router`, `flags` to the rest of the system?**
  _4085 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `app_database.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.007692307692307693 - nodes in this community are weakly interconnected._
- **Should `schema_v15.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.01818181818181818 - nodes in this community are weakly interconnected._
- **Should `schema_v11.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.017241379310344827 - nodes in this community are weakly interconnected._