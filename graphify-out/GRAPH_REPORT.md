# Graph Report - agent-a56494ea87981aeba  (2026-11-26)

## Corpus Check
- 346 files · ~272,992 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 5681 nodes · 9261 edges · 198 communities (191 shown, 7 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `c92c0654`
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
- package:pos_app/core/database/app_database.dart
- Table
- usage_ask_test.dart
- customer_card.dart
- package:pos_app/core/providers/hive_provider.dart
- usage_counter.dart
- report_data.dart
- cart_notifier.dart
- usage_summary.dart
- restore_merge_marker_test.dart
- usage_ask_controller.dart
- calc_oracle.dart
- package:flutter_riverpod/flutter_riverpod.dart
- most_sold_test.dart
- features_screen.dart
- expenses_screen.dart
- customers_provider.dart
- package:pos_app/core/theme/tokens.dart
- ConsumerWidget
- auto_print_test.dart
- DataClass
- sell_screen_rebuild_test.dart
- String?
- product_form_screen.dart
- ConsumerStatefulWidget
- app_root.dart
- databaseProvider
- backup_repository.dart
- dashboard_body.dart
- feature_flags.dart
- orders_screen.dart
- backup_screen.dart
- products_screen.dart
- audit_dao.dart
- package:flutter_test/flutter_test.dart
- tax_settings_screen.dart
- snapshot_providers.dart
- onboarding_screen.dart
- printer_setup_screen.dart
- restore_recovery_test.dart
- orders_dao.dart
- inventory_screen.dart
- app.dart
- package:pos_app/core/utils/currency_formatter.dart
- package:pos_app/features/cart/domain/cart_item.dart
- products_dao.dart
- csv_text.dart
- StatelessWidget
- receipt_printer.dart
- Milestone 1: v1 (Foundation & Core POS)
- home.dart
- place_order.dart
- build
- usage_constants.dart
- pos_catalog_provider.dart
- migration_test.dart
- featureOnProvider
- order_detail_screen.dart
- receipt_pdf_service.dart
- dashboard_screen.dart
- snapshot_photos_test.dart
- orders_table.dart
- money.dart
- payment_screen.dart
- receipt_screen.dart
- review_controller_test.dart
- tax_group_members_table.dart
- tables_screen.dart
- products_table.dart
- held_order.dart
- inventory_card.dart
- products_provider.dart
- receipt_body.dart
- usage_providers.dart
- pos_filter_provider.dart
- app_theme.dart
- _
- cart_summary.dart
- support_contact.dart
- order_history.dart
- Open POS
- customers_screen.dart
- tokens.dart
- audit_log_screen.dart
- held_tickets_bar.dart
- settings_screen.dart
- features_step.dart
- receipt_roll_pdf.dart
- snapshot_service_test.dart
- restore_merge_test.dart
- payment_screen_test.dart
- escpos_raster.dart
- onboarding_notifier.dart
- package:pos_app/core/providers/database_provider.dart
- article_detail_screen.dart
- List
- confirm_step.dart
- Return
- render_receipt_image.dart
- usage_host.dart
- returns_table.dart
- bundled_fonts.dart
- cart_item.dart
- sales.dart
- order_summary.dart
- int?
- schema.dart
- escpos_raster_test.dart
- _BackupScreenState
- locale_country.dart
- onboarding_state.dart
- package:flutter/services.dart
- thermal_plugin_printer.dart
- review_policy.dart
- IntColumn get
- store_profile_edit_screen.dart
- loyalty_section.dart
- package:flutter/foundation.dart
- cart_line_item.dart
- restore_merge_marker.dart
- star_printer.dart
- v1 Roadmap — Flutter Offline-First POS
- _StoreProfileEditScreenState
- dart:convert
- DateTime
- product_tile.dart
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
- onboardingNotifierProvider
- _grammar.dart
- tax_rates_table.dart
- package:intl/intl.dart
- share_origin.dart
- receipt_roll_pdf_test.dart
- business_type.dart
- country_repository.dart
- TextColumn get
- customers_dao.dart
- deviceRegionProvider
- link_uris_test.dart
- country_default.dart
- unit_conversion.dart
- @immutable
- render_receipt.dart
- audit_log_table.dart
- categories_table.dart
- order_taxes_table.dart
- package:pos_app/shared/widgets/app_sheet.dart
- percent.dart
- VoidCallback?
- Projects Dependencies
- External Integrations
- utils/share_origin_test.dart
- package:pos_app/features/onboarding/domain/locale_country.dart
- package:pos_app/features/orders/domain/order_number.dart
- support_contact_test.dart
- Project Conventions
- Technology Stack
- StateNotifier
- usage_event.dart
- _DeflatedFile
- int get
- install_macos.sh
- review_state_store.dart
- inventory_filter_bar.dart
- CLAUDE.md
- app_version.dart
- SettingsNotifier
- _FileSink
- currencies.dart
- @rebuzzpos
- package:flutter/material.dart
- tax_dao.dart
- usage_screen_test.dart
- tables_dao.dart
- ReportPeriod

## God Nodes (most connected - your core abstractions)
1. `AppDatabase` - 53 edges
2. `featureOnProvider` - 41 edges
3. `Return` - 35 edges
4. `databaseProvider` - 35 edges
5. `settingsProvider` - 28 edges
6. `_` - 28 edges
7. `cartSessionProvider` - 28 edges
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

## Communities (198 total, 7 thin omitted)

### Community 0 - "app_database.dart"
Cohesion: 0.01
Nodes (259): class OrderTaxOverride extends, class ProductComponent extends, ColumnFilters, ColumnOrderings, backfillInvoiceNumbers, backfillV14, currentSchemaVersion, migration (+251 more)

### Community 1 - "schema_v15.dart"
Cohesion: 0.02
Nodes (128): Index, action, actualTableName, address, _alias, aliasedName, allSchemaEntities, allTables (+120 more)

### Community 2 - "schema_v11.dart"
Cohesion: 0.02
Nodes (113): ProductTaxes, action, actualTableName, address, _alias, aliasedName, allSchemaEntities, allTables (+105 more)

### Community 3 - "schema_v14.dart"
Cohesion: 0.02
Nodes (112): ProductComponents, TaxGroupMembers, action, actualTableName, address, _alias, aliasedName, allSchemaEntities (+104 more)

### Community 4 - "schema_v10.dart"
Cohesion: 0.02
Nodes (111): ProductModifiers, TaxGroups, action, actualTableName, address, _alias, aliasedName, allSchemaEntities (+103 more)

### Community 5 - "schema_v12.dart"
Cohesion: 0.02
Nodes (111): GeneratedColumn, Returns, action, actualTableName, address, _alias, aliasedName, allSchemaEntities (+103 more)

### Community 6 - "schema_v13.dart"
Cohesion: 0.02
Nodes (112): Customers, StockAdjustments, action, actualTableName, address, _alias, aliasedName, allSchemaEntities (+104 more)

### Community 7 - "schema_v9.dart"
Cohesion: 0.02
Nodes (107): OrderTaxOverrides, Products, ProductVariants, action, actualTableName, address, _alias, aliasedName (+99 more)

### Community 8 - "schema_v8.dart"
Cohesion: 0.02
Nodes (107): ExpenseCategories, Tables, action, actualTableName, address, _alias, aliasedName, allSchemaEntities (+99 more)

### Community 9 - "schema_v7.dart"
Cohesion: 0.02
Nodes (105): Expenses, OrderTaxes, action, actualTableName, address, _alias, aliasedName, allSchemaEntities (+97 more)

### Community 10 - "schema_v4.dart"
Cohesion: 0.02
Nodes (107): AuditLog, Orders, action, actualTableName, address, _alias, aliasedName, allSchemaEntities (+99 more)

### Community 11 - "schema_v6.dart"
Cohesion: 0.02
Nodes (104): Categories, OrderItems, TaxRates, action, actualTableName, address, _alias, aliasedName (+96 more)

### Community 12 - "snapshot_service.dart"
Cohesion: 0.02
Nodes (87): InputFileStream, _absentSuffix, add, _addDeflated, _addStored, assertNoPendingRestore, _bakSuffix, _baseName (+79 more)

### Community 13 - "hive_provider.dart"
Cohesion: 0.02
Nodes (90): autoBackupEnabled, autoBackupLastAt, _box, build, businessAddress, businessName, businessNameOrDefault, businessPan (+82 more)

### Community 14 - "package:pos_app/core/database/app_database.dart"
Cohesion: 0.03
Nodes (112): _, @DriftDatabase, AppDatabase, AuditService, _db, log, orderPlaced, orderRefunded (+104 more)

### Community 15 - "Table"
Cohesion: 0.06
Nodes (66): Table, TableInfo, Customers, OrderItems, OrderTaxes, OrderTaxOverrides, ProductVariants, Returns (+58 more)

### Community 16 - "usage_ask_test.dart"
Cohesion: 0.05
Nodes (39): bool get, appVersion, _guard, _inFlight, onReceiptDismissed, prompter, ReviewCheck, ReviewController (+31 more)

### Community 17 - "customer_card.dart"
Cohesion: 0.11
Nodes (16): Color, _Badge, bg, customer, CustomerCard, fg, icon, label (+8 more)

### Community 18 - "package:pos_app/core/providers/hive_provider.dart"
Cohesion: 0.03
Nodes (80): Box, dart:typed_data, Directory, AutoPrintService, printOrder, _ref, _box, _kFavoriteProductIds (+72 more)

### Community 19 - "usage_counter.dart"
Cohesion: 0.04
Nodes (54): bool?, DateTime? get, after, askedVersion, _box, countingEnabled, countingOn, _counts (+46 more)

### Community 20 - "report_data.dart"
Cohesion: 0.04
Nodes (51): all, avgOrder, changes, chartDates, chartHighlightIndex, chartTitle, chartTotals, costIsIncomplete (+43 more)

### Community 21 - "cart_notifier.dart"
Cohesion: 0.06
Nodes (33): ticketSequenceProvider, CartSession, addItem, addProduct, addProductInSecondaryUnit, CartSessionNotifier, clear, clearItems (+25 more)

### Community 22 - "usage_summary.dart"
Cohesion: 0.04
Nodes (49): appInfo, appVersion, buildUsageSummary, bump, businessType, canSendUsageSummary, chars, count (+41 more)

### Community 23 - "restore_merge_marker_test.dart"
Cohesion: 0.06
Nodes (33): databaseFile, dir, kDatabaseFileName, openConnection, main, startup, fatal, notice (+25 more)

### Community 24 - "usage_ask_controller.dart"
Cohesion: 0.11
Nodes (17): afterReviewCheck, appVersion, counter, dispose, evaluate, fossBuild, _inFlight, kFossBuild (+9 more)

### Community 25 - "calc_oracle.dart"
Cohesion: 0.04
Nodes (46): BigInt, int? discPermille,
  int, balance, base, baseOnHalfCent, bp, cents, d (+38 more)

### Community 26 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.04
Nodes (64): CartNotifier get, db, add, _allowQty, _cart, _committed, _container, _messenger (+56 more)

### Community 27 - "most_sold_test.dart"
Cohesion: 0.06
Nodes (30): int tea,, package:pos_app/core/services/demo_data_service.dart, QueryInterceptor, ../../_support/query_recorder.dart, db, expectIndexed, from, fullScan (+22 more)

### Community 28 - "features_screen.dart"
Cohesion: 0.05
Nodes (44): Feature, featureFlagsProvider, featuresIntroFreshProvider, featuresIntroSeenProvider, stockOffSinceProvider, build, _confirmBody, createState (+36 more)

### Community 29 - "expenses_screen.dart"
Cohesion: 0.05
Nodes (43): _amountCtrl, build, categories, category, _CategoryChips, _categoryId, _check, _Chip (+35 more)

### Community 30 - "customers_provider.dart"
Cohesion: 0.22
Nodes (8): _LoyaltyGate, cartCustomerProvider, customerId, customerNamesKey, customerNamesProvider, customers, ref, watch

### Community 31 - "package:pos_app/core/theme/tokens.dart"
Cohesion: 0.12
Nodes (14): build, cs, highlightIndex, labels, MiniBarChart, values, build, emphasis (+6 more)

### Community 32 - "ConsumerWidget"
Cohesion: 0.06
Nodes (49): ConsumerWidget, defaultTaxIdProvider, invoicePrefixProvider, settingsBoxProvider, settingsProvider, themeModeProvider, cartMainUnitQtyProvider, _ClearCartButton (+41 more)

### Community 33 - "auto_print_test.dart"
Cohesion: 0.12
Nodes (15): Object?, box, db, devices, failWith, main, makeContainer, printed (+7 more)

### Community 34 - "DataClass"
Cohesion: 0.09
Nodes (39): Insertable, OrderNumberX, UpdateCompanion, AuditLogCompanion, AuditLogData, CategoriesCompanion, Category, Customer (+31 more)

### Community 35 - "sell_screen_rebuild_test.dart"
Cohesion: 0.05
Nodes (38): AppBar, CustomPaint, FilterChip, GridView, product, stock, units, ListView (+30 more)

### Community 36 - "String?"
Cohesion: 0.12
Nodes (15): double?, IconData?, action, AppEmptyState, build, icon, subtitle, title (+7 more)

### Community 37 - "product_form_screen.dart"
Cohesion: 0.05
Nodes (36): _categoryId, _ComponentEntry, _components, _conversionCtrl, createState, _delete, didChangeDependencies, dispose (+28 more)

### Community 38 - "ConsumerStatefulWidget"
Cohesion: 0.09
Nodes (26): ConsumerStatefulWidget, lowStockThresholdProvider, CartScreen, PaymentScreen, _fitsStock, CustomersScreen, _ExpenseForm, build (+18 more)

### Community 39 - "app_root.dart"
Cohesion: 0.06
Nodes (30): autoBackupDelay, _autoBackupRun, autoBackupScheduledForTest, _autoBackupTimer, build, child, _closeDatabaseForExit, _container (+22 more)

### Community 40 - "databaseProvider"
Cohesion: 0.05
Nodes (46): databaseProvider, _addressCtrl, build, createState, customer, CustomerForm, _CustomerFormState, _delete (+38 more)

### Community 41 - "backup_repository.dart"
Cohesion: 0.05
Nodes (43): @visibleForTesting, added, _csvEol, csvImportExplanation, CsvImportReport, customersCsv, db, expensesCsv (+35 more)

### Community 42 - "dashboard_body.dart"
Cohesion: 0.11
Nodes (17): ReportData, build, _buildKpiRows, cs, DashboardBody, data, _fmt, isCustomRange (+9 more)

### Community 43 - "feature_flags.dart"
Cohesion: 0.06
Nodes (34): autoPrint, bundles, costProfit, csvImportExport, customers, dashboardExtras, defaultOn, defaults (+26 more)

### Community 44 - "orders_screen.dart"
Cohesion: 0.07
Nodes (32): orderHistoryProvider, _body, _clearQuery, createState, cs, customerName, _debounce, dispose (+24 more)

### Community 45 - "backup_screen.dart"
Cohesion: 0.07
Nodes (26): _BackupTile, _buildInfoCard, color, _confirmAndImport, _createFullBackup, createState, cs, files (+18 more)

### Community 46 - "products_screen.dart"
Cohesion: 0.08
Nodes (23): categories, _CategoryChips, categoryName, _Chip, createState, cs, dispose, fmt (+15 more)

### Community 47 - "audit_dao.dart"
Cohesion: 0.10
Nodes (24): @DriftAccessor, _$AuditDaoMixin, _$CustomersDaoMixin, DatabaseAccessor, _$ExpensesDaoMixin, _$InventoryDaoMixin, AuditDao, log (+16 more)

### Community 48 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.04
Nodes (45): dart:io, FormatException, package:flutter_test/flutter_test.dart, package:pos_app/core/app_version.dart, package:pos_app/features/backup/data/backup_repository.dart, package:pos_app/features/backup/data/csv_text.dart, package:pos_app/features/backup/presentation/backup_screen.dart, package:pos_app/features/products/domain/stock_level.dart (+37 more)

### Community 49 - "tax_settings_screen.dart"
Cohesion: 0.12
Nodes (17): FormState, createState, dispose, existing, _formKey, _inclusionType, _nameCtrl, onAdd (+9 more)

### Community 50 - "snapshot_providers.dart"
Cohesion: 0.07
Nodes (27): autoBackupDir, autoBackupLastError, create, createAndShare, defaultHiveBoxPaths, docs, inspect, kAutoBackupInterval (+19 more)

### Community 51 - "onboarding_screen.dart"
Cohesion: 0.11
Nodes (18): _businessNameCtrl, _countries, createState, dispose, _filterCountries, _filtered, initState, _loadingCountries (+10 more)

### Community 52 - "printer_setup_screen.dart"
Cohesion: 0.07
Nodes (29): PrinterDriver, lastSdkNeedingLocationForBle, permissionsForScan, scanNeedsLocation, createState, _devices, _devicesSub, _disconnectSavedPrinter (+21 more)

### Community 53 - "restore_recovery_test.dart"
Cohesion: 0.07
Nodes (31): Exception, FileSystemException, RestoreJournalFormatException, PendingRestoreException, RestoreFatalException, RestoreRolledBackException, SnapshotFormatException, backupOf (+23 more)

### Community 54 - "orders_dao.dart"
Cohesion: 0.06
Nodes (31): completedOrderCount, _escapeLike, getById, getItems, getTaxBreakdown, hasRestockedReturn, historyPage, incrementPrintCount (+23 more)

### Community 55 - "inventory_screen.dart"
Cohesion: 0.13
Nodes (14): Iterable, createState, dispose, _filter, _filtered, filterInventoryProducts, list, _search (+6 more)

### Community 56 - "app.dart"
Cohesion: 0.03
Nodes (61): ChangeNotifier, EditableText, GoRouter, appRedirect, AppScrollBehavior, featureRedirect, flags, getKeyboardDismissBehavior (+53 more)

### Community 57 - "package:pos_app/core/utils/currency_formatter.dart"
Cohesion: 0.12
Nodes (15): buildReceiptText, dateFmt, join, lines, o, package:pos_app/core/utils/currency_formatter.dart, package:pos_app/features/receipts/domain/receipt_labels.dart, package:pos_app/features/receipts/presentation/receipt_body.dart (+7 more)

### Community 58 - "package:pos_app/features/cart/domain/cart_item.dart"
Cohesion: 0.07
Nodes (30): dart:math, _, CartCalculator, compute, _roundingModeFor, package:pos_app/core/utils/tax_calculator.dart, package:pos_app/features/cart/domain/cart_calculator.dart, package:pos_app/features/cart/domain/cart_item.dart (+22 more)

### Community 59 - "products_dao.dart"
Cohesion: 0.09
Nodes (21): deductStock, deleteCategory, getAllCategories, getById, getBySku, getComponents, replaceComponents, restock (+13 more)

### Community 60 - "csv_text.dart"
Cohesion: 0.07
Nodes (29): _bad, boolOf, cell, cellQuoted, _cells, _columns, CsvRow, CsvTable (+21 more)

### Community 61 - "StatelessWidget"
Cohesion: 0.10
Nodes (22): _ExpenseTile, _TotalBar, build, cs, gradient, icon, _InfoRow, label (+14 more)

### Community 62 - "receipt_printer.dart"
Cohesion: 0.07
Nodes (28): address, data, devices, DiscoveredPrinter, driver, escPosPrinterProvider, fmt, fromKey (+20 more)

### Community 63 - "Milestone 1: v1 (Foundation & Core POS)"
Cohesion: 0.07
Nodes (26): 1. State Management (Riverpod), 2. Navigation (GoRouter), 3. Data Layer (Drift & Hive), 4. Hardware Integration, Core Pillars, Data Flow, Directory Structure, Overview (+18 more)

### Community 64 - "home.dart"
Cohesion: 0.08
Nodes (28): demoDataServiceProvider, posCatalogProvider, posFilterProvider, categories, _CategoryRow, _Chip, createState, dispose (+20 more)

### Community 65 - "place_order.dart"
Cohesion: 0.08
Nodes (24): _, compoundTax, invoiceTax, lineItemTax, priceBeforeTax, _round, TaxCalculator, components (+16 more)

### Community 66 - "build"
Cohesion: 0.11
Nodes (24): build, build, build, build, build, Route /cart, Route /categories, Route /customers (+16 more)

### Community 67 - "usage_constants.dart"
Cohesion: 0.08
Nodes (25): kFeedbackAreaQuestion, kFeedbackAskAction, kFeedbackAskText, kFeedbackInstruction, kFeedbackMessageMaxLength, kFeedbackSupportRowSubtitle, kFeedbackSupportRowTitle, kOfflineFirstLine (+17 more)

### Community 68 - "pos_catalog_provider.dart"
Cohesion: 0.08
Nodes (24): AsyncValue, buildPosSearchIndex, cart, catalogEmpty, categoryId, committedMainUnits, favorites, favoritesOnly (+16 more)

### Community 69 - "migration_test.dart"
Cohesion: 0.14
Nodes (12): generated/schema.dart, package:drift_dev/api/migrations_common.dart, package:drift_dev/api/migrations_native.dart, package:drift/native.dart, SchemaVerifier, indexes, main, seedV13 (+4 more)

### Community 70 - "featureOnProvider"
Cohesion: 0.12
Nodes (45): ConsumerState, auditServiceProvider, featureOnProvider, onboardingCompleteProvider, build, CartDetailScreen, _CartScreenState, build (+37 more)

### Community 71 - "order_detail_screen.dart"
Cohesion: 0.08
Nodes (26): build, businessName, customer, data, db, _DetailData, does, fmt (+18 more)

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

### Community 79 - "review_controller_test.dart"
Cohesion: 0.13
Nodes (14): box, calls, controller, eligible, main, maybeRequestReview, _Mode, now (+6 more)

### Community 80 - "tax_group_members_table.dart"
Cohesion: 0.14
Nodes (13): primaryKey, productId, ProductTaxes, taxRateId, groupId, primaryKey, sortOrder, TaxGroupMembers (+5 more)

### Community 81 - "tables_screen.dart"
Cohesion: 0.06
Nodes (36): activeHeldOrdersProvider, build, occupied, onSelect, _pickTable, selectedId, session, _TablePickerSheet (+28 more)

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
Nodes (20): _BillRow, build, businessName, customer, data, _DataCell, fmt, _HeaderCell (+12 more)

### Community 87 - "usage_providers.dart"
Cohesion: 0.10
Nodes (19): dart:ui, ShareFiles, shareFilesWithOs, UsageCounter, c, f, launch, link (+11 more)

### Community 88 - "pos_filter_provider.dart"
Cohesion: 0.14
Nodes (13): clearSearch, copyWith, favoritesOnly, isGrid, PosSortMode, search, selectedCategoryId, setCategory (+5 more)

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

### Community 98 - "held_tickets_bar.dart"
Cohesion: 0.07
Nodes (31): AnimationController, HeldOrder, archive, archiveAll, archivedHeldOrdersProvider, _box, build, delete (+23 more)

### Community 99 - "settings_screen.dart"
Cohesion: 0.15
Nodes (12): build, SettingsScreen, package:pos_app/features/settings/presentation/widgets/appearance_section.dart, package:pos_app/features/settings/presentation/widgets/backup_section.dart, package:pos_app/features/settings/presentation/widgets/currency_section.dart, package:pos_app/features/settings/presentation/widgets/danger_section.dart, package:pos_app/features/settings/presentation/widgets/inventory_section.dart, package:pos_app/features/settings/presentation/widgets/loyalty_section.dart (+4 more)

### Community 100 - "features_step.dart"
Cohesion: 0.18
Nodes (10): build, FeaturesStep, kStartMinimal, kSuggestFooter, kSuggestSubtitle, kSuggestTitle, kSuggestWhy, onStartMinimal (+2 more)

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
Cohesion: 0.12
Nodes (16): FeatureFlags get, back, build, _defaults, next, _passed, _saveProfile, setBusinessName (+8 more)

### Community 107 - "package:pos_app/core/providers/database_provider.dart"
Cohesion: 0.05
Nodes (36): _db, DemoDataService, seed, _seedDatabase, _settings, build, _confirmReset, package:pos_app/core/providers/database_provider.dart (+28 more)

### Community 108 - "article_detail_screen.dart"
Cohesion: 0.11
Nodes (17): ArticleDetailScreen, ArticleSection, build, category, cs, heading, icon, readTime (+9 more)

### Community 109 - "List"
Cohesion: 0.08
Nodes (23): _Article, _ArticleCard, _articles, build, category, cs, description, icon (+15 more)

### Community 110 - "confirm_step.dart"
Cohesion: 0.11
Nodes (15): build, children, ConfirmStep, icon, isLast, kTaxesOffSummary, label, state (+7 more)

### Community 111 - "Return"
Cohesion: 0.15
Nodes (10): initials, name, null, stockCapFor, friendlyPrinterError, known, _match, null (+2 more)

### Community 112 - "render_receipt_image.dart"
Cohesion: 0.17
Nodes (11): doc, escPosPrintWidthDots, isCopy, kReceiptDpi, pages, _rasterise, renderReceiptImages, renderTestPageImages (+3 more)

### Community 113 - "usage_host.dart"
Cohesion: 0.07
Nodes (27): AppLifecycleListener?, dart:async, Duration, DatabaseExitGuard, dispose, handleExitRequest, _listener, timeout (+19 more)

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
Cohesion: 0.12
Nodes (16): addColor, cs, fmt, label, onTap, ref, _showDiscountSheet, _showTaxPicker (+8 more)

### Community 119 - "int?"
Cohesion: 0.12
Nodes (20): int?, AppRoot, AppRootState, RestartNoticeOverlay, RestartNoticeOverlayState, build, createState, CustomerPickerSheet (+12 more)

### Community 120 - "schema.dart"
Cohesion: 0.12
Nodes (16): package:drift/internal/migrations.dart, schema_v10.dart, schema_v11.dart, schema_v12.dart, schema_v13.dart, schema_v14.dart, schema_v15.dart, schema_v4.dart (+8 more)

### Community 121 - "escpos_raster_test.dart"
Cohesion: 0.15
Nodes (12): package:image/image.dart, StateError, _blockPage, _countSequence, _firstRaster, found, fromList, gsV (+4 more)

### Community 122 - "_BackupScreenState"
Cohesion: 0.33
Nodes (10): autoBackupEnabledProvider, autoBackupLastAtProvider, backupRepositoryProvider, snapshotCoordinatorProvider, _AutoBackupTile, BackupScreen, _BackupScreenState, build (+2 more)

### Community 123 - "locale_country.dart"
Cohesion: 0.15
Nodes (12): base, byCode, countryForRegion, fromLocale, kFallbackCountry, kUnmatchedCountry, _localeName, normalizeRegion (+4 more)

### Community 124 - "onboarding_state.dart"
Cohesion: 0.10
Nodes (19): businessName, businessType, copyWith, country, current, defaultTaxesOn, isLast, kOnboardingSteps (+11 more)

### Community 125 - "package:flutter/services.dart"
Cohesion: 0.09
Nodes (20): AndroidSdk, _cached, _methods, _read, sdkInt, _devices, dispose, _methods (+12 more)

### Community 126 - "thermal_plugin_printer.dart"
Cohesion: 0.10
Nodes (18): _connect, _connectTimeout, devices, _disconnect, _ftp, _pluginDevice, _printPages, printReceipt (+10 more)

### Community 127 - "review_policy.dart"
Cohesion: 0.12
Nodes (15): at, first, firstLaunchAt, kMinDaysBetweenAnyPrompts, kReviewMinCompletedSales, kReviewMinDaysBetweenPrompts, kReviewMinDaysSinceInstall, last (+7 more)

### Community 128 - "IntColumn get"
Cohesion: 0.10
Nodes (19): IntColumn get, getAdjustmentsForProduct, logAdjustment, watchLowStock, componentProductId, compositeProductId, id, ProductComponents (+11 more)

### Community 129 - "store_profile_edit_screen.dart"
Cohesion: 0.13
Nodes (14): class, _addressCtrl, build, createState, dispose, _initialised, _label, _loading (+6 more)

### Community 130 - "loyalty_section.dart"
Cohesion: 0.17
Nodes (14): loyaltyEarnRateProvider, loyaltyEnabledProvider, loyaltyPointValueProvider, build, createState, dispose, _earnCtrl, earnRate (+6 more)

### Community 131 - "package:flutter/foundation.dart"
Cohesion: 0.15
Nodes (11): restartNoticeShowing, apple, _encode, _lineBreak, mailtoLink, query, smsLink, target (+3 more)

### Community 132 - "cart_line_item.dart"
Cohesion: 0.12
Nodes (14): CurrencyFormatter, CartItem, build, CartLineItem, fmt, icon, item, onPressed (+6 more)

### Community 133 - "restore_merge_marker.dart"
Cohesion: 0.13
Nodes (14): counts, d, deleteRestoreMergeMarker, finishPendingRestoreMerge, kRestoreMergeMarkerName, _markerFile, null, path (+6 more)

### Community 134 - "star_printer.dart"
Cohesion: 0.10
Nodes (19): SppPrinter, _devices, _discovery, dispose, _events, _found, _isSupported, _methods (+11 more)

### Community 135 - "v1 Roadmap — Flutter Offline-First POS"
Cohesion: 0.13
Nodes (14): Architecture Decisions, Deferred to v2, Drift Schema — Full Table List (v1), Phase 0 — Foundation (No UI yet), Phase 1 — First-Run & Onboarding, Phase 2 — Product & Inventory Core, Phase 3 — Core Sales Loop, Phase 4 — Receipts & Hardware (+6 more)

### Community 136 - "_StoreProfileEditScreenState"
Cohesion: 0.42
Nodes (10): businessAddressProvider, businessNameProvider, businessPanProvider, businessPhoneProvider, businessTaglineProvider, didChangeDependencies, _StoreProfileEditScreenState, build (+2 more)

### Community 137 - "dart:convert"
Cohesion: 0.22
Nodes (8): dart:convert, _box, formatTicketNumber, heldOrdersBoxProvider, kTicketSeqKey, next, TicketSequence, _MemorySequence

### Community 138 - "DateTime"
Cohesion: 0.18
Nodes (13): DateTime, BackupRepository, package:csv/csv.dart, bytesOf, db, legacyAllOrdersWithItems, legacyOrdersCsv, legacySalesReportCsv (+5 more)

### Community 139 - "product_tile.dart"
Cohesion: 0.06
Nodes (30): ColorScheme, bg, color, cs, icon, onDecrement, onIncrement, onTap (+22 more)

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

### Community 150 - "onboardingNotifierProvider"
Cohesion: 0.25
Nodes (9): build, onboardingNotifierProvider, _back, build, _finish, _next, _selectCountry, _skip (+1 more)

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

### Community 156 - "business_type.dart"
Cohesion: 0.20
Nodes (9): _app, BusinessType, kAlwaysSuggested, kPresets, label, parseBusinessType, presetSwitches, usageLabel (+1 more)

### Community 157 - "country_repository.dart"
Cohesion: 0.33
Nodes (5): _cache, CountryRepository, load, package:pos_app/features/onboarding/domain/country_default.dart, static List

### Community 158 - "TextColumn get"
Cohesion: 0.12
Nodes (15): @DataClassName, DateTimeColumn get, capacity, createdAt, id, name, notes, Tables (+7 more)

### Community 159 - "customers_dao.dart"
Cohesion: 0.18
Nodes (10): addLoyaltyPoints, getAll, getById, namesFor, redeemLoyaltyPoints, search, upsert, watchAll (+2 more)

### Community 160 - "deviceRegionProvider"
Cohesion: 0.40
Nodes (5): deviceRegionProvider, _regionCountry, _loadCountries, OnboardingScreen, _OnboardingScreenState

### Community 161 - "link_uris_test.dart"
Cohesion: 0.33
Nodes (5): package:pos_app/core/utils/link_uris.dart, expectSafe, field, main, receipt

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
Cohesion: 0.18
Nodes (14): currencyCodeProvider, currencySymbolProvider, shareFilesProvider, build, _CurrencyPickerSheet, CurrencySection, current, _showCurrencyPicker (+6 more)

### Community 170 - "percent.dart"
Cohesion: 0.22
Nodes (8): formatPercent, formatPercentNumber, formatRateForEdit, formatRatePercent, kPercentDecimals, kPercentInputPattern, text, RegExp

### Community 171 - "VoidCallback?"
Cohesion: 0.12
Nodes (14): build, canNext, isLast, onBack, OnboardingNavBar, onNext, saving, step (+6 more)

### Community 172 - "Projects Dependencies"
Cohesion: 0.22
Nodes (8): Dev Dependencies, [Hardware] flutter_thermal_printer, Major Dependencies, Outdated / Deprecated Dependencies, Overview, [Persistence] drift, Projects Dependencies, [State Management] flutter_riverpod

### Community 173 - "External Integrations"
Cohesion: 0.22
Nodes (8): APIs & External Services, Authentication & Identity, CI/CD & Deployment, Data Storage, Environment Configuration, External Integrations, Monitoring & Observability, Webhooks & Callbacks

### Community 174 - "utils/share_origin_test.dart"
Cohesion: 0.33
Nodes (5): package:pos_app/core/utils/share_origin.dart, expectUsable, ipad, main, screen

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

### Community 180 - "StateNotifier"
Cohesion: 0.40
Nodes (5): PosFilterNotifier, PosFilterState, ProductsFilterNotifier, ProductsFilterState, StateNotifier

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
Nodes (18): build, _Chip, color, InventoryFilterBar, label, lowCount, onSelect, onTap (+10 more)

### Community 187 - "CLAUDE.md"
Cohesion: 0.50
Nodes (3): Database schema changes, graphify, Offline-first (non-negotiable)

### Community 188 - "app_version.dart"
Cohesion: 0.50
Nodes (3): kAppBuildNumber, kAppVersion, kAppVersionFull

### Community 193 - "package:flutter/material.dart"
Cohesion: 0.06
Nodes (32): build, BusinessNameStep, controller, build, countries, CountryStep, kUnmatchedRegionText, loading (+24 more)

### Community 196 - "tax_dao.dart"
Cohesion: 0.22
Nodes (8): getAll, getById, getRatesForProduct, setProductTaxes, upsertRate, watchActive, package:pos_app/core/database/tables/product_taxes_table.dart, _

### Community 197 - "usage_screen_test.dart"
Cohesion: 0.04
Nodes (58): BusinessType? get, ButtonStyleButton, CheckboxListTile, _grammar.dart, countOf, currentUsageEnvironment, readShopSizeCounts, t (+50 more)

### Community 198 - "tables_dao.dart"
Cohesion: 0.25
Nodes (7): deleteById, getAll, getById, upsert, watchAll, package:pos_app/core/database/tables/tables_table.dart, _

## Knowledge Gaps
- **4121 isolated node(s):** `refresh`, `router`, `flags`, `location`, `getKeyboardDismissBehavior` (+4116 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **7 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Return` connect `Return` to `app_database.dart`, `restore_merge_marker.dart`, `tron_border.dart`, `package:pos_app/core/providers/hive_provider.dart`, `usage_counter.dart`, `usage_summary.dart`, `calc_oracle.dart`, `package:flutter_riverpod/flutter_riverpod.dart`, `features_screen.dart`, `customers_provider.dart`, `DataClass`, `unit_conversion.dart`, `render_receipt.dart`, `percent.dart`, `app.dart`, `review_state_store.dart`, `csv_text.dart`, `receipt_printer.dart`, `pos_catalog_provider.dart`, `receipt_pdf_service.dart`, `money.dart`, `products_provider.dart`, `usage_providers.dart`, `receipt_roll_pdf.dart`, `escpos_raster.dart`, `render_receipt_image.dart`, `bundled_fonts.dart`, `escpos_raster_test.dart`, `locale_country.dart`, `review_policy.dart`?**
  _High betweenness centrality (0.041) - this node is a cross-community bridge._
- **Why does `AppDatabase` connect `package:pos_app/core/database/app_database.dart` to `app_database.dart`, `auto_print_test.dart`, `package:pos_app/features/cart/domain/cart_item.dart`, `usage_screen_test.dart`, `payment_screen_test.dart`, `backup_repository.dart`, `DateTime`, `package:pos_app/core/providers/database_provider.dart`, `audit_dao.dart`, `package:flutter_test/flutter_test.dart`, `package:pos_app/core/providers/hive_provider.dart`, `app.dart`, `package:flutter_riverpod/flutter_riverpod.dart`, `most_sold_test.dart`, `order_history.dart`?**
  _High betweenness centrality (0.013) - this node is a cross-community bridge._
- **Why does `featureOnProvider` connect `featureOnProvider` to `ConsumerWidget`, `build`, `settings_screen.dart`, `ConsumerStatefulWidget`, `package:pos_app/shared/widgets/app_sheet.dart`, `hive_provider.dart`, `cart_notifier.dart`, `features_screen.dart`?**
  _High betweenness centrality (0.010) - this node is a cross-community bridge._
- **What connects `refresh`, `router`, `flags` to the rest of the system?**
  _4121 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `app_database.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.007692307692307693 - nodes in this community are weakly interconnected._
- **Should `schema_v15.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.015503875968992248 - nodes in this community are weakly interconnected._
- **Should `schema_v11.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.017543859649122806 - nodes in this community are weakly interconnected._