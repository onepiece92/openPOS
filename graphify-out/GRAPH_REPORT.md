# Graph Report - agent-a10234a93b482c14a  (2026-11-25)

## Corpus Check
- 301 files · ~238,469 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 5008 nodes · 7930 edges · 181 communities (179 shown, 2 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `62314a58`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- app_database.dart
- schema_v15.dart
- schema_v14.dart
- schema_v10.dart
- schema_v12.dart
- schema_v13.dart
- schema_v11.dart
- schema_v8.dart
- schema_v9.dart
- schema_v7.dart
- schema_v4.dart
- schema_v6.dart
- snapshot_service.dart
- hive_provider.dart
- package:pos_app/core/services/audit_service.dart
- Table
- payment_screen_test.dart
- package:flutter_riverpod/flutter_riverpod.dart
- expenses_screen.dart
- calc_oracle.dart
- package:drift/drift.dart
- report_data.dart
- package:pos_app/features/cart/domain/cart_item.dart
- DataClass
- orders_screen.dart
- package:flutter/material.dart
- backup_screen.dart
- payment_screen.dart
- backup_repository.dart
- product_form_screen.dart
- cart_notifier.dart
- orders_dao.dart
- printer_setup_screen.dart
- home.dart
- receipt_printer.dart
- ConsumerState
- csv_text.dart
- VoidCallback?
- app.dart
- demo_data_service_test.dart
- app_root.dart
- StatelessWidget
- learn_screen.dart
- order_detail_screen.dart
- ConsumerWidget
- backup/share_origin_test.dart
- snapshot_providers.dart
- databaseProvider
- receipt_roll_pdf.dart
- TextColumn get
- sell_screen_rebuild_test.dart
- package:pos_app/core/database/app_database.dart
- package:pos_app/core/providers/database_provider.dart
- package:intl/intl.dart
- receipt_screen.dart
- tables_dao.dart
- pos_catalog_provider.dart
- package:pos_app/features/receipts/presentation/receipt_body.dart
- receipt_pdf_service.dart
- snapshot_service_test.dart
- snapshot_photos_test.dart
- String?
- orders_table.dart
- money.dart
- Return
- onboarding_screen.dart
- package:flutter/services.dart
- products_screen.dart
- csv_import_test.dart
- IntColumn get
- products_dao.dart
- _
- render_receipt.dart
- tables_screen.dart
- held_tickets_bar.dart
- inventory_filter_bar.dart
- held_order.dart
- confirm_step.dart
- order_history.dart
- products_provider.dart
- receipt_body.dart
- thermal_plugin_printer.dart
- products_table.dart
- app_theme.dart
- occupied_tables_test.dart
- cart_summary.dart
- inventory_card.dart
- Open POS
- tokens.dart
- restore_merge_test.dart
- table_selector.dart
- escpos_raster_test.dart
- escpos_raster.dart
- tax_settings_screen.dart
- customers_screen.dart
- customer_form.dart
- article_detail_screen.dart
- build
- returns_table.dart
- cart_item.dart
- product_tile.dart
- order_summary.dart
- inventory_screen.dart
- dashboard_body.dart
- schema.dart
- restore_recovery_test.dart
- order_taxes_table.dart
- package:pos_app/features/orders/domain/order_number.dart
- package:flutter_test/flutter_test.dart
- package:flutter/foundation.dart
- loyalty_section.dart
- auto_print_test.dart
- stock_adjustments_table.dart
- dashboard_screen.dart
- settingsProvider
- star_printer.dart
- review_controller_test.dart
- v1 Roadmap — Flutter Offline-First POS
- migration_test.dart
- customers_table.dart
- store_review_prompter.dart
- store_profile_edit_screen.dart
- tron_border.dart
- render_receipt_image.dart
- discount_sheet.dart
- expenses_dao.dart
- order_items_table.dart
- cart_session.dart
- sales.dart
- pos_cart_actions.dart
- held_orders_notifier.dart
- settings_screen.dart
- DateTime
- GeneratedDatabase
- expenses_table.dart
- app_sheet.dart
- audit_log_screen.dart
- package:pos_app/features/products/domain/products_provider.dart
- onboardingNotifierProvider
- Milestone 1: v1 (Foundation & Core POS)
- List
- tax_rates_table.dart
- _PrinterSetupScreenState
- bundled_fonts.dart
- onboarding_state.dart
- review_state_store.dart
- review_policy.dart
- receipt_roll_pdf_test.dart
- State
- customers_dao.dart
- _StoreProfileEditScreenState
- share_origin.dart
- country_default.dart
- package:pos_app/core/providers/hive_provider.dart
- review_controller.dart
- tax_dao.dart
- dart:async
- currencyFormatterProvider
- categories_table.dart
- percent.dart
- Projects Dependencies
- External Integrations
- @visibleForTesting
- Route /pos
- review_providers.dart
- tax_rate_form_test.dart
- Project Conventions
- Technology Stack
- dart:ui
- _
- audit_dao.dart
- package:pos_app/core/utils/currency_formatter.dart
- dart:convert
- int get
- process_return.dart
- install_macos.sh
- package:pos_app/features/review/domain/review_policy.dart
- CLAUDE.md
- app_version.dart
- currencies.dart
- startup.dart

## God Nodes (most connected - your core abstractions)
1. `AppDatabase` - 45 edges
2. `databaseProvider` - 34 edges
3. `_` - 27 edges
4. `cartSessionProvider` - 26 edges
5. `Return` - 25 edges
6. `currencyFormatterProvider` - 22 edges
7. `settingsProvider` - 20 edges
8. `DataClass` - 19 edges
9. `AuditService` - 19 edges
10. `cartProvider` - 19 edges

## Surprising Connections (you probably didn't know these)
- `_GatedAudit` --inherits--> `AuditService`  [EXTRACTED]
  test/features/cart/payment_screen_test.dart → lib/core/services/audit_service.dart
- `_FixedSessionNotifier` --inherits--> `CartSessionNotifier`  [EXTRACTED]
  test/features/tables/occupied_tables_test.dart → lib/features/cart/presentation/providers/cart_notifier.dart
- `FakeReceiptPrinter` --implements--> `ReceiptPrinter`  [EXTRACTED]
  test/features/printing/auto_print_test.dart → lib/features/printing/domain/receipt_printer.dart
- `_FakePrompter` --implements--> `ReviewPrompter`  [EXTRACTED]
  test/features/review/review_controller_test.dart → lib/features/review/domain/review_prompter.dart
- `_save` --references--> `databaseProvider`  [EXTRACTED]
  lib/features/customers/presentation/widgets/customer_form.dart → lib/core/providers/database_provider.dart

## Import Cycles
- None detected.

## Communities (181 total, 2 thin omitted)

### Community 0 - "app_database.dart"
Cohesion: 0.01
Nodes (259): class OrderTaxOverride extends, class ProductComponent extends, ColumnFilters, ColumnOrderings, backfillInvoiceNumbers, backfillV14, currentSchemaVersion, migration (+251 more)

### Community 1 - "schema_v15.dart"
Cohesion: 0.02
Nodes (109): action, actualTableName, address, _alias, aliasedName, allSchemaEntities, allTables, amount (+101 more)

### Community 2 - "schema_v14.dart"
Cohesion: 0.02
Nodes (102): OrderTaxOverrides, action, actualTableName, address, _alias, aliasedName, allSchemaEntities, allTables (+94 more)

### Community 3 - "schema_v10.dart"
Cohesion: 0.02
Nodes (116): TaxGroupMembers, action, actualTableName, address, _alias, aliasedName, allSchemaEntities, allTables (+108 more)

### Community 4 - "schema_v12.dart"
Cohesion: 0.02
Nodes (116): Expenses, Index, action, actualTableName, address, _alias, aliasedName, allSchemaEntities (+108 more)

### Community 5 - "schema_v13.dart"
Cohesion: 0.02
Nodes (117): Tables, action, actualTableName, address, _alias, aliasedName, allSchemaEntities, allTables (+109 more)

### Community 6 - "schema_v11.dart"
Cohesion: 0.02
Nodes (101): ProductVariants, action, actualTableName, address, _alias, aliasedName, allSchemaEntities, allTables (+93 more)

### Community 7 - "schema_v8.dart"
Cohesion: 0.02
Nodes (109): AuditLog, OrderTaxes, ProductModifiers, action, actualTableName, address, _alias, aliasedName (+101 more)

### Community 8 - "schema_v9.dart"
Cohesion: 0.02
Nodes (113): Categories, Customers, action, actualTableName, address, _alias, aliasedName, allSchemaEntities (+105 more)

### Community 9 - "schema_v7.dart"
Cohesion: 0.02
Nodes (107): GeneratedColumn, OrderItems, ProductComponents, TaxRates, action, actualTableName, address, _alias (+99 more)

### Community 10 - "schema_v4.dart"
Cohesion: 0.02
Nodes (109): Returns, StockAdjustments, TaxGroups, action, actualTableName, address, _alias, aliasedName (+101 more)

### Community 11 - "schema_v6.dart"
Cohesion: 0.02
Nodes (106): ExpenseCategories, Orders, Products, ProductTaxes, action, actualTableName, address, _alias (+98 more)

### Community 12 - "snapshot_service.dart"
Cohesion: 0.02
Nodes (88): FileContent, InputFileStream, _absentSuffix, add, _addDeflated, _addStored, _bakSuffix, _baseName (+80 more)

### Community 13 - "hive_provider.dart"
Cohesion: 0.03
Nodes (74): autoBackupEnabled, autoBackupLastAt, _box, build, businessAddress, businessName, businessNameOrDefault, businessPan (+66 more)

### Community 14 - "package:pos_app/core/services/audit_service.dart"
Cohesion: 0.06
Nodes (42): int tea,, AuditService, transaction, voidOrder, package:pos_app/core/services/audit_service.dart, package:pos_app/features/returns/domain/process_return.dart, package:pos_app/features/returns/domain/void_order.dart, ../../_support/sales.dart (+34 more)

### Community 15 - "Table"
Cohesion: 0.05
Nodes (78): Table, TableInfo, OrderItems, Orders, ProductModifiers, AuditLog, Categories, Customers (+70 more)

### Community 16 - "payment_screen_test.dart"
Cohesion: 0.11
Nodes (17): Completer, package:pos_app/core/providers/audit_service_provider.dart, package:pos_app/features/cart/presentation/payment_screen.dart, app, c, confirm, db, gate (+9 more)

### Community 17 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.06
Nodes (41): Box, Directory, db, customerId, customers, watch, _box, _kFavoriteProductIds (+33 more)

### Community 18 - "expenses_screen.dart"
Cohesion: 0.05
Nodes (49): ConsumerStatefulWidget, _amountCtrl, build, categories, category, _CategoryChips, _categoryId, _check (+41 more)

### Community 19 - "calc_oracle.dart"
Cohesion: 0.04
Nodes (46): BigInt, int? discPermille,
  int, balance, base, baseOnHalfCent, bp, cents, d (+38 more)

### Community 20 - "package:drift/drift.dart"
Cohesion: 0.06
Nodes (37): _, @DriftDatabase, AppDatabase, package:drift/drift.dart, package:pos_app/features/cart/data/place_order.dart, ../../_support/test_db.dart, audit, db (+29 more)

### Community 21 - "report_data.dart"
Cohesion: 0.04
Nodes (48): avgOrder, changes, chartDates, chartHighlightIndex, chartTitle, chartTotals, costIsIncomplete, costOfGoods (+40 more)

### Community 22 - "package:pos_app/features/cart/domain/cart_item.dart"
Cohesion: 0.06
Nodes (34): dart:math, _, CartCalculator, compute, _roundingModeFor, package:pos_app/core/utils/tax_calculator.dart, package:pos_app/features/cart/domain/cart_calculator.dart, package:pos_app/features/cart/domain/cart_item.dart (+26 more)

### Community 23 - "DataClass"
Cohesion: 0.09
Nodes (39): Insertable, OrderNumberX, UpdateCompanion, AuditLogCompanion, AuditLogData, CategoriesCompanion, Category, Customer (+31 more)

### Community 24 - "orders_screen.dart"
Cohesion: 0.07
Nodes (33): orderHistoryProvider, _body, build, _clearQuery, createState, cs, customerName, _debounce (+25 more)

### Community 25 - "package:flutter/material.dart"
Cohesion: 0.06
Nodes (30): _Badge, bg, customer, CustomerCard, fg, icon, label, onEdit (+22 more)

### Community 26 - "backup_screen.dart"
Cohesion: 0.07
Nodes (33): autoBackupEnabledProvider, autoBackupLastAtProvider, backupRepositoryProvider, snapshotCoordinatorProvider, _AutoBackupTile, BackupScreen, _BackupScreenState, build (+25 more)

### Community 27 - "payment_screen.dart"
Cohesion: 0.06
Nodes (41): build, CartDetailScreen, _ClearCartButton, build, createState, customer, dispose, endsWith (+33 more)

### Community 28 - "backup_repository.dart"
Cohesion: 0.06
Nodes (34): added, _csvEol, csvImportExplanation, CsvImportReport, db, exportCustomers, exportExpenses, exportOrders (+26 more)

### Community 29 - "product_form_screen.dart"
Cohesion: 0.06
Nodes (36): _categoryId, _ComponentEntry, _components, _conversionCtrl, createState, _delete, didChangeDependencies, dispose (+28 more)

### Community 30 - "cart_notifier.dart"
Cohesion: 0.08
Nodes (30): addItem, addProduct, addProductInSecondaryUnit, allRates, cartSessionProvider, clear, clearItems, compute (+22 more)

### Community 31 - "orders_dao.dart"
Cohesion: 0.06
Nodes (31): completedOrderCount, _escapeLike, getById, getItems, getTaxBreakdown, hasRestockedReturn, historyPage, incrementPrintCount (+23 more)

### Community 32 - "printer_setup_screen.dart"
Cohesion: 0.08
Nodes (23): PrinterDriver, printerForDriverProvider, createState, _devices, _devicesSub, _disconnectSavedPrinter, dispose, _driver (+15 more)

### Community 33 - "home.dart"
Cohesion: 0.07
Nodes (32): demoDataServiceProvider, posCatalogProvider, posFilterProvider, CartScreen, _CartScreenState, categories, _CategoryRow, _Chip (+24 more)

### Community 34 - "receipt_printer.dart"
Cohesion: 0.07
Nodes (28): address, data, devices, DiscoveredPrinter, driver, escPosPrinterProvider, fmt, fromKey (+20 more)

### Community 35 - "ConsumerState"
Cohesion: 0.11
Nodes (22): ConsumerState, lowStockThresholdProvider, CartNotifier, _fitsStock, build, productsFilterProvider, productsStreamProvider, build (+14 more)

### Community 36 - "csv_text.dart"
Cohesion: 0.07
Nodes (29): _bad, boolOf, cell, cellQuoted, _cells, _columns, CsvRow, CsvTable (+21 more)

### Community 37 - "VoidCallback?"
Cohesion: 0.13
Nodes (13): build, _labels, onSkip, step, WizardHeader, build, canNext, onBack (+5 more)

### Community 38 - "app.dart"
Cohesion: 0.05
Nodes (37): ChangeNotifier, EditableText, GoRouter, AppScrollBehavior, getKeyboardDismissBehavior, ping, POSApp, refresh (+29 more)

### Community 39 - "demo_data_service_test.dart"
Cohesion: 0.08
Nodes (22): package:pos_app/core/services/demo_data_service.dart, QueryInterceptor, ../../_support/query_recorder.dart, db, expectIndexed, from, fullScan, main (+14 more)

### Community 40 - "app_root.dart"
Cohesion: 0.07
Nodes (29): autoBackupDelay, _autoBackupRun, _autoBackupTimer, build, child, _closeDatabaseForExit, _container, createState (+21 more)

### Community 41 - "StatelessWidget"
Cohesion: 0.07
Nodes (33): _BackupTile, _SectionHeader, build, cs, key_, _KeyChip, keys, label (+25 more)

### Community 42 - "learn_screen.dart"
Cohesion: 0.07
Nodes (27): ColorScheme, _Article, _ArticleCard, _articles, category, cs, description, icon (+19 more)

### Community 43 - "order_detail_screen.dart"
Cohesion: 0.09
Nodes (24): auditServiceProvider, businessName, customer, data, db, _DetailBody, _DetailData, fmt (+16 more)

### Community 44 - "ConsumerWidget"
Cohesion: 0.11
Nodes (22): ConsumerWidget, currencyCodeProvider, currencySymbolProvider, themeModeProvider, _ListSeparator, _TaxPickerSheet, SupportScreen, InventoryCard (+14 more)

### Community 45 - "backup/share_origin_test.dart"
Cohesion: 0.07
Nodes (29): dart:io, package:pos_app/core/app_version.dart, package:pos_app/features/backup/data/backup_repository.dart, package:pos_app/features/backup/data/csv_text.dart, package:pos_app/features/backup/data/share_files.dart, package:pos_app/features/backup/presentation/backup_screen.dart, package:pos_app/features/review/review_providers.dart, main (+21 more)

### Community 46 - "snapshot_providers.dart"
Cohesion: 0.07
Nodes (29): databaseFile, dir, kDatabaseFileName, openConnection, autoBackupDir, autoBackupLastError, create, createAndShare (+21 more)

### Community 47 - "databaseProvider"
Cohesion: 0.09
Nodes (26): databaseProvider, _delete, _delete, _save, _showAddCategoryDialog, categoriesStreamProvider, productsByCategoryProvider, build (+18 more)

### Community 48 - "receipt_roll_pdf.dart"
Cohesion: 0.11
Nodes (18): base, body, bold, buildReceiptRollPdf, buildTestPageRollPdf, dateFmt, doc, font (+10 more)

### Community 49 - "TextColumn get"
Cohesion: 0.08
Nodes (23): @DataClassName, DateTimeColumn get, action, createdAt, entityId, entityType, id, metadata (+15 more)

### Community 50 - "sell_screen_rebuild_test.dart"
Cohesion: 0.08
Nodes (25): AppBar, CustomPaint, FilterChip, GridView, build, ListView, MaterialPageRoute, NavigatorState (+17 more)

### Community 51 - "package:pos_app/core/database/app_database.dart"
Cohesion: 0.07
Nodes (23): _db, log, orderPlaced, orderRefunded, orderVoided, settingChanged, taxOverridden, _db (+15 more)

### Community 52 - "package:pos_app/core/providers/database_provider.dart"
Cohesion: 0.06
Nodes (30): package:pos_app/core/providers/database_provider.dart, package:pos_app/features/audit/presentation/audit_log_screen.dart, package:pos_app/features/expenses/presentation/expenses_screen.dart, package:pos_app/features/orders/domain/order_history.dart, package:pos_app/features/reports/domain/report_data.dart, package:pos_app/features/reports/presentation/widgets/dashboard_body.dart, ProviderContainer, audit (+22 more)

### Community 53 - "package:intl/intl.dart"
Cohesion: 0.18
Nodes (10): decimalDigits, _fmt, format, formatPlain, locale, _plainFmt, symbol, tryParse (+2 more)

### Community 54 - "receipt_screen.dart"
Cohesion: 0.09
Nodes (25): build, businessName, createState, customer, data, db, dispose, fmt (+17 more)

### Community 55 - "tables_dao.dart"
Cohesion: 0.08
Nodes (30): @DriftAccessor, _$AuditDaoMixin, _$CustomersDaoMixin, DatabaseAccessor, _$ExpensesDaoMixin, _$InventoryDaoMixin, AuditDao, CustomersDao (+22 more)

### Community 56 - "pos_catalog_provider.dart"
Cohesion: 0.08
Nodes (24): AsyncValue, buildPosSearchIndex, cart, catalogEmpty, categoryId, committedMainUnits, favorites, favoritesOnly (+16 more)

### Community 57 - "package:pos_app/features/receipts/presentation/receipt_body.dart"
Cohesion: 0.13
Nodes (13): AutoPrintService, printOrder, _ref, package:pos_app/features/printing/domain/render_receipt.dart, package:pos_app/features/receipts/presentation/receipt_body.dart, Ref, fmt, item (+5 more)

### Community 58 - "receipt_pdf_service.dart"
Cohesion: 0.08
Nodes (23): baseStyle, billRow, boldStyle, buildReceiptPdf, bytes, customerName, _dataCell, dateFmt (+15 more)

### Community 59 - "snapshot_service_test.dart"
Cohesion: 0.09
Nodes (23): Exception, RestoreJournalFormatException, RestoreFatalException, RestoreRolledBackException, SnapshotFormatException, package:sqlite3/sqlite3.dart, craftZip, dbFileIn (+15 more)

### Community 60 - "snapshot_photos_test.dart"
Cohesion: 0.09
Nodes (21): File, package:archive/archive.dart, backupOf, dbFileIn, entriesOf, hasProduct, hivePathIn, _indexOf (+13 more)

### Community 61 - "String?"
Cohesion: 0.07
Nodes (28): double?, IconData?, action, AppEmptyState, build, icon, subtitle, title (+20 more)

### Community 62 - "orders_table.dart"
Cohesion: 0.09
Nodes (22): changeAmount, createdAt, customerId, discountIsPercent, discountTotal, discountValue, id, invoiceNo (+14 more)

### Community 63 - "money.dart"
Cohesion: 0.09
Nodes (22): allowZero, byLoss, cents, eps, exact, isRequired, kMaxMoneyAmount, kMaxMoneyAmountLabel (+14 more)

### Community 64 - "Return"
Cohesion: 0.12
Nodes (14): initials, name, null, stockCapFor, isValidConversionRate, kMaxConversionRate, kMinConversionRate, null (+6 more)

### Community 65 - "onboarding_screen.dart"
Cohesion: 0.10
Nodes (20): _businessNameCtrl, _canProceed, _countries, createState, dispose, _filterCountries, _filtered, _loadingCountries (+12 more)

### Community 66 - "package:flutter/services.dart"
Cohesion: 0.07
Nodes (25): AndroidSdk, _cached, _methods, _read, sdkInt, _devices, dispose, _methods (+17 more)

### Community 67 - "products_screen.dart"
Cohesion: 0.09
Nodes (22): categories, _CategoryChips, categoryName, _Chip, createState, cs, dispose, fmt (+14 more)

### Community 68 - "csv_import_test.dart"
Cohesion: 0.18
Nodes (10): FormatException, package:pos_app/features/receipts/presentation/receipt_pdf_service.dart, customers, db, main, orders, ordersHeader, products (+2 more)

### Community 69 - "IntColumn get"
Cohesion: 0.10
Nodes (20): IntColumn get, componentProductId, compositeProductId, id, ProductComponents, quantity, primaryKey, productId (+12 more)

### Community 70 - "products_dao.dart"
Cohesion: 0.09
Nodes (21): deductStock, deleteCategory, getAllCategories, getById, getBySku, getComponents, replaceComponents, restock (+13 more)

### Community 71 - "_"
Cohesion: 0.11
Nodes (19): _, _abs, bak, begin, cleanup, committed, markCommitted, message (+11 more)

### Community 72 - "render_receipt.dart"
Cohesion: 0.14
Nodes (13): bytes, customerName, g, isCopy, _kv, method, methodLabel, profile (+5 more)

### Community 73 - "tables_screen.dart"
Cohesion: 0.10
Nodes (21): _assignToCart, _capacityCtrl, createState, dispose, existing, initState, isCurrentCartTable, isOccupied (+13 more)

### Community 74 - "held_tickets_bar.dart"
Cohesion: 0.12
Nodes (21): AnimationController, archivedHeldOrdersProvider, heldOrdersProvider, CheckoutBar, build, _buildActiveList, _buildArchivedList, createState (+13 more)

### Community 75 - "inventory_filter_bar.dart"
Cohesion: 0.10
Nodes (19): Color, build, _Chip, color, InventoryFilterBar, label, lowCount, onSelect (+11 more)

### Community 76 - "held_order.dart"
Cohesion: 0.10
Nodes (20): archivedAt, copyWith, createdAt, customerId, customerName, fromJson, id, isArchived (+12 more)

### Community 77 - "confirm_step.dart"
Cohesion: 0.07
Nodes (22): build, BusinessNameStep, controller, build, children, ConfirmStep, icon, isLast (+14 more)

### Community 78 - "order_history.dart"
Cohesion: 0.06
Nodes (36): clearSearch, copyWith, favoritesOnly, isGrid, PosFilterNotifier, PosFilterState, PosSortMode, search (+28 more)

### Community 79 - "products_provider.dart"
Cohesion: 0.10
Nodes (20): applyProductsFilter, clearSearch, copyWith, list, mostSoldWindow, outOfStockOnly, productSalesCountProvider, ProductsFilterNotifier (+12 more)

### Community 80 - "receipt_body.dart"
Cohesion: 0.10
Nodes (20): _BillRow, build, businessName, customer, data, _DataCell, fmt, _HeaderCell (+12 more)

### Community 81 - "thermal_plugin_printer.dart"
Cohesion: 0.08
Nodes (23): _connect, _connectTimeout, devices, _disconnect, _ftp, _pluginDevice, _printPages, printReceipt (+15 more)

### Community 82 - "products_table.dart"
Cohesion: 0.10
Nodes (19): categoryId, conversionRate, createdAt, id, imagePath, isActive, isComposite, isHiddenInPos (+11 more)

### Community 83 - "app_theme.dart"
Cohesion: 0.10
Nodes (19): AppTheme, backgroundGradient, _build, ctaButtonStyle, _dark, _darkGrad, _darkScheme, _fontFamily (+11 more)

### Community 84 - "occupied_tables_test.dart"
Cohesion: 0.10
Nodes (19): _box, formatTicketNumber, heldOrdersBoxProvider, kTicketSeqKey, next, TicketSequence, ticketSequenceProvider, CartSession (+11 more)

### Community 85 - "cart_summary.dart"
Cohesion: 0.10
Nodes (19): amount, CartSummary, isInclusive, loyaltyDiscount, maxRedeemablePoints, name, orderDiscount, pointsRedeemed (+11 more)

### Community 86 - "inventory_card.dart"
Cohesion: 0.10
Nodes (19): _apply, badgeColor, build, canDecrement, canIncrement, cs, _decrement, icon (+11 more)

### Community 87 - "Open POS"
Cohesion: 0.10
Nodes (19): Build from source, Contributing, Customers, Features, Get Open POS, License, macOS, Money and reports (+11 more)

### Community 88 - "tokens.dart"
Cohesion: 0.11
Nodes (18): AppFonts, AppOpacity, heavy, lg, md, medium, mono, Radii (+10 more)

### Community 89 - "restore_merge_test.dart"
Cohesion: 0.11
Nodes (18): backupOf, dbFileIn, hivePathIn, installedLive, installedOld, live, liveState, main (+10 more)

### Community 90 - "table_selector.dart"
Cohesion: 0.13
Nodes (20): activeHeldOrdersProvider, build, occupied, onSelect, _pickTable, selectedId, session, _TablePickerSheet (+12 more)

### Community 91 - "escpos_raster_test.dart"
Cohesion: 0.11
Nodes (16): dart:typed_data, package:image/image.dart, package:pos_app/core/utils/bundled_fonts.dart, package:pos_app/features/printing/domain/escpos_raster.dart, StateError, main, _blockPage, _countSequence (+8 more)

### Community 92 - "escpos_raster.dart"
Cohesion: 0.11
Nodes (17): dart:isolate, Future, bytes, cached, canvas, escPosProfile, escPosRasterBytes, escPosRasterBytesSync (+9 more)

### Community 93 - "tax_settings_screen.dart"
Cohesion: 0.12
Nodes (17): FormState, createState, dispose, existing, _formKey, _inclusionType, _nameCtrl, onAdd (+9 more)

### Community 94 - "customers_screen.dart"
Cohesion: 0.08
Nodes (26): IconData get, build, _pickCustomer, session, TicketHeader, customersStreamProvider, build, createState (+18 more)

### Community 95 - "customer_form.dart"
Cohesion: 0.12
Nodes (17): _addressCtrl, build, createState, customer, CustomerForm, _CustomerFormState, _discountCtrl, _discountIsPercent (+9 more)

### Community 96 - "article_detail_screen.dart"
Cohesion: 0.11
Nodes (17): ArticleDetailScreen, ArticleSection, build, category, cs, heading, icon, readTime (+9 more)

### Community 97 - "build"
Cohesion: 0.21
Nodes (13): build, build, build, _loadTicket, Route /cart, Route /customers, Route /expenses, Route /help/shortcuts (+5 more)

### Community 98 - "returns_table.dart"
Cohesion: 0.12
Nodes (15): createdAt, id, orderId, OrderTaxOverrides, originalTax, overrideTax, reason, amount (+7 more)

### Community 99 - "cart_item.dart"
Cohesion: 0.12
Nodes (16): copyWith, grossAmount, isSecondaryUnit, isTaxable, lineDiscount, lineSubtotal, mainUnitQty, name (+8 more)

### Community 100 - "product_tile.dart"
Cohesion: 0.12
Nodes (16): product, bg, color, cs, icon, onDecrement, onIncrement, onTap (+8 more)

### Community 101 - "order_summary.dart"
Cohesion: 0.08
Nodes (23): CurrencyFormatter, CartItem, fmt, icon, item, onPressed, _QtyButton, addColor (+15 more)

### Community 102 - "inventory_screen.dart"
Cohesion: 0.12
Nodes (16): Iterable, createState, dispose, _filter, _filtered, filterInventoryProducts, InventoryScreen, _InventoryScreenState (+8 more)

### Community 103 - "dashboard_body.dart"
Cohesion: 0.12
Nodes (16): ReportData, build, _buildKpiRows, cs, DashboardBody, data, _fmt, isCustomRange (+8 more)

### Community 104 - "schema.dart"
Cohesion: 0.12
Nodes (16): package:drift/internal/migrations.dart, schema_v10.dart, schema_v11.dart, schema_v12.dart, schema_v13.dart, schema_v14.dart, schema_v15.dart, schema_v4.dart (+8 more)

### Community 105 - "restore_recovery_test.dart"
Cohesion: 0.06
Nodes (33): FileSystemException, main, startup, package:pos_app/app_root.dart, package:pos_app/features/backup/data/restore_journal.dart, package:pos_app/features/backup/data/snapshot_providers.dart, package:pos_app/features/backup/data/snapshot_service.dart, package:pos_app/startup.dart (+25 more)

### Community 106 - "order_taxes_table.dart"
Cohesion: 0.12
Nodes (14): BoolColumn get, color, ExpenseCategories, id, isDefault, name, id, isInclusive (+6 more)

### Community 107 - "package:pos_app/features/orders/domain/order_number.dart"
Cohesion: 0.13
Nodes (13): buildReceiptText, dateFmt, join, lines, o, addBack, customerId, items (+5 more)

### Community 108 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.09
Nodes (19): package:flutter_test/flutter_test.dart, package:pos_app/core/utils/money.dart, package:pos_app/features/products/domain/stock_level.dart, package:pos_app/features/products/domain/unit_conversion.dart, main, manifest, rules, main (+11 more)

### Community 109 - "package:flutter/foundation.dart"
Cohesion: 0.12
Nodes (14): apple, _encode, _lineBreak, mailtoLink, query, smsLink, target, to (+6 more)

### Community 110 - "loyalty_section.dart"
Cohesion: 0.17
Nodes (14): loyaltyEarnRateProvider, loyaltyEnabledProvider, loyaltyPointValueProvider, build, createState, dispose, _earnCtrl, earnRate (+6 more)

### Community 111 - "auto_print_test.dart"
Cohesion: 0.12
Nodes (15): package:pos_app/features/printing/domain/auto_print.dart, box, db, devices, failWith, main, makeContainer, printed (+7 more)

### Community 112 - "stock_adjustments_table.dart"
Cohesion: 0.13
Nodes (14): @TableIndex, AuditLog, Expenses, OrderItems, OrderTaxes, Orders, Returns, createdAt (+6 more)

### Community 113 - "dashboard_screen.dart"
Cohesion: 0.18
Nodes (12): DateTimeRange?, reportProvider, build, createState, _customRange, DashboardScreen, _DashboardScreenState, _period (+4 more)

### Community 114 - "settingsProvider"
Cohesion: 0.15
Nodes (19): int?, defaultTaxIdProvider, invoicePrefixProvider, settingsProvider, build, reset, skip, _selectDevice (+11 more)

### Community 115 - "star_printer.dart"
Cohesion: 0.10
Nodes (19): SppPrinter, _devices, _discovery, dispose, _events, _found, _isSupported, _methods (+11 more)

### Community 116 - "review_controller_test.dart"
Cohesion: 0.13
Nodes (14): box, calls, controller, eligible, main, maybeRequestReview, _Mode, now (+6 more)

### Community 117 - "v1 Roadmap — Flutter Offline-First POS"
Cohesion: 0.13
Nodes (14): Architecture Decisions, Deferred to v2, Drift Schema — Full Table List (v1), Phase 0 — Foundation (No UI yet), Phase 1 — First-Run & Onboarding, Phase 2 — Product & Inventory Core, Phase 3 — Core Sales Loop, Phase 4 — Receipts & Hardware (+6 more)

### Community 118 - "migration_test.dart"
Cohesion: 0.14
Nodes (12): generated/schema.dart, package:drift_dev/api/migrations_common.dart, package:drift_dev/api/migrations_native.dart, package:drift/native.dart, SchemaVerifier, indexes, main, seedV13 (+4 more)

### Community 119 - "customers_table.dart"
Cohesion: 0.14
Nodes (13): address, createdAt, Customers, defaultDiscount, defaultDiscountIsPercent, email, id, isTaxExempt (+5 more)

### Community 120 - "store_review_prompter.dart"
Cohesion: 0.14
Nodes (12): _kAndroidListingUrl, maybeRequestReview, openStoreListing, _review, package:in_app_review/in_app_review.dart, package:url_launcher/url_launcher.dart, InAppReview, instance (+4 more)

### Community 121 - "store_profile_edit_screen.dart"
Cohesion: 0.15
Nodes (12): class, _addressCtrl, build, createState, dispose, _initialised, _label, _loading (+4 more)

### Community 122 - "tron_border.dart"
Cohesion: 0.15
Nodes (12): CustomPainter, color, e, extractWrappedPath, f, len, p, paint (+4 more)

### Community 123 - "render_receipt_image.dart"
Cohesion: 0.17
Nodes (11): doc, escPosPrintWidthDots, isCopy, kReceiptDpi, pages, _rasterise, renderReceiptImages, renderTestPageImages (+3 more)

### Community 124 - "discount_sheet.dart"
Cohesion: 0.17
Nodes (12): double get, build, createState, _ctrl, currentDiscount, DiscountSheet, _DiscountSheetState, dispose (+4 more)

### Community 125 - "expenses_dao.dart"
Cohesion: 0.15
Nodes (12): getAll, getAllCategories, insert, insertCategory, totalForPeriod, updateExpense, upsertCategory, watchAll (+4 more)

### Community 126 - "order_items_table.dart"
Cohesion: 0.15
Nodes (12): discount, id, lineTotal, orderId, productId, productName, quantity, taxAmount (+4 more)

### Community 127 - "cart_session.dart"
Cohesion: 0.15
Nodes (12): copyWith, customerId, fresh, heldTicketId, isEditingHeldTicket, loyaltyPointsToRedeem, openedAt, orderDiscount (+4 more)

### Community 128 - "sales.dart"
Cohesion: 0.13
Nodes (14): int? customerId,
  int, line, loyaltyDiscount, paymentMethod, placeOrder, points, pointsRedeemed, pointsToEarn (+6 more)

### Community 129 - "pos_cart_actions.dart"
Cohesion: 0.14
Nodes (13): CartNotifier get, add, _allowQty, _cart, _committed, _container, _messenger, pickUnit (+5 more)

### Community 130 - "held_orders_notifier.dart"
Cohesion: 0.15
Nodes (12): HeldOrder, archive, archiveAll, _box, build, delete, deleteAllArchived, hold (+4 more)

### Community 131 - "settings_screen.dart"
Cohesion: 0.15
Nodes (12): build, SettingsScreen, package:pos_app/features/settings/presentation/widgets/appearance_section.dart, package:pos_app/features/settings/presentation/widgets/backup_section.dart, package:pos_app/features/settings/presentation/widgets/currency_section.dart, package:pos_app/features/settings/presentation/widgets/danger_section.dart, package:pos_app/features/settings/presentation/widgets/inventory_section.dart, package:pos_app/features/settings/presentation/widgets/loyalty_section.dart (+4 more)

### Community 132 - "DateTime"
Cohesion: 0.18
Nodes (13): DateTime, BackupRepository, package:csv/csv.dart, bytesOf, db, legacyAllOrdersWithItems, legacyOrdersCsv, legacySalesReportCsv (+5 more)

### Community 133 - "GeneratedDatabase"
Cohesion: 0.17
Nodes (12): GeneratedDatabase, DatabaseAtV10, DatabaseAtV11, DatabaseAtV12, DatabaseAtV13, DatabaseAtV14, DatabaseAtV15, DatabaseAtV4 (+4 more)

### Community 134 - "expenses_table.dart"
Cohesion: 0.17
Nodes (11): amount, categoryId, createdAt, date, id, isRecurring, isTaxDeductible, notes (+3 more)

### Community 135 - "app_sheet.dart"
Cohesion: 0.17
Nodes (10): cs, failurePrefix, messenger, draggable, initialSize, minSize, package:pos_app/shared/widgets/keyboard_safe.dart, required WidgetBuilder builder,
  bool (+2 more)

### Community 136 - "audit_log_screen.dart"
Cohesion: 0.20
Nodes (11): action, _ActionChip, _actionColor, _actionIcon, AuditLogScreen, auditLogsProvider, build, color (+3 more)

### Community 137 - "package:pos_app/features/products/domain/products_provider.dart"
Cohesion: 0.11
Nodes (16): package:pos_app/features/cart/domain/pos_filter_provider.dart, package:pos_app/features/cart/presentation/pos_cart_actions.dart, package:pos_app/features/inventory/presentation/inventory_screen.dart, package:pos_app/features/products/domain/products_provider.dart, ../../_support/fake_products.dart, line, main, qty (+8 more)

### Community 138 - "onboardingNotifierProvider"
Cohesion: 0.22
Nodes (9): onboardingNotifierProvider, _back, build, initState, _loadCountries, _next, OnboardingScreen, _OnboardingScreenState (+1 more)

### Community 139 - "Milestone 1: v1 (Foundation & Core POS)"
Cohesion: 0.07
Nodes (26): 1. State Management (Riverpod), 2. Navigation (GoRouter), 3. Data Layer (Drift & Hive), 4. Hardware Integration, Core Pillars, Data Flow, Directory Structure, Overview (+18 more)

### Community 140 - "List"
Cohesion: 0.08
Nodes (22): build, createState, customers, onSelect, _search, selectedId, build, countries (+14 more)

### Community 141 - "tax_rates_table.dart"
Cohesion: 0.18
Nodes (10): createdAt, id, inclusionType, isActive, isCompound, name, rate, roundingMode (+2 more)

### Community 142 - "_PrinterSetupScreenState"
Cohesion: 0.25
Nodes (13): printerDeviceAddressProvider, printerDeviceNameProvider, printerDriverProvider, printerPaperWidthProvider, build, receiptPrinterProvider, build, PrinterSetupScreen (+5 more)

### Community 143 - "bundled_fonts.dart"
Cohesion: 0.18
Nodes (10): bundledFontData, bundledPdfFont, cached, _fontData, future, jetBrainsMonoBold, jetBrainsMonoItalic, jetBrainsMonoRegular (+2 more)

### Community 144 - "onboarding_state.dart"
Cohesion: 0.22
Nodes (8): businessName, copyWith, country, saving, step, taxName, taxRate, package:pos_app/features/onboarding/domain/country_default.dart

### Community 145 - "review_state_store.dart"
Cohesion: 0.18
Nodes (10): _box, _date, ensureFirstLaunch, markPrompted, mergeAfterRestore, mergeReviewStateAfterRestore, read, reviewStateBeforeRestore (+2 more)

### Community 146 - "review_policy.dart"
Cohesion: 0.18
Nodes (10): first, firstLaunchAt, kReviewMinCompletedSales, kReviewMinDaysBetweenPrompts, kReviewMinDaysSinceInstall, last, lastPromptAt, lastPromptVersion (+2 more)

### Community 147 - "receipt_roll_pdf_test.dart"
Cohesion: 0.18
Nodes (10): package:pdf/pdf.dart, package:pos_app/features/printing/domain/receipt_roll_pdf.dart, package:pos_app/features/printing/domain/render_receipt_image.dart, doc, fmt, main, order, _pageFormats (+2 more)

### Community 148 - "State"
Cohesion: 0.23
Nodes (12): AppRoot, AppRootState, _NoticeOverlay, _NoticeOverlayState, CustomerPickerSheet, _CustomerPickerSheetState, _ReceiptMark, _ReceiptMarkState (+4 more)

### Community 149 - "customers_dao.dart"
Cohesion: 0.20
Nodes (9): addLoyaltyPoints, getAll, getById, redeemLoyaltyPoints, search, upsert, watchAll, package:pos_app/core/database/tables/customers_table.dart (+1 more)

### Community 150 - "_StoreProfileEditScreenState"
Cohesion: 0.42
Nodes (10): businessAddressProvider, businessNameProvider, businessPanProvider, businessPhoneProvider, businessTaglineProvider, didChangeDependencies, _StoreProfileEditScreenState, build (+2 more)

### Community 151 - "share_origin.dart"
Cohesion: 0.20
Nodes (9): bounds, box, fromLTWH, resolveShareOrigin, screen, shareOriginFor, view, widgetRect (+1 more)

### Community 152 - "country_default.dart"
Cohesion: 0.20
Nodes (9): code, CountryDefault, currency, fromJson, name, symbol, taxName, taxRate (+1 more)

### Community 153 - "package:pos_app/core/providers/hive_provider.dart"
Cohesion: 0.09
Nodes (25): @immutable, AppSettings, settingsBoxProvider, SettingsNotifier, SelectedTaxRatesNotifier, OnboardingState, back, build (+17 more)

### Community 154 - "review_controller.dart"
Cohesion: 0.10
Nodes (19): appVersion, _guard, _inFlight, onReceiptDismissed, prompter, settleDelay, store, timeout (+11 more)

### Community 155 - "tax_dao.dart"
Cohesion: 0.22
Nodes (8): getAll, getById, getRatesForProduct, setProductTaxes, upsertRate, watchActive, package:pos_app/core/database/tables/product_taxes_table.dart, _

### Community 156 - "dart:async"
Cohesion: 0.15
Nodes (11): AppLifecycleListener, dart:async, Duration, DatabaseExitGuard, dispose, handleExitRequest, _listener, timeout (+3 more)

### Community 157 - "currencyFormatterProvider"
Cohesion: 0.57
Nodes (7): cartMainUnitQtyProvider, build, GridProductTile, build, PosProductTile, favoritesProvider, currencyFormatterProvider

### Community 158 - "categories_table.dart"
Cohesion: 0.22
Nodes (8): Categories, createdAt, id, name, parentId, sortOrder, taxRateId, updatedAt

### Community 159 - "percent.dart"
Cohesion: 0.22
Nodes (8): formatPercent, formatPercentNumber, formatRateForEdit, formatRatePercent, kPercentDecimals, kPercentInputPattern, text, RegExp

### Community 160 - "Projects Dependencies"
Cohesion: 0.22
Nodes (8): Dev Dependencies, [Hardware] flutter_thermal_printer, Major Dependencies, Outdated / Deprecated Dependencies, Overview, [Persistence] drift, Projects Dependencies, [State Management] flutter_riverpod

### Community 161 - "External Integrations"
Cohesion: 0.22
Nodes (8): APIs & External Services, Authentication & Identity, CI/CD & Deployment, Data Storage, Environment Configuration, External Integrations, Monitoring & Observability, Webhooks & Callbacks

### Community 162 - "@visibleForTesting"
Cohesion: 0.25
Nodes (8): @visibleForTesting, customersCsv, expensesCsv, productsCsv, writeOrdersCsv, writeSalesReportCsv, exactAmountText, runCheck

### Community 163 - "Route /pos"
Cohesion: 0.40
Nodes (5): build, _finish, _skip, build, Route /pos

### Community 164 - "review_providers.dart"
Cohesion: 0.25
Nodes (7): bool get, ReviewController, reviewPrompterProvider, storeReviewSupported, package:pos_app/features/review/application/review_controller.dart, package:pos_app/features/review/data/noop_review_prompter.dart, package:pos_app/features/review/data/store_review_prompter.dart

### Community 165 - "tax_rate_form_test.dart"
Cohesion: 0.25
Nodes (7): package:pos_app/features/tax/presentation/tax_settings_screen.dart, create, db, main, pumpForm, rateField, TextFormField

### Community 166 - "Project Conventions"
Cohesion: 0.25
Nodes (7): Database (Drift), External Integrations, Feature Architecture, General Standards, Project Conventions, State Management (Riverpod), UI & UX

### Community 167 - "Technology Stack"
Cohesion: 0.25
Nodes (7): Configuration, Frameworks, Key Dependencies, Languages, Platform Requirements, Runtime, Technology Stack

### Community 168 - "dart:ui"
Cohesion: 0.29
Nodes (6): dart:ui, ShareFiles, shareFilesProvider, shareFilesWithOs, package:share_plus/share_plus.dart, typedef

### Community 169 - "_"
Cohesion: 0.33
Nodes (7): _, compoundTax, invoiceTax, lineItemTax, priceBeforeTax, _round, TaxCalculator

### Community 170 - "audit_dao.dart"
Cohesion: 0.29
Nodes (6): log, queryByDateRange, queryByEntity, watchRecent, package:pos_app/core/database/tables/audit_log_table.dart, _

### Community 171 - "package:pos_app/core/utils/currency_formatter.dart"
Cohesion: 0.29
Nodes (6): build, fmt, _fmtRate, product, UnitPickerSheet, package:pos_app/core/utils/currency_formatter.dart

### Community 172 - "dart:convert"
Cohesion: 0.33
Nodes (5): dart:convert, _cache, CountryRepository, load, static List

### Community 173 - "int get"
Cohesion: 0.33
Nodes (5): int get, billNo, displayNo, paymentLabel, String get

### Community 174 - "process_return.dart"
Cohesion: 0.29
Nodes (6): left, processReturn, refundableAmount, refunded, transaction, package:pos_app/features/returns/domain/reverse_sale.dart

### Community 176 - "package:pos_app/features/review/domain/review_policy.dart"
Cohesion: 0.29
Nodes (6): package:pos_app/features/review/domain/review_policy.dart, decide, main, now, passing, v

### Community 177 - "CLAUDE.md"
Cohesion: 0.50
Nodes (3): Database schema changes, graphify, Offline-first (non-negotiable)

### Community 178 - "app_version.dart"
Cohesion: 0.50
Nodes (3): kAppBuildNumber, kAppVersion, kAppVersionFull

### Community 183 - "startup.dart"
Cohesion: 0.22
Nodes (8): fatal, notice, openStartupStores, recovery, startUp, StartupResult, wait, package:pos_app/features/review/data/review_state_store.dart

## Knowledge Gaps
- **3596 isolated node(s):** `refresh`, `getKeyboardDismissBehavior`, `_slide`, `ping`, `startupNotice` (+3591 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **2 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Return` connect `Return` to `app_database.dart`, `bundled_fonts.dart`, `package:flutter_riverpod/flutter_riverpod.dart`, `review_policy.dart`, `calc_oracle.dart`, `DataClass`, `percent.dart`, `receipt_printer.dart`, `csv_text.dart`, `receipt_roll_pdf.dart`, `pos_catalog_provider.dart`, `receipt_pdf_service.dart`, `money.dart`, `package:flutter/services.dart`, `render_receipt.dart`, `products_provider.dart`, `escpos_raster_test.dart`, `escpos_raster.dart`, `tron_border.dart`, `render_receipt_image.dart`?**
  _High betweenness centrality (0.037) - this node is a cross-community bridge._
- **Why does `_` connect `_` to `package:flutter/services.dart`, `List`, `dart:convert`, `backup/share_origin_test.dart`, `snapshot_providers.dart`, `snapshot_service_test.dart`, `String?`?**
  _High betweenness centrality (0.015) - this node is a cross-community bridge._
- **Why does `AppDatabase` connect `package:drift/drift.dart` to `app_database.dart`, `csv_import_test.dart`, `DateTime`, `tax_rate_form_test.dart`, `demo_data_service_test.dart`, `package:flutter_test/flutter_test.dart`, `backup/share_origin_test.dart`, `order_history.dart`, `package:pos_app/core/services/audit_service.dart`, `payment_screen_test.dart`, `package:flutter_riverpod/flutter_riverpod.dart`, `auto_print_test.dart`, `package:pos_app/core/database/app_database.dart`, `package:pos_app/core/providers/database_provider.dart`, `package:pos_app/features/cart/domain/cart_item.dart`, `tables_dao.dart`, `backup_repository.dart`?**
  _High betweenness centrality (0.014) - this node is a cross-community bridge._
- **What connects `refresh`, `getKeyboardDismissBehavior`, `_slide` to the rest of the system?**
  _3596 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `app_database.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.007692307692307693 - nodes in this community are weakly interconnected._
- **Should `schema_v15.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.01818181818181818 - nodes in this community are weakly interconnected._
- **Should `schema_v14.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.019417475728155338 - nodes in this community are weakly interconnected._