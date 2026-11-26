# Graph Report - agent-a56494ea87981aeba  (2026-11-26)

## Corpus Check
- 345 files · ~271,538 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 5669 nodes · 9234 edges · 197 communities (193 shown, 4 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `ee3f6bdb`
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
- package:flutter_riverpod/flutter_riverpod.dart
- usage_counter.dart
- report_data.dart
- cart_notifier.dart
- usage_summary.dart
- restore_merge_marker_test.dart
- usage_ask_controller.dart
- calc_oracle.dart
- report_figures_test.dart
- query_plan_test.dart
- features_screen.dart
- expenses_screen.dart
- package:drift/drift.dart
- IconData?
- ConsumerWidget
- dart:async
- DataClass
- sell_screen_rebuild_test.dart
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
- inventory_dao.dart
- backup/share_origin_test.dart
- tax_settings_screen.dart
- snapshot_providers.dart
- onboarding_screen.dart
- printer_setup_screen.dart
- restore_recovery_test.dart
- orders_dao.dart
- smoke_sale_test.dart
- app.dart
- package:pos_app/core/utils/currency_formatter.dart
- package:pos_app/features/cart/domain/cart_item.dart
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
- migration_test.dart
- featureOnProvider
- order_detail_screen.dart
- receipt_pdf_service.dart
- package:pos_app/features/side_nav/presentation/side_nav.dart
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
- auto_print_test.dart
- Open POS
- customers_screen.dart
- tokens.dart
- audit_log_screen.dart
- held_tickets_bar.dart
- package:pos_app/features/usage/domain/usage_event.dart
- features_step.dart
- receipt_roll_pdf.dart
- snapshot_service_test.dart
- restore_merge_test.dart
- payment_screen_test.dart
- escpos_raster.dart
- onboarding_notifier.dart
- package:pos_app/core/database/app_database.dart
- String?
- List
- StatelessWidget
- printer_errors.dart
- render_receipt_image.dart
- usage_host.dart
- returns_table.dart
- bundled_fonts.dart
- cart_item.dart
- sales.dart
- order_summary.dart
- State
- schema.dart
- escpos_raster_test.dart
- side_nav.dart
- locale_country.dart
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
- dart:io
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
- onboardingNotifierProvider
- _grammar.dart
- tax_rates_table.dart
- package:intl/intl.dart
- share_origin.dart
- receipt_roll_pdf_test.dart
- business_type.dart
- static const
- TextColumn get
- customers_dao.dart
- deviceRegionProvider
- review_prompter.dart
- country_default.dart
- unit_conversion.dart
- @immutable
- render_receipt.dart
- audit_log_table.dart
- categories_table.dart
- order_taxes_table.dart
- package:pos_app/shared/widgets/app_sheet.dart
- Return
- VoidCallback?
- Projects Dependencies
- External Integrations
- @visibleForTesting
- package:pos_app/features/onboarding/domain/locale_country.dart
- package:pos_app/features/orders/domain/order_number.dart
- support_contact_test.dart
- Project Conventions
- Technology Stack
- _
- usage_event.dart
- int get
- install_macos.sh
- review_state_store.dart
- inventory_filter_bar.dart
- CLAUDE.md
- app_version.dart
- currencies.dart
- @rebuzzpos
- country_step.dart
- package:pos_app/features/printing/domain/receipt_printer.dart
- tax_dao.dart
- usage_no_forbidden_fields_test.dart
- tables_dao.dart
- audit_dao.dart
- ReportPeriod

## God Nodes (most connected - your core abstractions)
1. `AppDatabase` - 52 edges
2. `featureOnProvider` - 41 edges
3. `Return` - 35 edges
4. `databaseProvider` - 35 edges
5. `_` - 28 edges
6. `cartSessionProvider` - 28 edges
7. `settingsProvider` - 27 edges
8. `currencyFormatterProvider` - 22 edges
9. `AuditService` - 20 edges
10. `usageCounterProvider` - 20 edges

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

## Communities (197 total, 4 thin omitted)

### Community 0 - "app_database.dart"
Cohesion: 0.01
Nodes (259): class OrderTaxOverride extends, class ProductComponent extends, ColumnFilters, ColumnOrderings, backfillInvoiceNumbers, backfillV14, currentSchemaVersion, migration (+251 more)

### Community 1 - "schema_v15.dart"
Cohesion: 0.02
Nodes (121): action, actualTableName, address, _alias, aliasedName, allSchemaEntities, allTables, amount (+113 more)

### Community 2 - "schema_v11.dart"
Cohesion: 0.02
Nodes (114): Products, action, actualTableName, address, _alias, aliasedName, allSchemaEntities, allTables (+106 more)

### Community 3 - "schema_v14.dart"
Cohesion: 0.02
Nodes (116): Categories, action, actualTableName, address, _alias, aliasedName, allSchemaEntities, allTables (+108 more)

### Community 4 - "schema_v10.dart"
Cohesion: 0.02
Nodes (113): TaxGroupMembers, action, actualTableName, address, _alias, aliasedName, allSchemaEntities, allTables (+105 more)

### Community 5 - "schema_v12.dart"
Cohesion: 0.02
Nodes (112): AuditLog, OrderTaxOverrides, action, actualTableName, address, _alias, aliasedName, allSchemaEntities (+104 more)

### Community 6 - "schema_v13.dart"
Cohesion: 0.02
Nodes (112): Index, ProductTaxes, TaxRates, action, actualTableName, address, _alias, aliasedName (+104 more)

### Community 7 - "schema_v9.dart"
Cohesion: 0.02
Nodes (110): Expenses, ProductVariants, Tables, action, actualTableName, address, _alias, aliasedName (+102 more)

### Community 8 - "schema_v8.dart"
Cohesion: 0.02
Nodes (109): Customers, ExpenseCategories, action, actualTableName, address, _alias, aliasedName, allSchemaEntities (+101 more)

### Community 9 - "schema_v7.dart"
Cohesion: 0.02
Nodes (107): OrderItems, OrderTaxes, action, actualTableName, address, _alias, aliasedName, allSchemaEntities (+99 more)

### Community 10 - "schema_v4.dart"
Cohesion: 0.02
Nodes (107): GeneratedColumn, ProductModifiers, StockAdjustments, action, actualTableName, address, _alias, aliasedName (+99 more)

### Community 11 - "schema_v6.dart"
Cohesion: 0.02
Nodes (102): Orders, ProductComponents, Returns, TaxGroups, action, actualTableName, address, _alias (+94 more)

### Community 12 - "snapshot_service.dart"
Cohesion: 0.02
Nodes (91): FileContent, InputFileStream, _absentSuffix, add, _addDeflated, _addStored, assertNoPendingRestore, _bakSuffix (+83 more)

### Community 13 - "hive_provider.dart"
Cohesion: 0.02
Nodes (90): autoBackupEnabled, autoBackupLastAt, _box, build, businessAddress, businessName, businessNameOrDefault, businessPan (+82 more)

### Community 14 - "AppDatabase"
Cohesion: 0.04
Nodes (59): _, @DriftDatabase, int tea,, AppDatabase, AuditService, trackStock, transaction, voidOrder (+51 more)

### Community 15 - "Table"
Cohesion: 0.07
Nodes (60): Table, TableInfo, AuditLog, Categories, Orders, ProductComponents, ProductModifiers, TaxGroupMembers (+52 more)

### Community 16 - "review_controller_test.dart"
Cohesion: 0.05
Nodes (40): ReviewController, maybeRequestReview, NoopReviewPrompter, openStoreListing, StoreReviewPrompter, ReviewPrompter, reviewPrompterProvider, storeReviewSupported (+32 more)

### Community 17 - "usage_screen_test.dart"
Cohesion: 0.11
Nodes (18): ButtonStyleButton, CheckboxListTile, counter, db, enabled, expected, files, launched (+10 more)

### Community 18 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.03
Nodes (78): Box, Directory, db, _db, DemoDataService, seed, _seedDatabase, _settings (+70 more)

### Community 19 - "usage_counter.dart"
Cohesion: 0.04
Nodes (54): bool?, DateTime? get, after, askedVersion, _box, countingEnabled, countingOn, _counts (+46 more)

### Community 20 - "report_data.dart"
Cohesion: 0.04
Nodes (51): all, avgOrder, changes, chartDates, chartHighlightIndex, chartTitle, chartTotals, costIsIncomplete (+43 more)

### Community 21 - "cart_notifier.dart"
Cohesion: 0.06
Nodes (37): AppSettings, SettingsNotifier, ticketSequenceProvider, CartSession, addItem, addProduct, addProductInSecondaryUnit, CartNotifier (+29 more)

### Community 22 - "usage_summary.dart"
Cohesion: 0.04
Nodes (49): appInfo, appVersion, buildUsageSummary, bump, businessType, canSendUsageSummary, chars, count (+41 more)

### Community 23 - "restore_merge_marker_test.dart"
Cohesion: 0.08
Nodes (27): main, startup, fatal, notice, openStartupStores, recovery, startReviewClock, startUp (+19 more)

### Community 24 - "usage_ask_controller.dart"
Cohesion: 0.11
Nodes (17): afterReviewCheck, appVersion, counter, dispose, evaluate, fossBuild, _inFlight, kFossBuild (+9 more)

### Community 25 - "calc_oracle.dart"
Cohesion: 0.04
Nodes (46): BigInt, int? discPermille,
  int, balance, base, baseOnHalfCent, bp, cents, d (+38 more)

### Community 26 - "report_figures_test.dart"
Cohesion: 0.07
Nodes (25): package:pos_app/features/reports/domain/report_data.dart, package:pos_app/features/reports/presentation/widgets/dashboard_body.dart, ProviderContainer, ../../_support/features.dart, add, c, cart, line (+17 more)

### Community 27 - "query_plan_test.dart"
Cohesion: 0.12
Nodes (14): QueryInterceptor, db, expectIndexed, from, fullScan, main, planOf, recorder (+6 more)

### Community 28 - "features_screen.dart"
Cohesion: 0.06
Nodes (44): autoBackupEnabledProvider, autoBackupLastAtProvider, featureFlagsProvider, featuresIntroFreshProvider, featuresIntroSeenProvider, settingsBoxProvider, settingsProvider, stockOffSinceProvider (+36 more)

### Community 29 - "expenses_screen.dart"
Cohesion: 0.05
Nodes (43): _amountCtrl, build, categories, category, _categoryId, _check, color, createState (+35 more)

### Community 30 - "package:drift/drift.dart"
Cohesion: 0.05
Nodes (46): customerId, customerNamesKey, customerNamesProvider, customers, ref, watch, package:drift/drift.dart, package:pos_app/features/cart/data/place_order.dart (+38 more)

### Community 31 - "IconData?"
Cohesion: 0.13
Nodes (13): IconData?, build, icon, isDestructive, onTap, StepButton, build, emphasis (+5 more)

### Community 32 - "ConsumerWidget"
Cohesion: 0.12
Nodes (27): ConsumerWidget, cartMainUnitQtyProvider, build, CartDetailScreen, _ClearCartButton, _ListSeparator, PosBottomBars, _PosProductGrid (+19 more)

### Community 33 - "dart:async"
Cohesion: 0.09
Nodes (20): AppLifecycleListener?, dart:async, dart:ui, Duration, DatabaseExitGuard, dispose, _listener, timeout (+12 more)

### Community 34 - "DataClass"
Cohesion: 0.09
Nodes (39): Insertable, OrderNumberX, UpdateCompanion, AuditLogCompanion, AuditLogData, CategoriesCompanion, Category, Customer (+31 more)

### Community 35 - "sell_screen_rebuild_test.dart"
Cohesion: 0.04
Nodes (53): AppBar, CartNotifier get, CustomPaint, FilterChip, GridView, add, _allowQty, _cart (+45 more)

### Community 36 - "package:flutter/material.dart"
Cohesion: 0.08
Nodes (20): BackupSection, build, SettingsSectionHeader, title, build, ThemePreviewScreen, action, AppEmptyState (+12 more)

### Community 37 - "product_form_screen.dart"
Cohesion: 0.06
Nodes (33): _categoryId, _ComponentEntry, _components, _conversionCtrl, createState, _delete, didChangeDependencies, dispose (+25 more)

### Community 38 - "ConsumerState"
Cohesion: 0.05
Nodes (45): ConsumerState, ConsumerStatefulWidget, Iterable, lowStockThresholdProvider, BackupScreen, PaymentScreen, _HeldTicketsSheet, CustomersScreen (+37 more)

### Community 39 - "app_root.dart"
Cohesion: 0.07
Nodes (29): autoBackupDelay, _autoBackupRun, autoBackupScheduledForTest, _autoBackupTimer, build, child, _closeDatabaseForExit, _container (+21 more)

### Community 40 - "databaseProvider"
Cohesion: 0.05
Nodes (46): databaseProvider, _addressCtrl, build, createState, customer, CustomerForm, _CustomerFormState, _delete (+38 more)

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
Nodes (35): orderHistoryProvider, _body, _clearQuery, createState, cs, customerName, _debounce, dispose (+27 more)

### Community 45 - "backup_screen.dart"
Cohesion: 0.06
Nodes (31): _BackupTile, _buildInfoCard, color, _confirmAndImport, _createFullBackup, createState, cs, files (+23 more)

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
Cohesion: 0.07
Nodes (34): FormState, int?, defaultTaxIdProvider, invoicePrefixProvider, build, reset, taxRatesStreamProvider, build (+26 more)

### Community 50 - "snapshot_providers.dart"
Cohesion: 0.08
Nodes (25): autoBackupDir, autoBackupLastError, create, createAndShare, defaultHiveBoxPaths, docs, inspect, kAutoBackupInterval (+17 more)

### Community 51 - "onboarding_screen.dart"
Cohesion: 0.11
Nodes (18): _businessNameCtrl, _countries, createState, dispose, _filterCountries, _filtered, _loadingCountries, _pageController (+10 more)

### Community 52 - "printer_setup_screen.dart"
Cohesion: 0.08
Nodes (23): PrinterDriver, printerForDriverProvider, createState, _devices, _devicesSub, _disconnectSavedPrinter, dispose, _driver (+15 more)

### Community 53 - "restore_recovery_test.dart"
Cohesion: 0.07
Nodes (31): Exception, FileSystemException, RestoreJournalFormatException, PendingRestoreException, RestoreFatalException, RestoreRolledBackException, SnapshotFormatException, backupOf (+23 more)

### Community 54 - "orders_dao.dart"
Cohesion: 0.06
Nodes (31): completedOrderCount, _escapeLike, getById, getItems, getTaxBreakdown, hasRestockedReturn, historyPage, incrementPrintCount (+23 more)

### Community 55 - "smoke_sale_test.dart"
Cohesion: 0.11
Nodes (15): EditableText, package:pos_app/app.dart, package:pos_app/features/cart/presentation/payment_screen.dart, package:pos_app/features/printing/domain/auto_print.dart, package:pos_app/shared/widgets/dismiss_keyboard.dart, container, db, sell (+7 more)

### Community 56 - "app.dart"
Cohesion: 0.04
Nodes (49): ChangeNotifier, GoRouter, appRedirect, AppScrollBehavior, featureRedirect, flags, getKeyboardDismissBehavior, location (+41 more)

### Community 57 - "package:pos_app/core/utils/currency_formatter.dart"
Cohesion: 0.10
Nodes (18): AutoPrintService, printOrder, _ref, buildReceiptText, dateFmt, join, lines, o (+10 more)

### Community 58 - "package:pos_app/features/cart/domain/cart_item.dart"
Cohesion: 0.06
Nodes (34): dart:math, _, CartCalculator, compute, _roundingModeFor, package:pos_app/core/utils/tax_calculator.dart, package:pos_app/features/cart/data/ticket_sequence.dart, package:pos_app/features/cart/domain/cart_calculator.dart (+26 more)

### Community 59 - "products_dao.dart"
Cohesion: 0.09
Nodes (21): deductStock, deleteCategory, getAllCategories, getById, getBySku, getComponents, replaceComponents, restock (+13 more)

### Community 60 - "csv_text.dart"
Cohesion: 0.07
Nodes (29): _bad, boolOf, cell, cellQuoted, _cells, _columns, CsvRow, CsvTable (+21 more)

### Community 61 - "support_screen.dart"
Cohesion: 0.08
Nodes (23): build, cs, gradient, icon, _InfoRow, label, onTap, _SectionHeader (+15 more)

### Community 62 - "receipt_printer.dart"
Cohesion: 0.07
Nodes (28): address, data, devices, DiscoveredPrinter, driver, escPosPrinterProvider, fmt, fromKey (+20 more)

### Community 63 - "Milestone 1: v1 (Foundation & Core POS)"
Cohesion: 0.07
Nodes (26): 1. State Management (Riverpod), 2. Navigation (GoRouter), 3. Data Layer (Drift & Hive), 4. Hardware Integration, Core Pillars, Data Flow, Directory Structure, Overview (+18 more)

### Community 64 - "home.dart"
Cohesion: 0.08
Nodes (30): demoDataServiceProvider, posCatalogProvider, posFilterProvider, CartScreen, _CartScreenState, categories, _CategoryRow, _Chip (+22 more)

### Community 65 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.07
Nodes (25): left, processReturn, refundableAmount, refunded, trackStock, transaction, package:flutter_test/flutter_test.dart, package:pos_app/core/utils/money.dart (+17 more)

### Community 66 - "build"
Cohesion: 0.11
Nodes (25): build, build, build, _loadTicket, build, build, Route /cart, Route /categories (+17 more)

### Community 67 - "usage_constants.dart"
Cohesion: 0.08
Nodes (25): kFeedbackAreaQuestion, kFeedbackAskAction, kFeedbackAskText, kFeedbackInstruction, kFeedbackMessageMaxLength, kFeedbackSupportRowSubtitle, kFeedbackSupportRowTitle, kOfflineFirstLine (+17 more)

### Community 68 - "pos_catalog_provider.dart"
Cohesion: 0.08
Nodes (24): AsyncValue, buildPosSearchIndex, cart, catalogEmpty, categoryId, committedMainUnits, favorites, favoritesOnly (+16 more)

### Community 69 - "migration_test.dart"
Cohesion: 0.10
Nodes (17): generated/schema.dart, databaseFile, dir, kDatabaseFileName, openConnection, package:drift_dev/api/migrations_common.dart, package:drift_dev/api/migrations_native.dart, package:drift/native.dart (+9 more)

### Community 70 - "featureOnProvider"
Cohesion: 0.10
Nodes (34): auditServiceProvider, featureOnProvider, onboardingCompleteProvider, shareFilesProvider, _PaymentScreenState, _placeOrder, HeldOrdersNotifier, holdCurrentCart (+26 more)

### Community 71 - "order_detail_screen.dart"
Cohesion: 0.08
Nodes (24): businessName, customer, data, db, _DetailData, does, fmt, isPartlyRefunded (+16 more)

### Community 72 - "receipt_pdf_service.dart"
Cohesion: 0.08
Nodes (23): baseStyle, billRow, boldStyle, buildReceiptPdf, bytes, customerName, _dataCell, dateFmt (+15 more)

### Community 73 - "package:pos_app/features/side_nav/presentation/side_nav.dart"
Cohesion: 0.08
Nodes (25): DateTimeRange?, reportProvider, reportSectionsProvider, build, createState, _customRange, DashboardScreen, _DashboardScreenState (+17 more)

### Community 74 - "snapshot_photos_test.dart"
Cohesion: 0.10
Nodes (19): package:sqlite3/sqlite3.dart, backupOf, dbFileIn, entriesOf, hasProduct, hivePathIn, _indexOf, live (+11 more)

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
Cohesion: 0.11
Nodes (17): ListTile, package:flutter/gestures.dart, package:pos_app/core/restart_notice.dart, package:pos_app/features/help/presentation/support_screen.dart, package:pos_app/features/review/review_providers.dart, package:pos_app/features/usage/presentation/usage_host.dart, package:pos_app/features/usage/presentation/usage_screen.dart, package:pos_app/features/usage/usage_constants.dart (+9 more)

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
Nodes (19): _apply, badgeColor, build, canDecrement, canIncrement, cs, _decrement, icon (+11 more)

### Community 85 - "products_provider.dart"
Cohesion: 0.06
Nodes (36): clearSearch, copyWith, favoritesOnly, isGrid, PosFilterNotifier, PosFilterState, PosSortMode, search (+28 more)

### Community 86 - "receipt_body.dart"
Cohesion: 0.10
Nodes (20): _BillRow, build, businessName, customer, data, _DataCell, fmt, _HeaderCell (+12 more)

### Community 87 - "usage_providers.dart"
Cohesion: 0.10
Nodes (19): ShareFiles, shareFilesWithOs, c, f, launch, link, LinkLauncher, on (+11 more)

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
Cohesion: 0.07
Nodes (24): canLaunch, kLinkFailureMessageDuration, _kSupportWhatsAppDigits, kSupportWhatsAppDisplay, kSupportWhatsAppUnavailable, launch, messenger, native (+16 more)

### Community 93 - "auto_print_test.dart"
Cohesion: 0.06
Nodes (34): _changes, copyWith, _db, dispose, error, _generation, hasMore, isLoading (+26 more)

### Community 94 - "Open POS"
Cohesion: 0.10
Nodes (19): Build from source, Contributing, Customers, Features, Get Open POS, License, macOS, Money and reports (+11 more)

### Community 95 - "customers_screen.dart"
Cohesion: 0.13
Nodes (15): IconData get, createState, dispose, _filterAndSort, icon, label, _openForm, _search (+7 more)

### Community 96 - "tokens.dart"
Cohesion: 0.11
Nodes (18): AppFonts, AppOpacity, heavy, lg, md, medium, mono, Radii (+10 more)

### Community 97 - "audit_log_screen.dart"
Cohesion: 0.20
Nodes (11): action, _ActionChip, _actionColor, _actionIcon, AuditLogScreen, auditLogsProvider, build, color (+3 more)

### Community 98 - "held_tickets_bar.dart"
Cohesion: 0.05
Nodes (56): AnimationController, _box, formatTicketNumber, heldOrdersBoxProvider, kTicketSeqKey, next, HeldOrder, cartSessionProvider (+48 more)

### Community 99 - "package:pos_app/features/usage/domain/usage_event.dart"
Cohesion: 0.12
Nodes (16): package:pos_app/features/usage/data/usage_counter.dart, package:pos_app/features/usage/domain/usage_event.dart, package:pos_app/features/usage/presentation/usage_route_counter.dart, package:pos_app/features/usage/usage_providers.dart, box, counter, main, now (+8 more)

### Community 100 - "features_step.dart"
Cohesion: 0.20
Nodes (9): build, FeaturesStep, kStartMinimal, kSuggestFooter, kSuggestSubtitle, kSuggestTitle, onStartMinimal, switches (+1 more)

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

### Community 107 - "package:pos_app/core/database/app_database.dart"
Cohesion: 0.08
Nodes (20): _db, log, orderPlaced, orderRefunded, orderVoided, settingChanged, taxOverridden, isLowStock (+12 more)

### Community 108 - "String?"
Cohesion: 0.07
Nodes (25): double?, ArticleDetailScreen, ArticleSection, build, category, cs, heading, icon (+17 more)

### Community 109 - "List"
Cohesion: 0.07
Nodes (26): TicketSequence, _Article, _ArticleCard, _articles, build, category, cs, description (+18 more)

### Community 110 - "StatelessWidget"
Cohesion: 0.09
Nodes (25): _CategoryChips, _Chip, _ExpenseTile, _TotalBar, cs, key_, _KeyChip, keys (+17 more)

### Community 111 - "printer_errors.dart"
Cohesion: 0.33
Nodes (5): friendlyPrinterError, known, _match, null, raw

### Community 112 - "render_receipt_image.dart"
Cohesion: 0.12
Nodes (15): dart:typed_data, doc, escPosPrintWidthDots, isCopy, kReceiptDpi, pages, _rasterise, renderReceiptImages (+7 more)

### Community 113 - "usage_host.dart"
Cohesion: 0.11
Nodes (17): _ask, child, _counter, createState, _disclosing, dispose, initState, kFeedbackAskDuration (+9 more)

### Community 114 - "returns_table.dart"
Cohesion: 0.12
Nodes (15): createdAt, id, orderId, OrderTaxOverrides, originalTax, overrideTax, reason, amount (+7 more)

### Community 115 - "bundled_fonts.dart"
Cohesion: 0.18
Nodes (10): bundledFontData, bundledPdfFont, cached, _fontData, future, jetBrainsMonoBold, jetBrainsMonoItalic, jetBrainsMonoRegular (+2 more)

### Community 116 - "cart_item.dart"
Cohesion: 0.12
Nodes (16): copyWith, grossAmount, isSecondaryUnit, isTaxable, lineDiscount, lineSubtotal, mainUnitQty, name (+8 more)

### Community 117 - "sales.dart"
Cohesion: 0.12
Nodes (15): int? customerId,
  int, line, loyaltyDiscount, paymentMethod, placeOrder, points, pointsRedeemed, pointsToEarn (+7 more)

### Community 118 - "order_summary.dart"
Cohesion: 0.09
Nodes (19): addColor, cs, fmt, label, onTap, ref, _showDiscountSheet, _showTaxPicker (+11 more)

### Community 119 - "State"
Cohesion: 0.23
Nodes (12): AppRoot, AppRootState, RestartNoticeOverlay, RestartNoticeOverlayState, CustomerPickerSheet, _CustomerPickerSheetState, _ReceiptMark, _ReceiptMarkState (+4 more)

### Community 120 - "schema.dart"
Cohesion: 0.12
Nodes (16): package:drift/internal/migrations.dart, schema_v10.dart, schema_v11.dart, schema_v12.dart, schema_v13.dart, schema_v14.dart, schema_v15.dart, schema_v4.dart (+8 more)

### Community 121 - "escpos_raster_test.dart"
Cohesion: 0.12
Nodes (15): package:image/image.dart, package:pos_app/core/utils/bundled_fonts.dart, package:pos_app/features/printing/domain/escpos_raster.dart, StateError, main, _blockPage, _countSequence, _firstRaster (+7 more)

### Community 122 - "side_nav.dart"
Cohesion: 0.12
Nodes (16): Feature, f, feature, featureForLocation, featureRedirect, group, icon, kFeaturesIntroFreshText (+8 more)

### Community 123 - "locale_country.dart"
Cohesion: 0.17
Nodes (11): base, byCode, countryForRegion, fromLocale, kFallbackCountry, _localeName, normalizeRegion, null (+3 more)

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

### Community 128 - "IntColumn get"
Cohesion: 0.11
Nodes (16): IntColumn get, componentProductId, compositeProductId, id, ProductComponents, quantity, createdAt, delta (+8 more)

### Community 129 - "store_profile_edit_screen.dart"
Cohesion: 0.12
Nodes (24): class, businessAddressProvider, businessNameProvider, businessPanProvider, businessPhoneProvider, businessTaglineProvider, _addressCtrl, build (+16 more)

### Community 130 - "loyalty_section.dart"
Cohesion: 0.17
Nodes (14): loyaltyEarnRateProvider, loyaltyEnabledProvider, loyaltyPointValueProvider, build, createState, dispose, _earnCtrl, earnRate (+6 more)

### Community 131 - "package:flutter/foundation.dart"
Cohesion: 0.08
Nodes (20): restartNoticeShowing, apple, _encode, _lineBreak, mailtoLink, query, smsLink, target (+12 more)

### Community 132 - "cart_line_item.dart"
Cohesion: 0.12
Nodes (14): CurrencyFormatter, CartItem, build, CartLineItem, fmt, icon, item, onPressed (+6 more)

### Community 133 - "restore_merge_marker.dart"
Cohesion: 0.10
Nodes (19): dart:convert, counts, d, deleteRestoreMergeMarker, finishPendingRestoreMerge, kRestoreMergeMarkerName, _markerFile, null (+11 more)

### Community 134 - "package:flutter/services.dart"
Cohesion: 0.11
Nodes (17): _devices, _discovery, dispose, _events, _found, _isSupported, _methods, _printImages (+9 more)

### Community 135 - "v1 Roadmap — Flutter Offline-First POS"
Cohesion: 0.13
Nodes (14): Architecture Decisions, Deferred to v2, Drift Schema — Full Table List (v1), Phase 0 — Foundation (No UI yet), Phase 1 — First-Run & Onboarding, Phase 2 — Product & Inventory Core, Phase 3 — Core Sales Loop, Phase 4 — Receipts & Hardware (+6 more)

### Community 136 - "dart:io"
Cohesion: 0.20
Nodes (7): dart:io, File, main, manifest, rules, main, main

### Community 137 - "usage_screen.dart"
Cohesion: 0.12
Nodes (16): BusinessType? get, UsageCounter, _businessType, _confirmReset, _counter, createState, dispose, initState (+8 more)

### Community 138 - "DateTime"
Cohesion: 0.18
Nodes (13): DateTime, BackupRepository, package:csv/csv.dart, bytesOf, db, legacyAllOrdersWithItems, legacyOrdersCsv, legacySalesReportCsv (+5 more)

### Community 139 - "product_tile.dart"
Cohesion: 0.08
Nodes (23): Color, bg, color, cs, icon, onDecrement, onIncrement, onTap (+15 more)

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
Cohesion: 0.28
Nodes (12): printerDeviceAddressProvider, printerDeviceNameProvider, printerDriverProvider, printerPaperWidthProvider, build, receiptPrinterProvider, build, _PrinterSetupScreenState (+4 more)

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

### Community 150 - "onboardingNotifierProvider"
Cohesion: 0.22
Nodes (10): build, onboardingNotifierProvider, _back, build, _finish, initState, _next, _selectCountry (+2 more)

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
Cohesion: 0.20
Nodes (9): bounds, box, fromLTWH, resolveShareOrigin, screen, shareOriginFor, view, widgetRect (+1 more)

### Community 155 - "receipt_roll_pdf_test.dart"
Cohesion: 0.18
Nodes (10): package:pdf/pdf.dart, package:pos_app/features/printing/domain/receipt_roll_pdf.dart, package:pos_app/features/printing/domain/render_receipt_image.dart, doc, fmt, main, order, _pageFormats (+2 more)

### Community 156 - "business_type.dart"
Cohesion: 0.20
Nodes (9): _app, BusinessType, kAlwaysSuggested, kPresets, label, parseBusinessType, presetSwitches, usageLabel (+1 more)

### Community 157 - "static const"
Cohesion: 0.25
Nodes (7): AndroidSdk, _cached, _methods, _read, sdkInt, static const, static Future

### Community 158 - "TextColumn get"
Cohesion: 0.12
Nodes (15): @DataClassName, DateTimeColumn get, capacity, createdAt, id, name, notes, Tables (+7 more)

### Community 159 - "customers_dao.dart"
Cohesion: 0.18
Nodes (10): addLoyaltyPoints, getAll, getById, namesFor, redeemLoyaltyPoints, search, upsert, watchAll (+2 more)

### Community 160 - "deviceRegionProvider"
Cohesion: 0.40
Nodes (5): deviceRegionProvider, _regionCountry, _loadCountries, OnboardingScreen, _OnboardingScreenState

### Community 161 - "review_prompter.dart"
Cohesion: 0.40
Nodes (4): kAndroidPackage, kAppStoreId, maybeRequestReview, openStoreListing

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

### Community 169 - "package:pos_app/shared/widgets/app_sheet.dart"
Cohesion: 0.12
Nodes (17): currencyCodeProvider, currencySymbolProvider, themeModeProvider, AppearanceSection, build, current, _options, _showThemePicker (+9 more)

### Community 170 - "Return"
Cohesion: 0.12
Nodes (13): formatPercent, formatPercentNumber, formatRateForEdit, formatRatePercent, kPercentDecimals, kPercentInputPattern, text, initials (+5 more)

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
Cohesion: 0.20
Nodes (10): @visibleForTesting, handleExitRequest, customersCsv, expensesCsv, productsCsv, writeOrdersCsv, writeSalesReportCsv, exactAmountText (+2 more)

### Community 175 - "package:pos_app/features/onboarding/domain/locale_country.dart"
Cohesion: 0.50
Nodes (3): package:pos_app/features/onboarding/data/country_repository.dart, package:pos_app/features/onboarding/domain/locale_country.dart, main

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

### Community 183 - "int get"
Cohesion: 0.33
Nodes (5): int get, billNo, displayNo, paymentLabel, String get

### Community 185 - "review_state_store.dart"
Cohesion: 0.08
Nodes (22): _box, _date, ensureFirstLaunch, markAnyPromptShown, markPrompted, mergeAfterRestore, mergeReviewStateAfterRestore, read (+14 more)

### Community 186 - "inventory_filter_bar.dart"
Cohesion: 0.10
Nodes (19): build, createState, customers, onSelect, _search, selectedId, build, _Chip (+11 more)

### Community 187 - "CLAUDE.md"
Cohesion: 0.50
Nodes (3): Database schema changes, graphify, Offline-first (non-negotiable)

### Community 188 - "app_version.dart"
Cohesion: 0.50
Nodes (3): kAppBuildNumber, kAppVersion, kAppVersionFull

### Community 193 - "country_step.dart"
Cohesion: 0.10
Nodes (18): build, BusinessNameStep, controller, build, countries, CountryStep, loading, onSearch (+10 more)

### Community 195 - "package:pos_app/features/printing/domain/receipt_printer.dart"
Cohesion: 0.22
Nodes (8): lastSdkNeedingLocationForBle, permissionsForScan, scanNeedsLocation, package:permission_handler/permission_handler.dart, package:pos_app/features/printing/domain/receipt_printer.dart, package:pos_app/features/printing/domain/scan_permissions.dart, bluetooth, main

### Community 196 - "tax_dao.dart"
Cohesion: 0.22
Nodes (8): getAll, getById, getRatesForProduct, setProductTaxes, upsertRate, watchActive, package:pos_app/core/database/tables/product_taxes_table.dart, _

### Community 197 - "usage_no_forbidden_fields_test.dart"
Cohesion: 0.07
Nodes (27): _grammar.dart, build, BusinessTypeStep, kBusinessTypeSubtitle, kBusinessTypeTitle, onPick, selected, countOf (+19 more)

### Community 198 - "tables_dao.dart"
Cohesion: 0.25
Nodes (7): deleteById, getAll, getById, upsert, watchAll, package:pos_app/core/database/tables/tables_table.dart, _

### Community 199 - "audit_dao.dart"
Cohesion: 0.29
Nodes (6): log, queryByDateRange, queryByEntity, watchRecent, package:pos_app/core/database/tables/audit_log_table.dart, _

## Knowledge Gaps
- **4108 isolated node(s):** `refresh`, `router`, `flags`, `location`, `getKeyboardDismissBehavior` (+4103 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **4 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Return` connect `Return` to `app_database.dart`, `restore_merge_marker.dart`, `tron_border.dart`, `package:flutter_riverpod/flutter_riverpod.dart`, `usage_counter.dart`, `usage_summary.dart`, `calc_oracle.dart`, `package:drift/drift.dart`, `DataClass`, `unit_conversion.dart`, `render_receipt.dart`, `app.dart`, `review_state_store.dart`, `csv_text.dart`, `receipt_printer.dart`, `pos_catalog_provider.dart`, `receipt_pdf_service.dart`, `money.dart`, `products_provider.dart`, `usage_providers.dart`, `receipt_roll_pdf.dart`, `escpos_raster.dart`, `printer_errors.dart`, `render_receipt_image.dart`, `bundled_fonts.dart`, `escpos_raster_test.dart`, `side_nav.dart`, `locale_country.dart`, `review_policy.dart`?**
  _High betweenness centrality (0.033) - this node is a cross-community bridge._
- **Why does `AppDatabase` connect `AppDatabase` to `app_database.dart`, `IntColumn get`, `DateTime`, `usage_screen_test.dart`, `package:flutter_riverpod/flutter_riverpod.dart`, `report_figures_test.dart`, `query_plan_test.dart`, `package:drift/drift.dart`, `backup_repository.dart`, `inventory_dao.dart`, `backup/share_origin_test.dart`, `smoke_sale_test.dart`, `app.dart`, `package:pos_app/features/cart/domain/cart_item.dart`, `package:flutter_test/flutter_test.dart`, `usage_no_forbidden_fields_test.dart`, `usage_host_test.dart`, `auto_print_test.dart`, `payment_screen_test.dart`, `package:pos_app/core/database/app_database.dart`?**
  _High betweenness centrality (0.013) - this node is a cross-community bridge._
- **Why does `_` connect `_` to `restore_merge_marker.dart`, `dart:io`, `String?`, `List`, `restore_recovery_test.dart`, `restore_merge_marker_test.dart`, `static const`?**
  _High betweenness centrality (0.004) - this node is a cross-community bridge._
- **What connects `refresh`, `router`, `flags` to the rest of the system?**
  _4108 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `app_database.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.007692307692307693 - nodes in this community are weakly interconnected._
- **Should `schema_v15.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.01639344262295082 - nodes in this community are weakly interconnected._
- **Should `schema_v11.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.017391304347826087 - nodes in this community are weakly interconnected._