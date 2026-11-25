# Graph Report - agent-a3d526a14688b3540  (2026-11-25)

## Corpus Check
- 321 files · ~253,694 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 5338 nodes · 8538 edges · 192 communities (187 shown, 5 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `b11bbbe1`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- app_database.dart
- schema_v13.dart
- schema_v12.dart
- schema_v10.dart
- schema_v9.dart
- schema_v8.dart
- schema_v4.dart
- schema_v15.dart
- schema_v7.dart
- schema_v6.dart
- schema_v14.dart
- schema_v11.dart
- snapshot_service.dart
- Table
- hive_provider.dart
- report_figures_test.dart
- payment_screen_test.dart
- ConsumerWidget
- package:drift/drift.dart
- usage_summary.dart
- usage_ask_test.dart
- usage_screen_test.dart
- held_tickets_bar.dart
- calc_oracle.dart
- usage_counter.dart
- report_data.dart
- expenses_screen.dart
- app_root.dart
- package:flutter_riverpod/flutter_riverpod.dart
- dart:io
- DataClass
- review_controller_test.dart
- place_order.dart
- product_form_screen.dart
- backup_repository.dart
- backup/share_origin_test.dart
- home.dart
- app.dart
- restore_recovery_test.dart
- orders_dao.dart
- StatelessWidget
- orders_screen.dart
- snapshot_providers.dart
- most_sold_test.dart
- csv_text.dart
- payment_screen.dart
- receipt_printer.dart
- Milestone 1: v1 (Foundation & Core POS)
- product_tile.dart
- sell_screen_rebuild_test.dart
- package:flutter/services.dart
- receipt_screen.dart
- audit_dao.dart
- usage_ask_controller.dart
- settings_screen.dart
- package:flutter/material.dart
- databaseProvider
- pos_catalog_provider.dart
- settingsProvider
- backup_screen.dart
- orders_screen_test.dart
- VoidCallback?
- printer_setup_screen.dart
- receipt_pdf_service.dart
- snapshot_photos_test.dart
- String?
- orders_table.dart
- money.dart
- onboarding_screen.dart
- products_screen.dart
- package:flutter_test/flutter_test.dart
- IntColumn get
- products_dao.dart
- package:flutter/foundation.dart
- tables_screen.dart
- inventory_filter_bar.dart
- pos_cart_actions.dart
- held_order.dart
- cart_notifier.dart
- order_history.dart
- products_provider.dart
- products_table.dart
- app_theme.dart
- cart_summary.dart
- order_summary.dart
- inventory_card.dart
- order_detail_screen.dart
- thermal_plugin_printer.dart
- receipt_body.dart
- usage_constants.dart
- Open POS
- usage_providers.dart
- customer_form.dart
- customers_screen.dart
- usage_host.dart
- tokens.dart
- _
- receipt_roll_pdf.dart
- snapshot_service_test.dart
- restore_merge_test.dart
- package:pos_app/features/usage/domain/usage_event.dart
- escpos_raster.dart
- cart_item.dart
- article_detail_screen.dart
- TextColumn get
- returns_table.dart
- pos_filter_provider.dart
- dashboard_body.dart
- tax_settings_screen.dart
- schema.dart
- audit_log_table.dart
- order_taxes_table.dart
- inventory_section.dart
- ConsumerState
- _PrinterSetupScreenState
- Return
- support_screen.dart
- spp_printer.dart
- sales.dart
- tax_group_members_table.dart
- learn_screen.dart
- render_receipt.dart
- v1 Roadmap — Flutter Offline-First POS
- DateTime
- tax_section.dart
- customers_table.dart
- support_contact.dart
- review_state_store.dart
- store_review_prompter.dart
- review_policy.dart
- store_profile_edit_screen.dart
- tron_border.dart
- render_receipt_image.dart
- discount_sheet.dart
- expenses_dao.dart
- order_items_table.dart
- cart_session.dart
- package:pos_app/features/review/domain/review_policy.dart
- escpos_raster_test.dart
- package:pos_app/core/providers/hive_provider.dart
- GeneratedDatabase
- expenses_table.dart
- app_sheet.dart
- audit_log_screen.dart
- review_controller.dart
- grid_product_tile.dart
- ReviewPrompter
- migration_test.dart
- tax_rates_table.dart
- bundled_fonts.dart
- State
- usage_counter_test.dart
- customer_picker_sheet.dart
- onboardingNotifierProvider
- tax_step.dart
- receipt_roll_pdf_test.dart
- _grammar.dart
- tables_dao.dart
- customers_dao.dart
- review_providers.dart
- support_contact_test.dart
- _StoreProfileEditScreenState
- country_default.dart
- package:pos_app/features/printing/domain/receipt_printer.dart
- unit_conversion.dart
- package:pos_app/core/utils/currency_formatter.dart
- @visibleForTesting
- tax_dao.dart
- categories_table.dart
- appearance_section.dart
- onboarding_state.dart
- country_step.dart
- Projects Dependencies
- External Integrations
- package:pos_app/core/database/app_database.dart
- _
- Project Conventions
- Technology Stack
- @immutable
- package:pos_app/features/review/domain/review_prompter.dart
- reportProvider
- usage_event.dart
- dart:convert
- int get
- usage_screen.dart
- install_macos.sh
- app_root_retry_test.dart
- CLAUDE.md
- app_version.dart
- _DeflatedFile
- _FileSink
- currencies.dart

## God Nodes (most connected - your core abstractions)
1. `AppDatabase` - 48 edges
2. `databaseProvider` - 36 edges
3. `Return` - 30 edges
4. `_` - 28 edges
5. `cartSessionProvider` - 25 edges
6. `currencyFormatterProvider` - 22 edges
7. `settingsProvider` - 20 edges
8. `usageCounterProvider` - 20 edges
9. `DataClass` - 19 edges
10. `AuditService` - 19 edges

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

## Communities (192 total, 5 thin omitted)

### Community 0 - "app_database.dart"
Cohesion: 0.01
Nodes (259): class OrderTaxOverride extends, class ProductComponent extends, ColumnFilters, ColumnOrderings, backfillInvoiceNumbers, backfillV14, currentSchemaVersion, migration (+251 more)

### Community 1 - "schema_v13.dart"
Cohesion: 0.02
Nodes (116): ExpenseCategories, Index, action, actualTableName, address, _alias, aliasedName, allSchemaEntities (+108 more)

### Community 2 - "schema_v12.dart"
Cohesion: 0.02
Nodes (112): ProductTaxes, StockAdjustments, TaxRates, action, actualTableName, address, _alias, aliasedName (+104 more)

### Community 3 - "schema_v10.dart"
Cohesion: 0.02
Nodes (112): Categories, TaxGroups, action, actualTableName, address, _alias, aliasedName, allSchemaEntities (+104 more)

### Community 4 - "schema_v9.dart"
Cohesion: 0.02
Nodes (112): OrderTaxOverrides, ProductComponents, action, actualTableName, address, _alias, aliasedName, allSchemaEntities (+104 more)

### Community 5 - "schema_v8.dart"
Cohesion: 0.02
Nodes (110): AuditLog, GeneratedColumn, action, actualTableName, address, _alias, aliasedName, allSchemaEntities (+102 more)

### Community 6 - "schema_v4.dart"
Cohesion: 0.02
Nodes (110): OrderItems, Returns, action, actualTableName, address, _alias, aliasedName, allSchemaEntities (+102 more)

### Community 7 - "schema_v15.dart"
Cohesion: 0.02
Nodes (109): action, actualTableName, address, _alias, aliasedName, allSchemaEntities, allTables, amount (+101 more)

### Community 8 - "schema_v7.dart"
Cohesion: 0.02
Nodes (107): Orders, ProductModifiers, ProductVariants, Tables, action, actualTableName, address, _alias (+99 more)

### Community 9 - "schema_v6.dart"
Cohesion: 0.02
Nodes (105): Expenses, OrderTaxes, Products, TaxGroupMembers, action, actualTableName, address, _alias (+97 more)

### Community 10 - "schema_v14.dart"
Cohesion: 0.02
Nodes (102): Customers, action, actualTableName, address, _alias, aliasedName, allSchemaEntities, allTables (+94 more)

### Community 11 - "schema_v11.dart"
Cohesion: 0.02
Nodes (117): action, actualTableName, address, _alias, aliasedName, allSchemaEntities, allTables, amount (+109 more)

### Community 12 - "snapshot_service.dart"
Cohesion: 0.02
Nodes (87): InputFileStream, _absentSuffix, add, _addDeflated, _addStored, assertNoPendingRestore, _bakSuffix, _baseName (+79 more)

### Community 13 - "Table"
Cohesion: 0.06
Nodes (71): Table, TableInfo, AuditLog, Customers, ExpenseCategories, OrderItems, Orders, OrderTaxes (+63 more)

### Community 14 - "hive_provider.dart"
Cohesion: 0.03
Nodes (76): AppSettings, autoBackupEnabled, autoBackupLastAt, _box, build, businessAddress, businessName, businessNameOrDefault (+68 more)

### Community 15 - "report_figures_test.dart"
Cohesion: 0.05
Nodes (53): AuditService, transaction, voidOrder, package:pos_app/core/services/audit_service.dart, package:pos_app/features/reports/domain/report_data.dart, package:pos_app/features/returns/domain/process_return.dart, package:pos_app/features/returns/domain/void_order.dart, ../../_support/sales.dart (+45 more)

### Community 16 - "payment_screen_test.dart"
Cohesion: 0.05
Nodes (43): Box, Completer, Directory, _box, formatTicketNumber, heldOrdersBoxProvider, kTicketSeqKey, next (+35 more)

### Community 17 - "ConsumerWidget"
Cohesion: 0.12
Nodes (27): ConsumerWidget, cartMainUnitQtyProvider, build, CartDetailScreen, _ClearCartButton, _ListSeparator, build, initState (+19 more)

### Community 18 - "package:drift/drift.dart"
Cohesion: 0.05
Nodes (49): _, @DriftDatabase, AppDatabase, package:drift/drift.dart, package:pos_app/features/cart/data/place_order.dart, package:pos_app/features/tax/presentation/tax_settings_screen.dart, ../../_support/test_db.dart, audit (+41 more)

### Community 19 - "usage_summary.dart"
Cohesion: 0.04
Nodes (45): appInfo, appVersion, buildUsageSummary, bump, canSendUsageSummary, count, currencyCode, _currencyPattern (+37 more)

### Community 20 - "usage_ask_test.dart"
Cohesion: 0.18
Nodes (10): package:pos_app/features/usage/application/usage_ask_controller.dart, package:pos_app/features/usage/domain/usage_ask_policy.dart, ask, available, calls, main, maybeRequestReview, now (+2 more)

### Community 21 - "usage_screen_test.dart"
Cohesion: 0.07
Nodes (29): ButtonStyleButton, _grammar.dart, countOf, currentUsageEnvironment, readShopSizeCounts, t, package:pos_app/features/usage/domain/usage_summary.dart, package:pos_app/features/usage/usage_constants.dart (+21 more)

### Community 22 - "held_tickets_bar.dart"
Cohesion: 0.07
Nodes (37): AnimationController, ConsumerStatefulWidget, HeldOrder, PaymentScreen, activeHeldOrdersProvider, archive, archiveAll, archivedHeldOrdersProvider (+29 more)

### Community 23 - "calc_oracle.dart"
Cohesion: 0.04
Nodes (46): BigInt, int? discPermille,
  int, balance, base, baseOnHalfCent, bp, cents, d (+38 more)

### Community 24 - "usage_counter.dart"
Cohesion: 0.04
Nodes (45): bool?, after, askedVersion, _box, countingEnabled, countingOn, _counts, _defaultOpen (+37 more)

### Community 25 - "report_data.dart"
Cohesion: 0.04
Nodes (48): avgOrder, changes, chartDates, chartHighlightIndex, chartTitle, chartTotals, costIsIncomplete, costOfGoods (+40 more)

### Community 26 - "expenses_screen.dart"
Cohesion: 0.05
Nodes (45): _amountCtrl, build, categories, category, _categoryId, _check, color, createState (+37 more)

### Community 27 - "app_root.dart"
Cohesion: 0.06
Nodes (30): autoBackupDelay, _autoBackupRun, autoBackupScheduledForTest, _autoBackupTimer, build, child, _closeDatabaseForExit, _container (+22 more)

### Community 28 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.05
Nodes (52): customerId, customers, watch, activeHeld, cartTableId, tableId, tables, watch (+44 more)

### Community 29 - "dart:io"
Cohesion: 0.10
Nodes (18): dart:io, package:pos_app/core/app_version.dart, package:pos_app/features/backup/data/backup_repository.dart, package:pos_app/features/backup/data/csv_text.dart, package:pos_app/features/review/review_providers.dart, main, manifest, rules (+10 more)

### Community 30 - "DataClass"
Cohesion: 0.09
Nodes (39): Insertable, OrderNumberX, UpdateCompanion, AuditLogCompanion, AuditLogData, CategoriesCompanion, Category, Customer (+31 more)

### Community 31 - "review_controller_test.dart"
Cohesion: 0.13
Nodes (14): box, calls, controller, eligible, main, maybeRequestReview, _Mode, now (+6 more)

### Community 32 - "place_order.dart"
Cohesion: 0.22
Nodes (8): components, cost, invoicePrefix, placeOrder, roundMoney, transaction, _unitCostNow, required double tenderedAmount,
  String

### Community 33 - "product_form_screen.dart"
Cohesion: 0.06
Nodes (36): _categoryId, _ComponentEntry, _components, _conversionCtrl, createState, _delete, didChangeDependencies, dispose (+28 more)

### Community 34 - "backup_repository.dart"
Cohesion: 0.06
Nodes (34): added, _csvEol, csvImportExplanation, CsvImportReport, db, exportCustomers, exportExpenses, exportOrders (+26 more)

### Community 35 - "backup/share_origin_test.dart"
Cohesion: 0.08
Nodes (23): FormatException, package:pos_app/features/backup/presentation/backup_screen.dart, package:pos_app/features/receipts/presentation/receipt_pdf_service.dart, customers, db, main, orders, ordersHeader (+15 more)

### Community 36 - "home.dart"
Cohesion: 0.07
Nodes (32): demoDataServiceProvider, posCatalogProvider, posFilterProvider, CartScreen, _CartScreenState, categories, _CategoryRow, _Chip (+24 more)

### Community 37 - "app.dart"
Cohesion: 0.06
Nodes (31): ChangeNotifier, GoRouter, AppScrollBehavior, getKeyboardDismissBehavior, onNavigate, ping, POSApp, refresh (+23 more)

### Community 38 - "restore_recovery_test.dart"
Cohesion: 0.07
Nodes (31): Exception, FileSystemException, RestoreJournalFormatException, PendingRestoreException, RestoreFatalException, RestoreRolledBackException, SnapshotFormatException, backupOf (+23 more)

### Community 39 - "orders_dao.dart"
Cohesion: 0.06
Nodes (31): completedOrderCount, _escapeLike, getById, getItems, getTaxBreakdown, hasRestockedReturn, historyPage, incrementPrintCount (+23 more)

### Community 40 - "StatelessWidget"
Cohesion: 0.07
Nodes (31): _RestoreFailedScreen, _RestoringSplash, _CategoryChips, _Chip, _ExpenseTile, _TotalBar, build, cs (+23 more)

### Community 41 - "orders_screen.dart"
Cohesion: 0.07
Nodes (35): orderHistoryProvider, _body, build, _clearQuery, createState, cs, customerName, _debounce (+27 more)

### Community 42 - "snapshot_providers.dart"
Cohesion: 0.08
Nodes (25): autoBackupDir, autoBackupLastError, create, createAndShare, defaultHiveBoxPaths, docs, inspect, kAutoBackupInterval (+17 more)

### Community 43 - "most_sold_test.dart"
Cohesion: 0.06
Nodes (32): int tea,, package:drift/native.dart, package:pos_app/core/services/demo_data_service.dart, QueryInterceptor, ../../_support/query_recorder.dart, db, expectIndexed, from (+24 more)

### Community 44 - "csv_text.dart"
Cohesion: 0.07
Nodes (29): _bad, boolOf, cell, cellQuoted, _cells, _columns, CsvRow, CsvTable (+21 more)

### Community 45 - "payment_screen.dart"
Cohesion: 0.09
Nodes (21): createState, customer, dispose, endsWith, fmt, icon, label, _loyaltyCtrl (+13 more)

### Community 46 - "receipt_printer.dart"
Cohesion: 0.07
Nodes (28): address, data, devices, DiscoveredPrinter, driver, escPosPrinterProvider, fmt, fromKey (+20 more)

### Community 47 - "Milestone 1: v1 (Foundation & Core POS)"
Cohesion: 0.07
Nodes (26): 1. State Management (Riverpod), 2. Navigation (GoRouter), 3. Data Layer (Drift & Hive), 4. Hardware Integration, Core Pillars, Data Flow, Directory Structure, Overview (+18 more)

### Community 48 - "product_tile.dart"
Cohesion: 0.07
Nodes (27): Color, ColorScheme, bg, color, cs, icon, onDecrement, onIncrement (+19 more)

### Community 49 - "sell_screen_rebuild_test.dart"
Cohesion: 0.07
Nodes (26): AppBar, CustomPaint, FilterChip, GridView, build, ListView, MaterialPageRoute, NavigatorState (+18 more)

### Community 50 - "package:flutter/services.dart"
Cohesion: 0.08
Nodes (24): AndroidSdk, _cached, _methods, _read, sdkInt, _devices, _discovery, dispose (+16 more)

### Community 51 - "receipt_screen.dart"
Cohesion: 0.08
Nodes (27): build, businessName, createState, customer, data, db, dispose, fmt (+19 more)

### Community 52 - "audit_dao.dart"
Cohesion: 0.10
Nodes (24): @DriftAccessor, _$AuditDaoMixin, _$CustomersDaoMixin, DatabaseAccessor, _$ExpensesDaoMixin, _$InventoryDaoMixin, AuditDao, log (+16 more)

### Community 53 - "usage_ask_controller.dart"
Cohesion: 0.08
Nodes (25): AppLifecycleListener?, dart:async, dart:ui, Duration, DatabaseExitGuard, dispose, handleExitRequest, _listener (+17 more)

### Community 54 - "settings_screen.dart"
Cohesion: 0.15
Nodes (12): build, SettingsScreen, package:pos_app/features/settings/presentation/widgets/appearance_section.dart, package:pos_app/features/settings/presentation/widgets/backup_section.dart, package:pos_app/features/settings/presentation/widgets/currency_section.dart, package:pos_app/features/settings/presentation/widgets/danger_section.dart, package:pos_app/features/settings/presentation/widgets/inventory_section.dart, package:pos_app/features/settings/presentation/widgets/loyalty_section.dart (+4 more)

### Community 55 - "package:flutter/material.dart"
Cohesion: 0.05
Nodes (35): EditableText, BackupSection, build, build, SettingsSectionHeader, title, cs, icon (+27 more)

### Community 56 - "databaseProvider"
Cohesion: 0.08
Nodes (33): auditServiceProvider, databaseProvider, _createFullBackup, _runExport, _PaymentScreenState, _placeOrder, _showDiscountSheet, _delete (+25 more)

### Community 57 - "pos_catalog_provider.dart"
Cohesion: 0.08
Nodes (24): AsyncValue, buildPosSearchIndex, cart, catalogEmpty, categoryId, committedMainUnits, favorites, favoritesOnly (+16 more)

### Community 58 - "settingsProvider"
Cohesion: 0.10
Nodes (25): loyaltyEarnRateProvider, loyaltyEnabledProvider, loyaltyPointValueProvider, settingsBoxProvider, settingsProvider, OnboardingState, back, build (+17 more)

### Community 59 - "backup_screen.dart"
Cohesion: 0.08
Nodes (34): autoBackupEnabledProvider, autoBackupLastAtProvider, backupRepositoryProvider, snapshotCoordinatorProvider, _AutoBackupTile, BackupScreen, _BackupScreenState, _BackupTile (+26 more)

### Community 60 - "orders_screen_test.dart"
Cohesion: 0.11
Nodes (16): package:pos_app/features/audit/presentation/audit_log_screen.dart, package:pos_app/features/expenses/presentation/expenses_screen.dart, package:pos_app/features/orders/domain/order_history.dart, package:pos_app/features/orders/presentation/orders_screen.dart, container, db, main, order (+8 more)

### Community 61 - "VoidCallback?"
Cohesion: 0.08
Nodes (21): _Badge, bg, customer, CustomerCard, fg, icon, label, onEdit (+13 more)

### Community 62 - "printer_setup_screen.dart"
Cohesion: 0.08
Nodes (23): PrinterDriver, printerForDriverProvider, createState, _devices, _devicesSub, _disconnectSavedPrinter, dispose, _driver (+15 more)

### Community 63 - "receipt_pdf_service.dart"
Cohesion: 0.08
Nodes (23): baseStyle, billRow, boldStyle, buildReceiptPdf, bytes, customerName, _dataCell, dateFmt (+15 more)

### Community 64 - "snapshot_photos_test.dart"
Cohesion: 0.09
Nodes (21): File, package:archive/archive.dart, backupOf, dbFileIn, entriesOf, hasProduct, hivePathIn, _indexOf (+13 more)

### Community 65 - "String?"
Cohesion: 0.07
Nodes (28): double?, IconData?, action, AppEmptyState, build, icon, subtitle, title (+20 more)

### Community 66 - "orders_table.dart"
Cohesion: 0.09
Nodes (22): changeAmount, createdAt, customerId, discountIsPercent, discountTotal, discountValue, id, invoiceNo (+14 more)

### Community 67 - "money.dart"
Cohesion: 0.09
Nodes (22): allowZero, byLoss, cents, eps, exact, isRequired, kMaxMoneyAmount, kMaxMoneyAmountLabel (+14 more)

### Community 68 - "onboarding_screen.dart"
Cohesion: 0.09
Nodes (22): _businessNameCtrl, _canProceed, _countries, createState, dispose, _filterCountries, _filtered, _loadingCountries (+14 more)

### Community 69 - "products_screen.dart"
Cohesion: 0.09
Nodes (22): categories, _CategoryChips, categoryName, _Chip, createState, cs, dispose, fmt (+14 more)

### Community 70 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.06
Nodes (33): dart:math, _, CartCalculator, compute, _roundingModeFor, package:flutter_test/flutter_test.dart, package:pos_app/core/utils/money.dart, package:pos_app/core/utils/tax_calculator.dart (+25 more)

### Community 71 - "IntColumn get"
Cohesion: 0.10
Nodes (19): IntColumn get, getAdjustmentsForProduct, logAdjustment, watchLowStock, componentProductId, compositeProductId, id, ProductComponents (+11 more)

### Community 72 - "products_dao.dart"
Cohesion: 0.09
Nodes (21): deductStock, deleteCategory, getAllCategories, getById, getBySku, getComponents, replaceComponents, restock (+13 more)

### Community 73 - "package:flutter/foundation.dart"
Cohesion: 0.12
Nodes (15): apple, _encode, _lineBreak, mailtoLink, query, smsLink, target, to (+7 more)

### Community 74 - "tables_screen.dart"
Cohesion: 0.10
Nodes (21): _assignToCart, _capacityCtrl, createState, dispose, existing, initState, isCurrentCartTable, isOccupied (+13 more)

### Community 75 - "inventory_filter_bar.dart"
Cohesion: 0.17
Nodes (11): build, _Chip, color, InventoryFilterBar, label, lowCount, onSelect, onTap (+3 more)

### Community 76 - "pos_cart_actions.dart"
Cohesion: 0.14
Nodes (13): CartNotifier get, add, _allowQty, _cart, _committed, _container, _messenger, pickUnit (+5 more)

### Community 77 - "held_order.dart"
Cohesion: 0.10
Nodes (20): archivedAt, copyWith, createdAt, customerId, customerName, fromJson, id, isArchived (+12 more)

### Community 78 - "cart_notifier.dart"
Cohesion: 0.05
Nodes (56): ticketSequenceProvider, CartSession, addItem, addProduct, addProductInSecondaryUnit, allRates, CartNotifier, CartSessionNotifier (+48 more)

### Community 79 - "order_history.dart"
Cohesion: 0.10
Nodes (20): _changes, copyWith, _db, dispose, error, _generation, hasMore, isLoading (+12 more)

### Community 80 - "products_provider.dart"
Cohesion: 0.05
Nodes (39): Iterable, _fitsStock, build, createState, dispose, _filter, _filtered, filterInventoryProducts (+31 more)

### Community 81 - "products_table.dart"
Cohesion: 0.10
Nodes (19): categoryId, conversionRate, createdAt, id, imagePath, isActive, isComposite, isHiddenInPos (+11 more)

### Community 82 - "app_theme.dart"
Cohesion: 0.10
Nodes (19): AppTheme, backgroundGradient, _build, ctaButtonStyle, _dark, _darkGrad, _darkScheme, _fontFamily (+11 more)

### Community 83 - "cart_summary.dart"
Cohesion: 0.10
Nodes (19): amount, CartSummary, isInclusive, loyaltyDiscount, maxRedeemablePoints, name, orderDiscount, pointsRedeemed (+11 more)

### Community 84 - "order_summary.dart"
Cohesion: 0.08
Nodes (23): CurrencyFormatter, CartItem, build, fmt, icon, item, onPressed, _QtyButton (+15 more)

### Community 85 - "inventory_card.dart"
Cohesion: 0.10
Nodes (19): _apply, badgeColor, build, canDecrement, canIncrement, cs, _decrement, icon (+11 more)

### Community 86 - "order_detail_screen.dart"
Cohesion: 0.11
Nodes (18): businessName, customer, data, db, _DetailData, fmt, isPartlyRefunded, items (+10 more)

### Community 87 - "thermal_plugin_printer.dart"
Cohesion: 0.12
Nodes (15): _connect, _connectTimeout, devices, _disconnect, _ftp, _pluginDevice, _printPages, printReceipt (+7 more)

### Community 88 - "receipt_body.dart"
Cohesion: 0.10
Nodes (20): _BillRow, build, businessName, customer, data, _DataCell, fmt, _HeaderCell (+12 more)

### Community 89 - "usage_constants.dart"
Cohesion: 0.09
Nodes (21): kFeedbackAreaQuestion, kFeedbackAskAction, kFeedbackAskText, kFeedbackInstruction, kFeedbackMessageMaxLength, kFeedbackSupportRowSubtitle, kFeedbackSupportRowTitle, kOfflineFirstLine (+13 more)

### Community 90 - "Open POS"
Cohesion: 0.10
Nodes (19): Build from source, Contributing, Customers, Features, Get Open POS, License, macOS, Money and reports (+11 more)

### Community 91 - "usage_providers.dart"
Cohesion: 0.08
Nodes (23): databaseFile, dir, kDatabaseFileName, openConnection, ShareFiles, shareFilesWithOs, c, f (+15 more)

### Community 92 - "customer_form.dart"
Cohesion: 0.11
Nodes (18): _addressCtrl, build, createState, customer, CustomerForm, _CustomerFormState, _delete, _discountCtrl (+10 more)

### Community 93 - "customers_screen.dart"
Cohesion: 0.12
Nodes (18): IconData get, build, createState, CustomersScreen, _CustomersScreenState, dispose, _filterAndSort, icon (+10 more)

### Community 94 - "usage_host.dart"
Cohesion: 0.12
Nodes (18): onboardingCompleteProvider, UsageCounter, _ask, build, child, _counter, createState, _disclosing (+10 more)

### Community 95 - "tokens.dart"
Cohesion: 0.11
Nodes (18): AppFonts, AppOpacity, heavy, lg, md, medium, mono, Radii (+10 more)

### Community 96 - "_"
Cohesion: 0.11
Nodes (20): _, _abs, bak, begin, cleanup, committed, markCommitted, message (+12 more)

### Community 97 - "receipt_roll_pdf.dart"
Cohesion: 0.11
Nodes (18): base, body, bold, buildReceiptRollPdf, buildTestPageRollPdf, dateFmt, doc, font (+10 more)

### Community 98 - "snapshot_service_test.dart"
Cohesion: 0.11
Nodes (18): package:sqlite3/sqlite3.dart, craftZip, dbFileIn, expectLiveUntouched, expectRejected, hivePathIn, live, main (+10 more)

### Community 99 - "restore_merge_test.dart"
Cohesion: 0.11
Nodes (18): backupOf, dbFileIn, hivePathIn, installedLive, installedOld, live, liveState, main (+10 more)

### Community 100 - "package:pos_app/features/usage/domain/usage_event.dart"
Cohesion: 0.17
Nodes (11): session, AutoPrintService, printOrder, _ref, UsageRecording, package:pos_app/features/cart/presentation/widgets/customer_picker_sheet.dart, package:pos_app/features/cart/presentation/widgets/table_selector.dart, package:pos_app/features/customers/domain/customers_provider.dart (+3 more)

### Community 101 - "escpos_raster.dart"
Cohesion: 0.11
Nodes (17): dart:isolate, Future, bytes, cached, canvas, escPosProfile, escPosRasterBytes, escPosRasterBytesSync (+9 more)

### Community 102 - "cart_item.dart"
Cohesion: 0.12
Nodes (16): copyWith, grossAmount, isSecondaryUnit, isTaxable, lineDiscount, lineSubtotal, mainUnitQty, name (+8 more)

### Community 103 - "article_detail_screen.dart"
Cohesion: 0.11
Nodes (17): ArticleDetailScreen, ArticleSection, build, category, cs, heading, icon, readTime (+9 more)

### Community 104 - "TextColumn get"
Cohesion: 0.12
Nodes (15): @DataClassName, DateTimeColumn get, capacity, createdAt, id, name, notes, Tables (+7 more)

### Community 105 - "returns_table.dart"
Cohesion: 0.12
Nodes (15): createdAt, id, orderId, OrderTaxOverrides, originalTax, overrideTax, reason, amount (+7 more)

### Community 106 - "pos_filter_provider.dart"
Cohesion: 0.12
Nodes (16): clearSearch, copyWith, favoritesOnly, isGrid, PosFilterNotifier, PosFilterState, PosSortMode, search (+8 more)

### Community 107 - "dashboard_body.dart"
Cohesion: 0.12
Nodes (16): ReportData, build, _buildKpiRows, cs, DashboardBody, data, _fmt, isCustomRange (+8 more)

### Community 108 - "tax_settings_screen.dart"
Cohesion: 0.12
Nodes (17): FormState, createState, dispose, existing, _formKey, _inclusionType, _nameCtrl, onAdd (+9 more)

### Community 109 - "schema.dart"
Cohesion: 0.12
Nodes (16): package:drift/internal/migrations.dart, schema_v10.dart, schema_v11.dart, schema_v12.dart, schema_v13.dart, schema_v14.dart, schema_v15.dart, schema_v4.dart (+8 more)

### Community 110 - "audit_log_table.dart"
Cohesion: 0.12
Nodes (15): @TableIndex, action, AuditLog, createdAt, entityId, entityType, id, metadata (+7 more)

### Community 111 - "order_taxes_table.dart"
Cohesion: 0.12
Nodes (14): BoolColumn get, color, ExpenseCategories, id, isDefault, name, id, isInclusive (+6 more)

### Community 112 - "inventory_section.dart"
Cohesion: 0.08
Nodes (32): build, lowStockThresholdProvider, build, build, categoriesStreamProvider, productsFilterProvider, CategoriesScreen, build (+24 more)

### Community 113 - "ConsumerState"
Cohesion: 0.10
Nodes (21): ConsumerState, currencyCodeProvider, currencySymbolProvider, DashboardScreen, _DashboardScreenState, build, _CurrencyPickerSheet, CurrencySection (+13 more)

### Community 114 - "_PrinterSetupScreenState"
Cohesion: 0.22
Nodes (15): printerDeviceAddressProvider, printerDeviceNameProvider, printerDriverProvider, printerPaperWidthProvider, build, _orderDetailProvider, OrderDetailScreen, receiptPrinterProvider (+7 more)

### Community 115 - "Return"
Cohesion: 0.09
Nodes (18): formatPercent, formatPercentNumber, formatRateForEdit, formatRatePercent, kPercentDecimals, kPercentInputPattern, text, initials (+10 more)

### Community 116 - "support_screen.dart"
Cohesion: 0.12
Nodes (15): build, cs, gradient, icon, _InfoRow, label, onTap, _SectionHeader (+7 more)

### Community 117 - "spp_printer.dart"
Cohesion: 0.12
Nodes (15): _devices, dispose, _methods, _print, printReceipt, printTestPage, _requireAndroid, SppPrinter (+7 more)

### Community 118 - "sales.dart"
Cohesion: 0.13
Nodes (14): int? customerId,
  int, line, loyaltyDiscount, paymentMethod, placeOrder, points, pointsRedeemed, pointsToEarn (+6 more)

### Community 119 - "tax_group_members_table.dart"
Cohesion: 0.14
Nodes (13): primaryKey, productId, ProductTaxes, taxRateId, groupId, primaryKey, sortOrder, TaxGroupMembers (+5 more)

### Community 120 - "learn_screen.dart"
Cohesion: 0.13
Nodes (14): _Article, _ArticleCard, _articles, category, cs, description, icon, LearnScreen (+6 more)

### Community 121 - "render_receipt.dart"
Cohesion: 0.07
Nodes (27): bytes, customerName, g, isCopy, _kv, method, methodLabel, profile (+19 more)

### Community 122 - "v1 Roadmap — Flutter Offline-First POS"
Cohesion: 0.13
Nodes (14): Architecture Decisions, Deferred to v2, Drift Schema — Full Table List (v1), Phase 0 — Foundation (No UI yet), Phase 1 — First-Run & Onboarding, Phase 2 — Product & Inventory Core, Phase 3 — Core Sales Loop, Phase 4 — Receipts & Hardware (+6 more)

### Community 123 - "DateTime"
Cohesion: 0.18
Nodes (13): DateTime, BackupRepository, package:csv/csv.dart, bytesOf, db, legacyAllOrdersWithItems, legacyOrdersCsv, legacySalesReportCsv (+5 more)

### Community 124 - "tax_section.dart"
Cohesion: 0.17
Nodes (15): int?, defaultTaxIdProvider, invoicePrefixProvider, build, reset, taxRatesStreamProvider, build, currentId (+7 more)

### Community 125 - "customers_table.dart"
Cohesion: 0.14
Nodes (13): address, createdAt, Customers, defaultDiscount, defaultDiscountIsPercent, email, id, isTaxExempt (+5 more)

### Community 126 - "support_contact.dart"
Cohesion: 0.15
Nodes (12): canLaunch, kLinkFailureMessageDuration, _kSupportWhatsAppDigits, kSupportWhatsAppDisplay, kSupportWhatsAppUnavailable, launch, messenger, native (+4 more)

### Community 127 - "review_state_store.dart"
Cohesion: 0.17
Nodes (11): _box, _date, ensureFirstLaunch, markAnyPromptShown, markPrompted, mergeAfterRestore, mergeReviewStateAfterRestore, read (+3 more)

### Community 128 - "store_review_prompter.dart"
Cohesion: 0.14
Nodes (12): _kAndroidListingUrl, maybeRequestReview, openStoreListing, _review, package:in_app_review/in_app_review.dart, package:url_launcher/url_launcher.dart, InAppReview, instance (+4 more)

### Community 129 - "review_policy.dart"
Cohesion: 0.14
Nodes (13): first, firstLaunchAt, kMinDaysBetweenAnyPrompts, kReviewMinCompletedSales, kReviewMinDaysBetweenPrompts, kReviewMinDaysSinceInstall, last, lastPromptAt (+5 more)

### Community 130 - "store_profile_edit_screen.dart"
Cohesion: 0.15
Nodes (12): class, _addressCtrl, build, createState, dispose, _initialised, _label, _loading (+4 more)

### Community 131 - "tron_border.dart"
Cohesion: 0.15
Nodes (12): CustomPainter, color, e, extractWrappedPath, f, len, p, paint (+4 more)

### Community 132 - "render_receipt_image.dart"
Cohesion: 0.17
Nodes (11): doc, escPosPrintWidthDots, isCopy, kReceiptDpi, pages, _rasterise, renderReceiptImages, renderTestPageImages (+3 more)

### Community 133 - "discount_sheet.dart"
Cohesion: 0.17
Nodes (12): double get, build, createState, _ctrl, currentDiscount, DiscountSheet, _DiscountSheetState, dispose (+4 more)

### Community 134 - "expenses_dao.dart"
Cohesion: 0.15
Nodes (12): getAll, getAllCategories, insert, insertCategory, totalForPeriod, updateExpense, upsertCategory, watchAll (+4 more)

### Community 135 - "order_items_table.dart"
Cohesion: 0.15
Nodes (12): discount, id, lineTotal, orderId, productId, productName, quantity, taxAmount (+4 more)

### Community 136 - "cart_session.dart"
Cohesion: 0.14
Nodes (13): bool get, copyWith, customerId, fresh, heldTicketId, isEditingHeldTicket, loyaltyPointsToRedeem, openedAt (+5 more)

### Community 137 - "package:pos_app/features/review/domain/review_policy.dart"
Cohesion: 0.17
Nodes (10): kUsageAskMinCompletedSales, kUsageAskMinDaysSinceInstall, shouldAskForFeedback, true, package:pos_app/features/review/domain/review_policy.dart, decide, main, now (+2 more)

### Community 138 - "escpos_raster_test.dart"
Cohesion: 0.11
Nodes (16): dart:typed_data, package:image/image.dart, package:pos_app/core/utils/bundled_fonts.dart, package:pos_app/features/printing/domain/escpos_raster.dart, StateError, main, _blockPage, _countSequence (+8 more)

### Community 139 - "package:pos_app/core/providers/hive_provider.dart"
Cohesion: 0.06
Nodes (33): _db, DemoDataService, seed, _seedDatabase, _settings, build, _confirmReset, package:pos_app/core/providers/database_provider.dart (+25 more)

### Community 140 - "GeneratedDatabase"
Cohesion: 0.17
Nodes (12): GeneratedDatabase, DatabaseAtV10, DatabaseAtV11, DatabaseAtV12, DatabaseAtV13, DatabaseAtV14, DatabaseAtV15, DatabaseAtV4 (+4 more)

### Community 141 - "expenses_table.dart"
Cohesion: 0.17
Nodes (11): amount, categoryId, createdAt, date, id, isRecurring, isTaxDeductible, notes (+3 more)

### Community 142 - "app_sheet.dart"
Cohesion: 0.17
Nodes (10): cs, failurePrefix, messenger, draggable, initialSize, minSize, package:pos_app/shared/widgets/keyboard_safe.dart, required WidgetBuilder builder,
  bool (+2 more)

### Community 143 - "audit_log_screen.dart"
Cohesion: 0.07
Nodes (30): DateTimeRange?, decimalDigits, _fmt, format, formatPlain, locale, _plainFmt, symbol (+22 more)

### Community 144 - "review_controller.dart"
Cohesion: 0.20
Nodes (9): appVersion, _guard, _inFlight, onReceiptDismissed, prompter, ReviewCheck, settleDelay, store (+1 more)

### Community 145 - "grid_product_tile.dart"
Cohesion: 0.14
Nodes (12): product, package:pos_app/features/cart/domain/pos_catalog_provider.dart, package:pos_app/features/cart/domain/pos_filter_provider.dart, package:pos_app/features/cart/presentation/pos_cart_actions.dart, package:pos_app/features/inventory/presentation/inventory_screen.dart, package:pos_app/features/products/domain/favorites_provider.dart, package:pos_app/shared/widgets/step_button.dart, ../../_support/fake_products.dart (+4 more)

### Community 146 - "ReviewPrompter"
Cohesion: 0.22
Nodes (8): StoreReviewPrompter, kAndroidPackage, kAppStoreId, maybeRequestReview, openStoreListing, ReviewPrompter, _FakePrompter, _Prompter

### Community 147 - "migration_test.dart"
Cohesion: 0.18
Nodes (10): generated/schema.dart, package:drift_dev/api/migrations_common.dart, package:drift_dev/api/migrations_native.dart, SchemaVerifier, indexes, main, seedV13, shipped (+2 more)

### Community 148 - "tax_rates_table.dart"
Cohesion: 0.18
Nodes (10): createdAt, id, inclusionType, isActive, isCompound, name, rate, roundingMode (+2 more)

### Community 149 - "bundled_fonts.dart"
Cohesion: 0.18
Nodes (10): bundledFontData, bundledPdfFont, cached, _fontData, future, jetBrainsMonoBold, jetBrainsMonoItalic, jetBrainsMonoRegular (+2 more)

### Community 150 - "State"
Cohesion: 0.32
Nodes (8): AppRoot, AppRootState, _NoticeOverlay, _NoticeOverlayState, _ComponentPickerSheet, _ComponentPickerSheetState, State, StatefulWidget

### Community 151 - "usage_counter_test.dart"
Cohesion: 0.11
Nodes (16): bounds, box, fromLTWH, resolveShareOrigin, screen, shareOriginFor, view, widgetRect (+8 more)

### Community 152 - "customer_picker_sheet.dart"
Cohesion: 0.20
Nodes (10): build, createState, CustomerPickerSheet, _CustomerPickerSheetState, customers, onSelect, _search, selectedId (+2 more)

### Community 153 - "onboardingNotifierProvider"
Cohesion: 0.18
Nodes (12): build, onboardingNotifierProvider, _back, build, _finish, initState, _loadCountries, _next (+4 more)

### Community 154 - "tax_step.dart"
Cohesion: 0.12
Nodes (12): build, BusinessNameStep, controller, build, currencySymbol, nameController, rateController, TaxStep (+4 more)

### Community 155 - "receipt_roll_pdf_test.dart"
Cohesion: 0.18
Nodes (10): package:pdf/pdf.dart, package:pos_app/features/printing/domain/receipt_roll_pdf.dart, package:pos_app/features/printing/domain/render_receipt_image.dart, doc, fmt, main, order, _pageFormats (+2 more)

### Community 156 - "_grammar.dart"
Cohesion: 0.18
Nodes (10): _bucket, _events, expectGrammar, fixed, i, kUsageLineGrammar, _labels, lines (+2 more)

### Community 157 - "tables_dao.dart"
Cohesion: 0.25
Nodes (7): deleteById, getAll, getById, upsert, watchAll, package:pos_app/core/database/tables/tables_table.dart, _

### Community 158 - "customers_dao.dart"
Cohesion: 0.20
Nodes (9): addLoyaltyPoints, getAll, getById, redeemLoyaltyPoints, search, upsert, watchAll, package:pos_app/core/database/tables/customers_table.dart (+1 more)

### Community 159 - "review_providers.dart"
Cohesion: 0.25
Nodes (7): ReviewController, reviewPrompterProvider, storeReviewSupported, package:pos_app/features/review/application/review_controller.dart, package:pos_app/features/review/data/noop_review_prompter.dart, package:pos_app/features/review/data/review_state_store.dart, package:pos_app/features/review/data/store_review_prompter.dart

### Community 160 - "support_contact_test.dart"
Cohesion: 0.25
Nodes (7): package:pos_app/features/help/support_contact.dart, main, no, opened, record, throws, yes

### Community 161 - "_StoreProfileEditScreenState"
Cohesion: 0.42
Nodes (10): businessAddressProvider, businessNameProvider, businessPanProvider, businessPhoneProvider, businessTaglineProvider, didChangeDependencies, _StoreProfileEditScreenState, build (+2 more)

### Community 162 - "country_default.dart"
Cohesion: 0.20
Nodes (9): code, CountryDefault, currency, fromJson, name, symbol, taxName, taxRate (+1 more)

### Community 163 - "package:pos_app/features/printing/domain/receipt_printer.dart"
Cohesion: 0.22
Nodes (8): lastSdkNeedingLocationForBle, permissionsForScan, scanNeedsLocation, package:permission_handler/permission_handler.dart, package:pos_app/features/printing/domain/receipt_printer.dart, package:pos_app/features/printing/domain/scan_permissions.dart, bluetooth, main

### Community 164 - "unit_conversion.dart"
Cohesion: 0.20
Nodes (9): isValidConversionRate, kMaxConversionRate, kMinConversionRate, null, parseConversionRate, text, toInt, validateConversionRate (+1 more)

### Community 165 - "package:pos_app/core/utils/currency_formatter.dart"
Cohesion: 0.12
Nodes (14): build, fmt, _fmtRate, product, UnitPickerSheet, package:pos_app/core/utils/currency_formatter.dart, package:pos_app/features/printing/domain/render_receipt.dart, fmt (+6 more)

### Community 166 - "@visibleForTesting"
Cohesion: 0.22
Nodes (9): @visibleForTesting, debugSetPendingRestoreMerge, customersCsv, expensesCsv, productsCsv, writeOrdersCsv, writeSalesReportCsv, exactAmountText (+1 more)

### Community 167 - "tax_dao.dart"
Cohesion: 0.22
Nodes (8): getAll, getById, getRatesForProduct, setProductTaxes, upsertRate, watchActive, package:pos_app/core/database/tables/product_taxes_table.dart, _

### Community 168 - "categories_table.dart"
Cohesion: 0.22
Nodes (8): Categories, createdAt, id, name, parentId, sortOrder, taxRateId, updatedAt

### Community 169 - "appearance_section.dart"
Cohesion: 0.25
Nodes (8): themeModeProvider, AppearanceSection, build, current, _options, _showThemePicker, _ThemePickerSheet, ThemeMode

### Community 170 - "onboarding_state.dart"
Cohesion: 0.22
Nodes (8): businessName, copyWith, country, saving, step, taxName, taxRate, package:pos_app/features/onboarding/domain/country_default.dart

### Community 171 - "country_step.dart"
Cohesion: 0.22
Nodes (8): build, countries, CountryStep, loading, onSearch, onSelect, searchController, selected

### Community 172 - "Projects Dependencies"
Cohesion: 0.22
Nodes (8): Dev Dependencies, [Hardware] flutter_thermal_printer, Major Dependencies, Outdated / Deprecated Dependencies, Overview, [Persistence] drift, Projects Dependencies, [State Management] flutter_riverpod

### Community 173 - "External Integrations"
Cohesion: 0.22
Nodes (8): APIs & External Services, Authentication & Identity, CI/CD & Deployment, Data Storage, Environment Configuration, External Integrations, Monitoring & Observability, Webhooks & Callbacks

### Community 174 - "package:pos_app/core/database/app_database.dart"
Cohesion: 0.08
Nodes (20): db, _db, log, orderPlaced, orderRefunded, orderVoided, settingChanged, taxOverridden (+12 more)

### Community 175 - "_"
Cohesion: 0.33
Nodes (7): _, compoundTax, invoiceTax, lineItemTax, priceBeforeTax, _round, TaxCalculator

### Community 176 - "Project Conventions"
Cohesion: 0.25
Nodes (7): Database (Drift), External Integrations, Feature Architecture, General Standards, Project Conventions, State Management (Riverpod), UI & UX

### Community 177 - "Technology Stack"
Cohesion: 0.25
Nodes (7): Configuration, Frameworks, Key Dependencies, Languages, Platform Requirements, Runtime, Technology Stack

### Community 178 - "@immutable"
Cohesion: 0.33
Nodes (6): @immutable, ReviewState, ShopSizeCounts, UsageCount, UsageEnvironment, UsageSelection

### Community 179 - "package:pos_app/features/review/domain/review_prompter.dart"
Cohesion: 0.40
Nodes (4): maybeRequestReview, NoopReviewPrompter, openStoreListing, package:pos_app/features/review/domain/review_prompter.dart

### Community 181 - "usage_event.dart"
Cohesion: 0.29
Nodes (6): area, FeatureArea, label, of, UsageEvent, usageEventForRoute

### Community 182 - "dart:convert"
Cohesion: 0.33
Nodes (5): dart:convert, _cache, CountryRepository, load, static List

### Community 183 - "int get"
Cohesion: 0.33
Nodes (5): int get, billNo, displayNo, paymentLabel, String get

### Community 185 - "usage_screen.dart"
Cohesion: 0.09
Nodes (24): shareFilesProvider, build, _confirmReset, _counter, createState, dispose, initState, _message (+16 more)

### Community 187 - "app_root_retry_test.dart"
Cohesion: 0.09
Nodes (20): main, startup, fatal, notice, openStartupStores, recovery, startReviewClock, startUp (+12 more)

### Community 188 - "CLAUDE.md"
Cohesion: 0.50
Nodes (3): Database schema changes, graphify, Offline-first (non-negotiable)

### Community 189 - "app_version.dart"
Cohesion: 0.50
Nodes (3): kAppBuildNumber, kAppVersion, kAppVersionFull

## Knowledge Gaps
- **3862 isolated node(s):** `refresh`, `router`, `usage`, `getKeyboardDismissBehavior`, `_slide` (+3857 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **5 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Return` connect `Return` to `app_database.dart`, `review_policy.dart`, `tron_border.dart`, `render_receipt_image.dart`, `package:pos_app/features/review/domain/review_policy.dart`, `escpos_raster_test.dart`, `usage_summary.dart`, `bundled_fonts.dart`, `calc_oracle.dart`, `usage_counter.dart`, `DataClass`, `unit_conversion.dart`, `app.dart`, `csv_text.dart`, `package:pos_app/core/database/app_database.dart`, `receipt_printer.dart`, `pos_catalog_provider.dart`, `receipt_pdf_service.dart`, `money.dart`, `products_provider.dart`, `usage_providers.dart`, `receipt_roll_pdf.dart`, `escpos_raster.dart`, `render_receipt.dart`?**
  _High betweenness centrality (0.044) - this node is a cross-community bridge._
- **Why does `AppDatabase` connect `package:drift/drift.dart` to `app_database.dart`, `backup_repository.dart`, `backup/share_origin_test.dart`, `package:flutter_test/flutter_test.dart`, `package:pos_app/core/providers/hive_provider.dart`, `most_sold_test.dart`, `package:pos_app/core/database/app_database.dart`, `order_history.dart`, `payment_screen_test.dart`, `report_figures_test.dart`, `audit_dao.dart`, `usage_screen_test.dart`, `DateTime`, `orders_screen_test.dart`, `dart:io`?**
  _High betweenness centrality (0.014) - this node is a cross-community bridge._
- **Why does `cartSessionProvider` connect `cart_notifier.dart` to `inventory_section.dart`, `ConsumerWidget`, `order_summary.dart`, `held_tickets_bar.dart`, `databaseProvider`, `onboardingNotifierProvider`, `VoidCallback?`?**
  _High betweenness centrality (0.005) - this node is a cross-community bridge._
- **What connects `refresh`, `router`, `usage` to the rest of the system?**
  _3862 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `app_database.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.007692307692307693 - nodes in this community are weakly interconnected._
- **Should `schema_v13.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.017094017094017096 - nodes in this community are weakly interconnected._
- **Should `schema_v12.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.017699115044247787 - nodes in this community are weakly interconnected._