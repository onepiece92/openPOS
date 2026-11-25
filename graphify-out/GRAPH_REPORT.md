# Graph Report - agent-a3d526a14688b3540  (2026-11-26)

## Corpus Check
- 326 files · ~256,941 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 5388 nodes · 8645 edges · 194 communities (190 shown, 4 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `a61029e0`
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
- AppDatabase
- package:pos_app/core/providers/hive_provider.dart
- ConsumerWidget
- package:pos_app/core/services/audit_service.dart
- usage_summary.dart
- package:pos_app/core/providers/database_provider.dart
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
- build
- place_order_snapshot_test.dart
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
- usage_host.dart
- settings_screen.dart
- package:flutter/material.dart
- databaseProvider
- pos_catalog_provider.dart
- onboarding_notifier.dart
- backup_screen.dart
- orders_screen_test.dart
- VoidCallback?
- printer_setup_screen.dart
- receipt_pdf_service.dart
- snapshot_photos_test.dart
- IconData?
- orders_table.dart
- money.dart
- onboarding_screen.dart
- products_screen.dart
- _
- package:drift/drift.dart
- products_dao.dart
- link_uris.dart
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
- cart_line_item.dart
- tokens.dart
- _
- receipt_roll_pdf.dart
- snapshot_service_test.dart
- restore_merge_test.dart
- payment_screen_test.dart
- escpos_raster.dart
- cart_item.dart
- article_detail_screen.dart
- DateTimeColumn get
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
- package:flutter_test/flutter_test.dart
- sales.dart
- tax_dao.dart
- learn_screen.dart
- render_receipt.dart
- v1 Roadmap — Flutter Offline-First POS
- DateTime
- settingsProvider
- customers_table.dart
- support_contact.dart
- inventory_screen.dart
- table_selector.dart
- review_policy.dart
- store_profile_edit_screen.dart
- tron_border.dart
- String?
- discount_sheet.dart
- expenses_dao.dart
- order_items_table.dart
- cart_session.dart
- held_orders_notifier.dart
- escpos_raster_test.dart
- auto_print_test.dart
- GeneratedDatabase
- expenses_table.dart
- app_sheet.dart
- audit_log_screen.dart
- review_controller.dart
- usageCounterProvider
- _BackupScreenState
- migration_test.dart
- tax_rates_table.dart
- bundled_fonts.dart
- State
- share_origin.dart
- customer_picker_sheet.dart
- package:pos_app/shared/widgets/app_sheet.dart
- tax_step.dart
- receipt_roll_pdf_test.dart
- _grammar.dart
- tables_dao.dart
- customers_dao.dart
- percent.dart
- receipt_tax_labels_test.dart
- _StoreProfileEditScreenState
- country_default.dart
- _CartScreenState
- unit_conversion.dart
- package:pos_app/core/utils/currency_formatter.dart
- @visibleForTesting
- utils/share_origin_test.dart
- IntColumn get
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
- dart:typed_data
- dashboard_screen.dart
- usage_event.dart
- dart:convert
- int get
- LoyaltySection
- usage_screen.dart
- install_macos.sh
- package:pos_app/features/usage/domain/usage_event.dart
- CLAUDE.md
- app_version.dart
- _DeflatedFile
- _FileSink
- build
- currencies.dart

## God Nodes (most connected - your core abstractions)
1. `AppDatabase` - 48 edges
2. `databaseProvider` - 36 edges
3. `Return` - 31 edges
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

## Communities (194 total, 4 thin omitted)

### Community 0 - "app_database.dart"
Cohesion: 0.01
Nodes (259): class OrderTaxOverride extends, class ProductComponent extends, ColumnFilters, ColumnOrderings, backfillInvoiceNumbers, backfillV14, currentSchemaVersion, migration (+251 more)

### Community 1 - "schema_v13.dart"
Cohesion: 0.02
Nodes (100): StockAdjustments, action, actualTableName, address, _alias, aliasedName, allSchemaEntities, allTables (+92 more)

### Community 2 - "schema_v12.dart"
Cohesion: 0.02
Nodes (117): Index, Tables, action, actualTableName, address, _alias, aliasedName, allSchemaEntities (+109 more)

### Community 3 - "schema_v10.dart"
Cohesion: 0.02
Nodes (114): OrderItems, TaxGroupMembers, action, actualTableName, address, _alias, aliasedName, allSchemaEntities (+106 more)

### Community 4 - "schema_v9.dart"
Cohesion: 0.02
Nodes (113): Categories, ProductVariants, action, actualTableName, address, _alias, aliasedName, allSchemaEntities (+105 more)

### Community 5 - "schema_v8.dart"
Cohesion: 0.02
Nodes (111): AuditLog, ProductModifiers, action, actualTableName, address, _alias, aliasedName, allSchemaEntities (+103 more)

### Community 6 - "schema_v4.dart"
Cohesion: 0.02
Nodes (110): OrderTaxOverrides, TaxGroups, action, actualTableName, address, _alias, aliasedName, allSchemaEntities (+102 more)

### Community 7 - "schema_v15.dart"
Cohesion: 0.02
Nodes (109): action, actualTableName, address, _alias, aliasedName, allSchemaEntities, allTables, amount (+101 more)

### Community 8 - "schema_v7.dart"
Cohesion: 0.02
Nodes (107): Customers, GeneratedColumn, OrderTaxes, Products, action, actualTableName, address, _alias (+99 more)

### Community 9 - "schema_v6.dart"
Cohesion: 0.02
Nodes (106): ExpenseCategories, Orders, ProductTaxes, Returns, TaxRates, action, actualTableName, address (+98 more)

### Community 10 - "schema_v14.dart"
Cohesion: 0.02
Nodes (102): ProductComponents, action, actualTableName, address, _alias, aliasedName, allSchemaEntities, allTables (+94 more)

### Community 11 - "schema_v11.dart"
Cohesion: 0.02
Nodes (116): Expenses, action, actualTableName, address, _alias, aliasedName, allSchemaEntities, allTables (+108 more)

### Community 12 - "snapshot_service.dart"
Cohesion: 0.02
Nodes (87): InputFileStream, _absentSuffix, add, _addDeflated, _addStored, assertNoPendingRestore, _bakSuffix, _baseName (+79 more)

### Community 13 - "Table"
Cohesion: 0.05
Nodes (78): Table, TableInfo, OrderTaxes, OrderTaxOverrides, ProductModifiers, ProductTaxes, StockAdjustments, TaxRates (+70 more)

### Community 14 - "hive_provider.dart"
Cohesion: 0.03
Nodes (76): AppSettings, autoBackupEnabled, autoBackupLastAt, _box, build, businessAddress, businessName, businessNameOrDefault (+68 more)

### Community 15 - "AppDatabase"
Cohesion: 0.05
Nodes (48): _, @DriftDatabase, AppDatabase, AuditService, package:pos_app/features/returns/domain/process_return.dart, package:pos_app/features/returns/domain/void_order.dart, ../../_support/sales.dart, ../../_support/test_db.dart (+40 more)

### Community 16 - "package:pos_app/core/providers/hive_provider.dart"
Cohesion: 0.04
Nodes (51): Box, Directory, _box, formatTicketNumber, heldOrdersBoxProvider, kTicketSeqKey, next, TicketSequence (+43 more)

### Community 17 - "ConsumerWidget"
Cohesion: 0.29
Nodes (12): ConsumerWidget, cartMainUnitQtyProvider, _ListSeparator, build, GridProductTile, _TaxPickerSheet, build, PosProductTile (+4 more)

### Community 18 - "package:pos_app/core/services/audit_service.dart"
Cohesion: 0.06
Nodes (30): left, processReturn, refundableAmount, refunded, transaction, transaction, voidOrder, package:pos_app/core/services/audit_service.dart (+22 more)

### Community 19 - "usage_summary.dart"
Cohesion: 0.04
Nodes (47): appInfo, appVersion, buildUsageSummary, bump, canSendUsageSummary, chars, count, currencyCode (+39 more)

### Community 20 - "package:pos_app/core/providers/database_provider.dart"
Cohesion: 0.08
Nodes (23): _db, DemoDataService, seed, _seedDatabase, _settings, customerId, customers, watch (+15 more)

### Community 21 - "usage_screen_test.dart"
Cohesion: 0.05
Nodes (38): ButtonStyleButton, _grammar.dart, countOf, currentUsageEnvironment, readShopSizeCounts, t, package:pos_app/features/usage/data/usage_inputs.dart, package:pos_app/features/usage/domain/usage_summary.dart (+30 more)

### Community 22 - "held_tickets_bar.dart"
Cohesion: 0.12
Nodes (21): AnimationController, archivedHeldOrdersProvider, heldOrdersProvider, CheckoutBar, build, _buildActiveList, _buildArchivedList, createState (+13 more)

### Community 23 - "calc_oracle.dart"
Cohesion: 0.04
Nodes (46): BigInt, int? discPermille,
  int, balance, base, baseOnHalfCent, bp, cents, d (+38 more)

### Community 24 - "usage_counter.dart"
Cohesion: 0.04
Nodes (47): bool?, after, askedVersion, _box, countingEnabled, countingOn, _counts, _defaultOpen (+39 more)

### Community 25 - "report_data.dart"
Cohesion: 0.04
Nodes (46): avgOrder, changes, chartDates, chartHighlightIndex, chartTitle, chartTotals, costIsIncomplete, costOfGoods (+38 more)

### Community 26 - "expenses_screen.dart"
Cohesion: 0.05
Nodes (46): _amountCtrl, build, categories, category, _CategoryChips, _categoryId, _check, _Chip (+38 more)

### Community 27 - "app_root.dart"
Cohesion: 0.06
Nodes (32): AppRoot, AppRootState, autoBackupDelay, _autoBackupRun, autoBackupScheduledForTest, _autoBackupTimer, build, child (+24 more)

### Community 28 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.06
Nodes (43): activeHeld, cartTableId, tableId, tables, watch, package:flutter_riverpod/flutter_riverpod.dart, package:pos_app/features/cart/data/ticket_sequence.dart, package:pos_app/features/cart/domain/cart_item.dart (+35 more)

### Community 29 - "dart:io"
Cohesion: 0.10
Nodes (19): dart:io, package:flutter/gestures.dart, package:pos_app/core/app_version.dart, package:pos_app/core/restart_notice.dart, package:pos_app/features/help/presentation/support_screen.dart, package:pos_app/features/usage/presentation/usage_host.dart, package:pos_app/features/usage/presentation/usage_screen.dart, main (+11 more)

### Community 30 - "DataClass"
Cohesion: 0.09
Nodes (39): Insertable, OrderNumberX, UpdateCompanion, AuditLogCompanion, AuditLogData, CategoriesCompanion, Category, Customer (+31 more)

### Community 31 - "build"
Cohesion: 0.15
Nodes (20): build, build, build, _loadTicket, build, Route /cart, Route /customers, Route /expenses (+12 more)

### Community 32 - "place_order_snapshot_test.dart"
Cohesion: 0.10
Nodes (17): components, cost, invoicePrefix, placeOrder, roundMoney, transaction, _unitCostNow, package:pos_app/core/utils/money.dart (+9 more)

### Community 33 - "product_form_screen.dart"
Cohesion: 0.06
Nodes (34): _categoryId, _ComponentEntry, _components, _conversionCtrl, createState, _delete, didChangeDependencies, dispose (+26 more)

### Community 34 - "backup_repository.dart"
Cohesion: 0.06
Nodes (34): added, _csvEol, csvImportExplanation, CsvImportReport, db, exportCustomers, exportExpenses, exportOrders (+26 more)

### Community 35 - "backup/share_origin_test.dart"
Cohesion: 0.06
Nodes (30): FormatException, package:pos_app/features/backup/data/backup_repository.dart, package:pos_app/features/backup/data/csv_text.dart, package:pos_app/features/backup/presentation/backup_screen.dart, package:pos_app/features/receipts/presentation/receipt_pdf_service.dart, customers, db, main (+22 more)

### Community 36 - "home.dart"
Cohesion: 0.08
Nodes (26): demoDataServiceProvider, categories, _CategoryRow, _Chip, createState, dispose, _EmptyProductsState, _EmptyProductsStateState (+18 more)

### Community 37 - "app.dart"
Cohesion: 0.07
Nodes (29): ChangeNotifier, GoRouter, AppScrollBehavior, getKeyboardDismissBehavior, ping, POSApp, refresh, router (+21 more)

### Community 38 - "restore_recovery_test.dart"
Cohesion: 0.07
Nodes (31): Exception, FileSystemException, RestoreJournalFormatException, PendingRestoreException, RestoreFatalException, RestoreRolledBackException, SnapshotFormatException, backupOf (+23 more)

### Community 39 - "orders_dao.dart"
Cohesion: 0.06
Nodes (31): completedOrderCount, _escapeLike, getById, getItems, getTaxBreakdown, hasRestockedReturn, historyPage, incrementPrintCount (+23 more)

### Community 40 - "StatelessWidget"
Cohesion: 0.10
Nodes (22): build, cs, key_, _KeyChip, keys, label, _SectionHeader, _ShortcutRow (+14 more)

### Community 41 - "orders_screen.dart"
Cohesion: 0.06
Nodes (37): orderHistoryProvider, _body, build, _clearQuery, createState, cs, customerName, _debounce (+29 more)

### Community 42 - "snapshot_providers.dart"
Cohesion: 0.05
Nodes (37): databaseFile, dir, kDatabaseFileName, openConnection, autoBackupDir, autoBackupLastError, create, createAndShare (+29 more)

### Community 43 - "most_sold_test.dart"
Cohesion: 0.06
Nodes (31): int tea,, package:pos_app/core/services/demo_data_service.dart, package:pos_app/features/review/review_providers.dart, QueryInterceptor, ../../_support/query_recorder.dart, db, expectIndexed, from (+23 more)

### Community 44 - "csv_text.dart"
Cohesion: 0.07
Nodes (29): _bad, boolOf, cell, cellQuoted, _cells, _columns, CsvRow, CsvTable (+21 more)

### Community 45 - "payment_screen.dart"
Cohesion: 0.06
Nodes (40): build, CartDetailScreen, _ClearCartButton, build, createState, customer, dispose, endsWith (+32 more)

### Community 46 - "receipt_printer.dart"
Cohesion: 0.07
Nodes (28): address, data, devices, DiscoveredPrinter, driver, escPosPrinterProvider, fmt, fromKey (+20 more)

### Community 47 - "Milestone 1: v1 (Foundation & Core POS)"
Cohesion: 0.07
Nodes (26): 1. State Management (Riverpod), 2. Navigation (GoRouter), 3. Data Layer (Drift & Hive), 4. Hardware Integration, Core Pillars, Data Flow, Directory Structure, Overview (+18 more)

### Community 48 - "product_tile.dart"
Cohesion: 0.07
Nodes (25): ColorScheme, bg, color, cs, icon, onDecrement, onIncrement, onTap (+17 more)

### Community 49 - "sell_screen_rebuild_test.dart"
Cohesion: 0.08
Nodes (23): AppBar, CustomPaint, FilterChip, GridView, ListView, NavigatorState, package:pos_app/features/cart/presentation/home.dart, package:pos_app/features/cart/presentation/widgets/checkout_bar.dart (+15 more)

### Community 50 - "package:flutter/services.dart"
Cohesion: 0.05
Nodes (39): AndroidSdk, _cached, _methods, _read, sdkInt, _devices, dispose, _methods (+31 more)

### Community 51 - "receipt_screen.dart"
Cohesion: 0.07
Nodes (31): build, businessName, createState, customer, data, db, dispose, fmt (+23 more)

### Community 52 - "audit_dao.dart"
Cohesion: 0.10
Nodes (24): @DriftAccessor, _$AuditDaoMixin, _$CustomersDaoMixin, DatabaseAccessor, _$ExpensesDaoMixin, _$InventoryDaoMixin, AuditDao, log (+16 more)

### Community 53 - "usage_host.dart"
Cohesion: 0.05
Nodes (45): AppLifecycleListener?, dart:async, Duration, DatabaseExitGuard, dispose, handleExitRequest, _listener, timeout (+37 more)

### Community 54 - "settings_screen.dart"
Cohesion: 0.15
Nodes (12): build, SettingsScreen, package:pos_app/features/settings/presentation/widgets/appearance_section.dart, package:pos_app/features/settings/presentation/widgets/backup_section.dart, package:pos_app/features/settings/presentation/widgets/currency_section.dart, package:pos_app/features/settings/presentation/widgets/danger_section.dart, package:pos_app/features/settings/presentation/widgets/inventory_section.dart, package:pos_app/features/settings/presentation/widgets/loyalty_section.dart (+4 more)

### Community 55 - "package:flutter/material.dart"
Cohesion: 0.05
Nodes (36): EditableText, _Badge, bg, customer, CustomerCard, fg, icon, label (+28 more)

### Community 56 - "databaseProvider"
Cohesion: 0.09
Nodes (26): databaseProvider, _save, _delete, _showAddCategoryDialog, categoriesStreamProvider, productsByCategoryProvider, build, CategoriesScreen (+18 more)

### Community 57 - "pos_catalog_provider.dart"
Cohesion: 0.05
Nodes (35): AsyncValue, buildPosSearchIndex, cart, catalogEmpty, categoryId, committedMainUnits, favorites, favoritesOnly (+27 more)

### Community 58 - "onboarding_notifier.dart"
Cohesion: 0.12
Nodes (16): settingsBoxProvider, OnboardingState, back, build, finish, next, OnboardingNotifier, setBusinessName (+8 more)

### Community 59 - "backup_screen.dart"
Cohesion: 0.08
Nodes (24): _BackupTile, _buildInfoCard, color, _confirmAndImport, createState, cs, files, _fmtBytes (+16 more)

### Community 60 - "orders_screen_test.dart"
Cohesion: 0.08
Nodes (22): package:pos_app/features/audit/presentation/audit_log_screen.dart, package:pos_app/features/expenses/presentation/expenses_screen.dart, package:pos_app/features/orders/domain/order_history.dart, package:pos_app/features/orders/presentation/orders_screen.dart, ProviderContainer, add, c, cart (+14 more)

### Community 61 - "VoidCallback?"
Cohesion: 0.13
Nodes (13): build, _labels, onSkip, step, WizardHeader, build, canNext, onBack (+5 more)

### Community 62 - "printer_setup_screen.dart"
Cohesion: 0.08
Nodes (23): PrinterDriver, printerForDriverProvider, createState, _devices, _devicesSub, _disconnectSavedPrinter, dispose, _driver (+15 more)

### Community 63 - "receipt_pdf_service.dart"
Cohesion: 0.08
Nodes (23): baseStyle, billRow, boldStyle, buildReceiptPdf, bytes, customerName, _dataCell, dateFmt (+15 more)

### Community 64 - "snapshot_photos_test.dart"
Cohesion: 0.09
Nodes (21): File, package:sqlite3/sqlite3.dart, backupOf, dbFileIn, entriesOf, hasProduct, hivePathIn, _indexOf (+13 more)

### Community 65 - "IconData?"
Cohesion: 0.09
Nodes (22): Color, IconData?, build, color, cs, icon, KpiCard, label (+14 more)

### Community 66 - "orders_table.dart"
Cohesion: 0.09
Nodes (22): changeAmount, createdAt, customerId, discountIsPercent, discountTotal, discountValue, id, invoiceNo (+14 more)

### Community 67 - "money.dart"
Cohesion: 0.09
Nodes (22): allowZero, byLoss, cents, eps, exact, isRequired, kMaxMoneyAmount, kMaxMoneyAmountLabel (+14 more)

### Community 68 - "onboarding_screen.dart"
Cohesion: 0.08
Nodes (33): build, onboardingNotifierProvider, _back, build, _businessNameCtrl, _canProceed, _countries, createState (+25 more)

### Community 69 - "products_screen.dart"
Cohesion: 0.09
Nodes (22): categories, _CategoryChips, categoryName, _Chip, createState, cs, dispose, fmt (+14 more)

### Community 70 - "_"
Cohesion: 0.10
Nodes (20): dart:math, _, CartCalculator, compute, _roundingModeFor, package:pos_app/core/utils/tax_calculator.dart, package:pos_app/features/cart/domain/cart_calculator.dart, package:pos_app/features/cart/domain/cart_session.dart (+12 more)

### Community 71 - "package:drift/drift.dart"
Cohesion: 0.09
Nodes (20): getAdjustmentsForProduct, logAdjustment, watchLowStock, createdAt, delta, id, notes, productId (+12 more)

### Community 72 - "products_dao.dart"
Cohesion: 0.09
Nodes (21): deductStock, deleteCategory, getAllCategories, getById, getBySku, getComponents, replaceComponents, restock (+13 more)

### Community 73 - "link_uris.dart"
Cohesion: 0.20
Nodes (9): apple, _encode, _lineBreak, mailtoLink, query, smsLink, target, to (+1 more)

### Community 74 - "tables_screen.dart"
Cohesion: 0.10
Nodes (19): _assignToCart, _capacityCtrl, createState, dispose, existing, initState, isCurrentCartTable, isOccupied (+11 more)

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
Cohesion: 0.07
Nodes (38): ticketSequenceProvider, CartSession, addItem, addProduct, addProductInSecondaryUnit, allRates, CartNotifier, CartSessionNotifier (+30 more)

### Community 79 - "order_history.dart"
Cohesion: 0.11
Nodes (19): _changes, copyWith, _db, dispose, error, _generation, hasMore, isLoading (+11 more)

### Community 80 - "products_provider.dart"
Cohesion: 0.10
Nodes (20): applyProductsFilter, clearSearch, copyWith, list, mostSoldWindow, outOfStockOnly, productSalesCountProvider, ProductsFilterNotifier (+12 more)

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
Cohesion: 0.10
Nodes (17): addColor, cs, fmt, label, onTap, ref, _showTaxPicker, summary (+9 more)

### Community 85 - "inventory_card.dart"
Cohesion: 0.10
Nodes (19): _apply, badgeColor, build, canDecrement, canIncrement, cs, _decrement, icon (+11 more)

### Community 86 - "order_detail_screen.dart"
Cohesion: 0.09
Nodes (24): build, businessName, customer, data, db, _DetailData, fmt, isPartlyRefunded (+16 more)

### Community 87 - "thermal_plugin_printer.dart"
Cohesion: 0.10
Nodes (18): _connect, _connectTimeout, devices, _disconnect, _ftp, _pluginDevice, _printPages, printReceipt (+10 more)

### Community 88 - "receipt_body.dart"
Cohesion: 0.10
Nodes (20): _BillRow, build, businessName, customer, data, _DataCell, fmt, _HeaderCell (+12 more)

### Community 89 - "usage_constants.dart"
Cohesion: 0.08
Nodes (23): kFeedbackAreaQuestion, kFeedbackAskAction, kFeedbackAskText, kFeedbackInstruction, kFeedbackMessageMaxLength, kFeedbackSupportRowSubtitle, kFeedbackSupportRowTitle, kOfflineFirstLine (+15 more)

### Community 90 - "Open POS"
Cohesion: 0.10
Nodes (19): Build from source, Contributing, Customers, Features, Get Open POS, License, macOS, Money and reports (+11 more)

### Community 91 - "usage_providers.dart"
Cohesion: 0.07
Nodes (27): dart:ui, ShareFiles, shareFilesWithOs, c, f, launch, link, LinkLauncher (+19 more)

### Community 92 - "customer_form.dart"
Cohesion: 0.12
Nodes (17): _addressCtrl, build, createState, customer, CustomerForm, _CustomerFormState, _delete, _discountCtrl (+9 more)

### Community 93 - "customers_screen.dart"
Cohesion: 0.09
Nodes (24): IconData get, build, _pickCustomer, session, TicketHeader, customersStreamProvider, build, createState (+16 more)

### Community 94 - "cart_line_item.dart"
Cohesion: 0.11
Nodes (17): CurrencyFormatter, decimalDigits, _fmt, format, formatPlain, locale, _plainFmt, symbol (+9 more)

### Community 95 - "tokens.dart"
Cohesion: 0.11
Nodes (18): AppFonts, AppOpacity, heavy, lg, md, medium, mono, Radii (+10 more)

### Community 96 - "_"
Cohesion: 0.11
Nodes (20): _, _abs, bak, begin, cleanup, committed, markCommitted, message (+12 more)

### Community 97 - "receipt_roll_pdf.dart"
Cohesion: 0.08
Nodes (25): base, body, bold, buildReceiptRollPdf, buildTestPageRollPdf, dateFmt, doc, font (+17 more)

### Community 98 - "snapshot_service_test.dart"
Cohesion: 0.11
Nodes (18): package:archive/archive.dart, craftZip, dbFileIn, expectLiveUntouched, expectRejected, hivePathIn, live, main (+10 more)

### Community 99 - "restore_merge_test.dart"
Cohesion: 0.06
Nodes (29): first, kUsageAskMinCompletedSales, kUsageAskMinDaysSinceInstall, shouldAskForFeedback, true, package:pos_app/features/review/domain/review_policy.dart, backupOf, dbFileIn (+21 more)

### Community 100 - "payment_screen_test.dart"
Cohesion: 0.11
Nodes (17): Completer, package:pos_app/core/providers/audit_service_provider.dart, package:pos_app/features/cart/presentation/payment_screen.dart, app, c, confirm, db, gate (+9 more)

### Community 101 - "escpos_raster.dart"
Cohesion: 0.11
Nodes (17): dart:isolate, Future, bytes, cached, canvas, escPosProfile, escPosRasterBytes, escPosRasterBytesSync (+9 more)

### Community 102 - "cart_item.dart"
Cohesion: 0.12
Nodes (16): copyWith, grossAmount, isSecondaryUnit, isTaxable, lineDiscount, lineSubtotal, mainUnitQty, name (+8 more)

### Community 103 - "article_detail_screen.dart"
Cohesion: 0.11
Nodes (17): ArticleDetailScreen, ArticleSection, build, category, cs, heading, icon, readTime (+9 more)

### Community 104 - "DateTimeColumn get"
Cohesion: 0.20
Nodes (9): @DataClassName, DateTimeColumn get, capacity, createdAt, id, name, notes, Tables (+1 more)

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
Nodes (16): FormState, createState, dispose, existing, _formKey, _inclusionType, _nameCtrl, onAdd (+8 more)

### Community 109 - "schema.dart"
Cohesion: 0.12
Nodes (16): package:drift/internal/migrations.dart, schema_v10.dart, schema_v11.dart, schema_v12.dart, schema_v13.dart, schema_v14.dart, schema_v15.dart, schema_v4.dart (+8 more)

### Community 110 - "audit_log_table.dart"
Cohesion: 0.12
Nodes (15): @TableIndex, action, AuditLog, createdAt, entityId, entityType, id, metadata (+7 more)

### Community 111 - "order_taxes_table.dart"
Cohesion: 0.09
Nodes (20): BoolColumn get, color, ExpenseCategories, id, isDefault, name, id, isInclusive (+12 more)

### Community 112 - "inventory_section.dart"
Cohesion: 0.14
Nodes (17): lowStockThresholdProvider, _fitsStock, build, productsFilterProvider, productsStreamProvider, build, ProductsScreen, _ProductsScreenState (+9 more)

### Community 113 - "ConsumerState"
Cohesion: 0.11
Nodes (22): ConsumerState, ConsumerStatefulWidget, CustomersScreen, _CustomersScreenState, ExpensesScreen, PrinterSetupScreen, ProductFormScreen, _ProductFormScreenState (+14 more)

### Community 114 - "_PrinterSetupScreenState"
Cohesion: 0.35
Nodes (10): printerDeviceAddressProvider, printerDeviceNameProvider, printerDriverProvider, printerPaperWidthProvider, receiptPrinterProvider, build, _PrinterSetupScreenState, _printTestPage (+2 more)

### Community 115 - "Return"
Cohesion: 0.15
Nodes (10): initials, name, null, stockCapFor, friendlyPrinterError, known, _match, null (+2 more)

### Community 116 - "support_screen.dart"
Cohesion: 0.08
Nodes (22): build, cs, gradient, icon, _InfoRow, label, onTap, _SectionHeader (+14 more)

### Community 117 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.11
Nodes (14): package:flutter_test/flutter_test.dart, package:pos_app/features/products/domain/stock_level.dart, package:pos_app/features/products/domain/unit_conversion.dart, package:pos_app/features/tax/presentation/tax_settings_screen.dart, main, main, main, product (+6 more)

### Community 118 - "sales.dart"
Cohesion: 0.13
Nodes (14): int? customerId,
  int, line, loyaltyDiscount, paymentMethod, placeOrder, points, pointsRedeemed, pointsToEarn (+6 more)

### Community 119 - "tax_dao.dart"
Cohesion: 0.09
Nodes (21): getAll, getById, getRatesForProduct, setProductTaxes, upsertRate, watchActive, primaryKey, productId (+13 more)

### Community 120 - "learn_screen.dart"
Cohesion: 0.13
Nodes (14): _Article, _ArticleCard, _articles, category, cs, description, icon, LearnScreen (+6 more)

### Community 121 - "render_receipt.dart"
Cohesion: 0.09
Nodes (20): bytes, customerName, g, isCopy, _kv, method, methodLabel, profile (+12 more)

### Community 122 - "v1 Roadmap — Flutter Offline-First POS"
Cohesion: 0.13
Nodes (14): Architecture Decisions, Deferred to v2, Drift Schema — Full Table List (v1), Phase 0 — Foundation (No UI yet), Phase 1 — First-Run & Onboarding, Phase 2 — Product & Inventory Core, Phase 3 — Core Sales Loop, Phase 4 — Receipts & Hardware (+6 more)

### Community 123 - "DateTime"
Cohesion: 0.18
Nodes (13): DateTime, BackupRepository, package:csv/csv.dart, bytesOf, db, legacyAllOrdersWithItems, legacyOrdersCsv, legacySalesReportCsv (+5 more)

### Community 124 - "settingsProvider"
Cohesion: 0.15
Nodes (19): int?, defaultTaxIdProvider, invoicePrefixProvider, settingsProvider, build, reset, skip, _selectDevice (+11 more)

### Community 125 - "customers_table.dart"
Cohesion: 0.14
Nodes (13): address, createdAt, Customers, defaultDiscount, defaultDiscountIsPercent, email, id, isTaxExempt (+5 more)

### Community 126 - "support_contact.dart"
Cohesion: 0.09
Nodes (18): canLaunch, kLinkFailureMessageDuration, _kSupportWhatsAppDigits, kSupportWhatsAppDisplay, kSupportWhatsAppUnavailable, launch, messenger, native (+10 more)

### Community 127 - "inventory_screen.dart"
Cohesion: 0.12
Nodes (16): Iterable, createState, dispose, _filter, _filtered, filterInventoryProducts, InventoryScreen, _InventoryScreenState (+8 more)

### Community 128 - "table_selector.dart"
Cohesion: 0.16
Nodes (16): activeHeldOrdersProvider, build, occupied, onSelect, _pickTable, selectedId, session, _TablePickerSheet (+8 more)

### Community 129 - "review_policy.dart"
Cohesion: 0.12
Nodes (15): at, first, firstLaunchAt, kMinDaysBetweenAnyPrompts, kReviewMinCompletedSales, kReviewMinDaysBetweenPrompts, kReviewMinDaysSinceInstall, last (+7 more)

### Community 130 - "store_profile_edit_screen.dart"
Cohesion: 0.15
Nodes (12): class, _addressCtrl, build, createState, dispose, _initialised, _label, _loading (+4 more)

### Community 131 - "tron_border.dart"
Cohesion: 0.15
Nodes (12): CustomPainter, color, e, extractWrappedPath, f, len, p, paint (+4 more)

### Community 132 - "String?"
Cohesion: 0.12
Nodes (14): double?, action, AppEmptyState, build, icon, subtitle, title, build (+6 more)

### Community 133 - "discount_sheet.dart"
Cohesion: 0.18
Nodes (10): double get, build, createState, _ctrl, currentDiscount, dispose, initState, isPercent (+2 more)

### Community 134 - "expenses_dao.dart"
Cohesion: 0.15
Nodes (12): getAll, getAllCategories, insert, insertCategory, totalForPeriod, updateExpense, upsertCategory, watchAll (+4 more)

### Community 135 - "order_items_table.dart"
Cohesion: 0.15
Nodes (12): discount, id, lineTotal, orderId, productId, productName, quantity, taxAmount (+4 more)

### Community 136 - "cart_session.dart"
Cohesion: 0.15
Nodes (12): copyWith, customerId, fresh, heldTicketId, isEditingHeldTicket, loyaltyPointsToRedeem, openedAt, orderDiscount (+4 more)

### Community 137 - "held_orders_notifier.dart"
Cohesion: 0.15
Nodes (12): HeldOrder, archive, archiveAll, _box, build, delete, deleteAllArchived, hold (+4 more)

### Community 138 - "escpos_raster_test.dart"
Cohesion: 0.15
Nodes (12): package:image/image.dart, StateError, _blockPage, _countSequence, _firstRaster, found, fromList, gsV (+4 more)

### Community 139 - "auto_print_test.dart"
Cohesion: 0.08
Nodes (24): lastSdkNeedingLocationForBle, permissionsForScan, scanNeedsLocation, Object?, package:permission_handler/permission_handler.dart, package:pos_app/features/printing/domain/auto_print.dart, package:pos_app/features/printing/domain/receipt_printer.dart, package:pos_app/features/printing/domain/scan_permissions.dart (+16 more)

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
Cohesion: 0.20
Nodes (11): action, _ActionChip, _actionColor, _actionIcon, AuditLogScreen, auditLogsProvider, build, color (+3 more)

### Community 144 - "review_controller.dart"
Cohesion: 0.05
Nodes (36): bool get, restartNoticeShowing, appVersion, _guard, _inFlight, onReceiptDismissed, prompter, ReviewCheck (+28 more)

### Community 145 - "usageCounterProvider"
Cohesion: 0.24
Nodes (9): auditServiceProvider, _createFullBackup, _runExport, _showDiscountSheet, _save, _DetailBody, _showRefundDialog, _showVoidDialog (+1 more)

### Community 146 - "_BackupScreenState"
Cohesion: 0.33
Nodes (10): autoBackupEnabledProvider, autoBackupLastAtProvider, backupRepositoryProvider, snapshotCoordinatorProvider, _AutoBackupTile, BackupScreen, _BackupScreenState, build (+2 more)

### Community 147 - "migration_test.dart"
Cohesion: 0.14
Nodes (12): generated/schema.dart, package:drift_dev/api/migrations_common.dart, package:drift_dev/api/migrations_native.dart, package:drift/native.dart, SchemaVerifier, indexes, main, seedV13 (+4 more)

### Community 148 - "tax_rates_table.dart"
Cohesion: 0.18
Nodes (10): createdAt, id, inclusionType, isActive, isCompound, name, rate, roundingMode (+2 more)

### Community 149 - "bundled_fonts.dart"
Cohesion: 0.18
Nodes (10): bundledFontData, bundledPdfFont, cached, _fontData, future, jetBrainsMonoBold, jetBrainsMonoItalic, jetBrainsMonoRegular (+2 more)

### Community 150 - "State"
Cohesion: 0.27
Nodes (10): _NoticeOverlay, _NoticeOverlayState, DiscountSheet, _DiscountSheetState, _ReceiptMark, _ReceiptMarkState, _ComponentPickerSheet, _ComponentPickerSheetState (+2 more)

### Community 151 - "share_origin.dart"
Cohesion: 0.18
Nodes (10): bounds, box, fromLTWH, resolveShareOrigin, screen, shareOriginFor, view, widgetRect (+2 more)

### Community 152 - "customer_picker_sheet.dart"
Cohesion: 0.20
Nodes (10): build, createState, CustomerPickerSheet, _CustomerPickerSheetState, customers, onSelect, _search, selectedId (+2 more)

### Community 153 - "package:pos_app/shared/widgets/app_sheet.dart"
Cohesion: 0.24
Nodes (9): currencyCodeProvider, currencySymbolProvider, build, _CurrencyPickerSheet, CurrencySection, current, _showCurrencyPicker, package:pos_app/features/settings/domain/currencies.dart (+1 more)

### Community 154 - "tax_step.dart"
Cohesion: 0.18
Nodes (9): build, BusinessNameStep, controller, build, currencySymbol, nameController, rateController, TaxStep (+1 more)

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

### Community 159 - "percent.dart"
Cohesion: 0.22
Nodes (8): formatPercent, formatPercentNumber, formatRateForEdit, formatRatePercent, kPercentDecimals, kPercentInputPattern, text, RegExp

### Community 160 - "receipt_tax_labels_test.dart"
Cohesion: 0.22
Nodes (8): package:pos_app/features/receipts/domain/receipt_text.dart, audit, db, fmt, main, sale, seq, thermalText

### Community 161 - "_StoreProfileEditScreenState"
Cohesion: 0.42
Nodes (10): businessAddressProvider, businessNameProvider, businessPanProvider, businessPhoneProvider, businessTaglineProvider, didChangeDependencies, _StoreProfileEditScreenState, build (+2 more)

### Community 162 - "country_default.dart"
Cohesion: 0.20
Nodes (9): code, CountryDefault, currency, fromJson, name, symbol, taxName, taxRate (+1 more)

### Community 163 - "_CartScreenState"
Cohesion: 0.33
Nodes (6): posCatalogProvider, posFilterProvider, CartScreen, _CartScreenState, initState, _ProductArea

### Community 164 - "unit_conversion.dart"
Cohesion: 0.20
Nodes (9): isValidConversionRate, kMaxConversionRate, kMinConversionRate, null, parseConversionRate, text, toInt, validateConversionRate (+1 more)

### Community 165 - "package:pos_app/core/utils/currency_formatter.dart"
Cohesion: 0.07
Nodes (26): build, fmt, _fmtRate, product, UnitPickerSheet, doc, escPosPrintWidthDots, isCopy (+18 more)

### Community 166 - "@visibleForTesting"
Cohesion: 0.25
Nodes (8): @visibleForTesting, customersCsv, expensesCsv, productsCsv, writeOrdersCsv, writeSalesReportCsv, exactAmountText, runCheck

### Community 167 - "utils/share_origin_test.dart"
Cohesion: 0.33
Nodes (5): package:pos_app/core/utils/share_origin.dart, expectUsable, ipad, main, screen

### Community 168 - "IntColumn get"
Cohesion: 0.12
Nodes (14): IntColumn get, Categories, createdAt, id, name, parentId, sortOrder, taxRateId (+6 more)

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
Cohesion: 0.13
Nodes (11): db, _db, log, orderPlaced, orderRefunded, orderVoided, settingChanged, taxOverridden (+3 more)

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

### Community 179 - "dart:typed_data"
Cohesion: 0.40
Nodes (4): dart:typed_data, package:pos_app/features/usage/presentation/usage_route_counter.dart, box, page

### Community 180 - "dashboard_screen.dart"
Cohesion: 0.15
Nodes (14): DateTimeRange?, ReportPeriod, ReportPeriodX, reportProvider, build, createState, _customRange, DashboardScreen (+6 more)

### Community 181 - "usage_event.dart"
Cohesion: 0.29
Nodes (6): area, FeatureArea, label, of, UsageEvent, usageEventForRoute

### Community 182 - "dart:convert"
Cohesion: 0.33
Nodes (5): dart:convert, _cache, CountryRepository, load, static List

### Community 183 - "int get"
Cohesion: 0.33
Nodes (5): int get, billNo, displayNo, paymentLabel, String get

### Community 184 - "LoyaltySection"
Cohesion: 0.60
Nodes (5): loyaltyEarnRateProvider, loyaltyEnabledProvider, loyaltyPointValueProvider, build, LoyaltySection

### Community 185 - "usage_screen.dart"
Cohesion: 0.11
Nodes (20): shareFilesProvider, _removeOldSummaryFile, build, _confirmReset, _counter, createState, dispose, initState (+12 more)

### Community 187 - "package:pos_app/features/usage/domain/usage_event.dart"
Cohesion: 0.05
Nodes (47): counts, d, deleteRestoreMergeMarker, finishPendingRestoreMerge, kRestoreMergeMarkerName, _markerFile, null, path (+39 more)

### Community 188 - "CLAUDE.md"
Cohesion: 0.50
Nodes (3): Database schema changes, graphify, Offline-first (non-negotiable)

### Community 189 - "app_version.dart"
Cohesion: 0.50
Nodes (3): kAppBuildNumber, kAppVersion, kAppVersionFull

### Community 192 - "build"
Cohesion: 0.67
Nodes (3): build, MaterialPageRoute, main

## Knowledge Gaps
- **3900 isolated node(s):** `refresh`, `router`, `getKeyboardDismissBehavior`, `_slide`, `ping` (+3895 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **4 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Return` connect `Return` to `app_database.dart`, `review_policy.dart`, `tron_border.dart`, `escpos_raster_test.dart`, `usage_summary.dart`, `bundled_fonts.dart`, `calc_oracle.dart`, `usage_counter.dart`, `DataClass`, `percent.dart`, `unit_conversion.dart`, `app.dart`, `package:pos_app/core/utils/currency_formatter.dart`, `csv_text.dart`, `package:pos_app/core/database/app_database.dart`, `receipt_printer.dart`, `pos_catalog_provider.dart`, `package:pos_app/features/usage/domain/usage_event.dart`, `receipt_pdf_service.dart`, `money.dart`, `products_provider.dart`, `usage_providers.dart`, `receipt_roll_pdf.dart`, `restore_merge_test.dart`, `escpos_raster.dart`, `render_receipt.dart`?**
  _High betweenness centrality (0.046) - this node is a cross-community bridge._
- **Why does `AppDatabase` connect `AppDatabase` to `app_database.dart`, `auto_print_test.dart`, `package:pos_app/core/services/audit_service.dart`, `package:pos_app/core/providers/database_provider.dart`, `usage_screen_test.dart`, `dart:io`, `place_order_snapshot_test.dart`, `receipt_tax_labels_test.dart`, `backup_repository.dart`, `backup/share_origin_test.dart`, `most_sold_test.dart`, `package:pos_app/core/database/app_database.dart`, `audit_dao.dart`, `orders_screen_test.dart`, `package:drift/drift.dart`, `order_history.dart`, `payment_screen_test.dart`, `package:flutter_test/flutter_test.dart`, `DateTime`?**
  _High betweenness centrality (0.012) - this node is a cross-community bridge._
- **Why does `HeldOrdersNotifier` connect `cart_notifier.dart` to `package:pos_app/core/providers/hive_provider.dart`, `held_orders_notifier.dart`, `usageCounterProvider`, `payment_screen.dart`?**
  _High betweenness centrality (0.006) - this node is a cross-community bridge._
- **What connects `refresh`, `router`, `getKeyboardDismissBehavior` to the rest of the system?**
  _3900 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `app_database.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.007692307692307693 - nodes in this community are weakly interconnected._
- **Should `schema_v13.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.019801980198019802 - nodes in this community are weakly interconnected._
- **Should `schema_v12.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.01694915254237288 - nodes in this community are weakly interconnected._