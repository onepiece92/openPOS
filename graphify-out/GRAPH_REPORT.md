# Graph Report - agent-a10234a93b482c14a  (2026-11-25)

## Corpus Check
- 302 files · ~241,315 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 5025 nodes · 7963 edges · 190 communities (185 shown, 5 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `c60ee633`
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
- AppDatabase
- Table
- payment_screen_test.dart
- package:flutter_riverpod/flutter_riverpod.dart
- expenses_screen.dart
- calc_oracle.dart
- pos_filter_provider.dart
- report_data.dart
- IntColumn get
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
- package:flutter_test/flutter_test.dart
- csv_text.dart
- VoidCallback?
- app.dart
- most_sold_test.dart
- app_root.dart
- support_screen.dart
- product_tile.dart
- order_detail_screen.dart
- dart:io
- backup/share_origin_test.dart
- snapshot_providers.dart
- categories_screen.dart
- receipt_roll_pdf.dart
- categories_table.dart
- sell_screen_rebuild_test.dart
- package:pos_app/core/database/app_database.dart
- report_figures_test.dart
- CurrencyFormatter
- receipt_screen.dart
- audit_dao.dart
- pos_catalog_provider.dart
- package:pos_app/features/receipts/presentation/receipt_body.dart
- receipt_pdf_service.dart
- snapshot_service_test.dart
- snapshot_photos_test.dart
- IconData?
- orders_table.dart
- money.dart
- unit_conversion.dart
- onboarding_screen.dart
- package:flutter/services.dart
- products_screen.dart
- Return
- tax_dao.dart
- products_dao.dart
- _
- render_receipt.dart
- tables_screen.dart
- held_tickets_bar.dart
- String?
- held_order.dart
- StatelessWidget
- order_history.dart
- products_provider.dart
- receipt_body.dart
- thermal_plugin_printer.dart
- products_table.dart
- app_theme.dart
- package:intl/intl.dart
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
- package:pos_app/core/providers/database_provider.dart
- order_summary.dart
- ConsumerState
- dashboard_body.dart
- schema.dart
- restore_recovery_test.dart
- order_taxes_table.dart
- package:pos_app/features/orders/domain/order_number.dart
- receipt_tax_labels_test.dart
- package:flutter/foundation.dart
- package:pos_app/shared/widgets/app_sheet.dart
- package:pos_app/core/providers/hive_provider.dart
- package:drift/drift.dart
- dashboard_screen.dart
- settingsProvider
- star_printer.dart
- tax_step.dart
- v1 Roadmap — Flutter Offline-First POS
- package:drift/native.dart
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
- databaseProvider
- DateTime
- GeneratedDatabase
- expenses_table.dart
- app_sheet.dart
- audit_log_screen.dart
- grid_product_tile.dart
- onboardingNotifierProvider
- Milestone 1: v1 (Foundation & Core POS)
- customer_picker_sheet.dart
- tax_rates_table.dart
- _PrinterSetupScreenState
- bundled_fonts.dart
- onboarding_state.dart
- stock_adjustments_table.dart
- review_policy.dart
- receipt_roll_pdf_test.dart
- inventory_screen.dart
- customers_dao.dart
- _StoreProfileEditScreenState
- share_origin.dart
- country_default.dart
- onboarding_notifier.dart
- review_controller.dart
- learn_screen.dart
- close_on_exit.dart
- ConsumerWidget
- app_root_retry_test.dart
- percent.dart
- Projects Dependencies
- External Integrations
- @visibleForTesting
- package:go_router/go_router.dart
- review_controller_test.dart
- country_step.dart
- Project Conventions
- Technology Stack
- dart:ui
- _
- tables_dao.dart
- settings_screen.dart
- dart:convert
- int get
- migration_test.dart
- install_macos.sh
- _DeflatedFile
- CLAUDE.md
- app_version.dart
- currencies.dart
- _FileSink
- review_state_store.dart
- place_order_test.dart
- package:pos_app/core/utils/currency_formatter.dart
- package:pos_app/features/review/domain/review_policy.dart
- utils/share_origin_test.dart
- review_prompter.dart
- main.dart
- SettingsNotifier
- @rebuzzpos

## God Nodes (most connected - your core abstractions)
1. `AppDatabase` - 45 edges
2. `databaseProvider` - 34 edges
3. `_` - 28 edges
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
- `_delete` --references--> `databaseProvider`  [EXTRACTED]
  lib/features/customers/presentation/widgets/customer_form.dart → lib/core/providers/database_provider.dart

## Import Cycles
- None detected.

## Communities (190 total, 5 thin omitted)

### Community 0 - "app_database.dart"
Cohesion: 0.01
Nodes (259): class OrderTaxOverride extends, class ProductComponent extends, ColumnFilters, ColumnOrderings, backfillInvoiceNumbers, backfillV14, currentSchemaVersion, migration (+251 more)

### Community 1 - "schema_v15.dart"
Cohesion: 0.02
Nodes (109): action, actualTableName, address, _alias, aliasedName, allSchemaEntities, allTables, amount (+101 more)

### Community 2 - "schema_v14.dart"
Cohesion: 0.02
Nodes (102): Expenses, action, actualTableName, address, _alias, aliasedName, allSchemaEntities, allTables (+94 more)

### Community 3 - "schema_v10.dart"
Cohesion: 0.02
Nodes (114): Orders, TaxGroupMembers, action, actualTableName, address, _alias, aliasedName, allSchemaEntities (+106 more)

### Community 4 - "schema_v12.dart"
Cohesion: 0.02
Nodes (116): GeneratedColumn, action, actualTableName, address, _alias, aliasedName, allSchemaEntities, allTables (+108 more)

### Community 5 - "schema_v13.dart"
Cohesion: 0.02
Nodes (100): Customers, action, actualTableName, address, _alias, aliasedName, allSchemaEntities, allTables (+92 more)

### Community 6 - "schema_v11.dart"
Cohesion: 0.02
Nodes (118): Index, action, actualTableName, address, _alias, aliasedName, allSchemaEntities, allTables (+110 more)

### Community 7 - "schema_v8.dart"
Cohesion: 0.02
Nodes (111): AuditLog, Returns, Tables, action, actualTableName, address, _alias, aliasedName (+103 more)

### Community 8 - "schema_v9.dart"
Cohesion: 0.02
Nodes (113): OrderTaxes, TaxRates, action, actualTableName, address, _alias, aliasedName, allSchemaEntities (+105 more)

### Community 9 - "schema_v7.dart"
Cohesion: 0.02
Nodes (107): ExpenseCategories, ProductComponents, Products, ProductTaxes, action, actualTableName, address, _alias (+99 more)

### Community 10 - "schema_v4.dart"
Cohesion: 0.02
Nodes (110): ProductModifiers, TaxGroups, action, actualTableName, address, _alias, aliasedName, allSchemaEntities (+102 more)

### Community 11 - "schema_v6.dart"
Cohesion: 0.02
Nodes (106): Categories, OrderItems, OrderTaxOverrides, ProductVariants, StockAdjustments, action, actualTableName, address (+98 more)

### Community 12 - "snapshot_service.dart"
Cohesion: 0.02
Nodes (87): InputFileStream, _absentSuffix, add, _addDeflated, _addStored, assertNoPendingRestore, _bakSuffix, _baseName (+79 more)

### Community 13 - "hive_provider.dart"
Cohesion: 0.03
Nodes (74): autoBackupEnabled, autoBackupLastAt, _box, build, businessAddress, businessName, businessNameOrDefault, businessPan (+66 more)

### Community 14 - "AppDatabase"
Cohesion: 0.04
Nodes (64): _, @DriftDatabase, AppDatabase, AuditService, transaction, voidOrder, package:pos_app/core/services/audit_service.dart, package:pos_app/features/returns/domain/process_return.dart (+56 more)

### Community 15 - "Table"
Cohesion: 0.05
Nodes (77): Table, TableInfo, OrderItems, OrderTaxOverrides, ProductModifiers, ProductTaxes, StockAdjustments, TaxRates (+69 more)

### Community 16 - "payment_screen_test.dart"
Cohesion: 0.11
Nodes (17): Completer, package:pos_app/core/providers/audit_service_provider.dart, package:pos_app/features/cart/presentation/payment_screen.dart, app, c, confirm, db, gate (+9 more)

### Community 17 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.05
Nodes (46): db, package:flutter_riverpod/flutter_riverpod.dart, package:pos_app/core/theme/app_theme.dart, package:pos_app/features/cart/data/place_order.dart, package:pos_app/features/cart/data/ticket_sequence.dart, package:pos_app/features/cart/domain/cart_item.dart, package:pos_app/features/cart/domain/held_order.dart, package:pos_app/features/cart/presentation/pos_cart_actions.dart (+38 more)

### Community 18 - "expenses_screen.dart"
Cohesion: 0.05
Nodes (49): _amountCtrl, build, categories, category, _CategoryChips, _categoryId, _check, _Chip (+41 more)

### Community 19 - "calc_oracle.dart"
Cohesion: 0.04
Nodes (46): BigInt, int? discPermille,
  int, balance, base, baseOnHalfCent, bp, cents, d (+38 more)

### Community 20 - "pos_filter_provider.dart"
Cohesion: 0.11
Nodes (18): clearSearch, copyWith, favoritesOnly, isGrid, PosFilterNotifier, PosFilterState, PosSortMode, search (+10 more)

### Community 21 - "report_data.dart"
Cohesion: 0.04
Nodes (48): avgOrder, changes, chartDates, chartHighlightIndex, chartTitle, chartTotals, costIsIncomplete, costOfGoods (+40 more)

### Community 22 - "IntColumn get"
Cohesion: 0.12
Nodes (14): IntColumn get, action, createdAt, entityId, entityType, id, metadata, newValue (+6 more)

### Community 23 - "DataClass"
Cohesion: 0.09
Nodes (39): Insertable, OrderNumberX, UpdateCompanion, AuditLogCompanion, AuditLogData, CategoriesCompanion, Category, Customer (+31 more)

### Community 24 - "orders_screen.dart"
Cohesion: 0.06
Nodes (37): orderHistoryProvider, _body, build, _clearQuery, createState, cs, customerName, _debounce (+29 more)

### Community 25 - "package:flutter/material.dart"
Cohesion: 0.09
Nodes (20): EditableText, build, SettingsSectionHeader, title, build, ThemePreviewScreen, build, child (+12 more)

### Community 26 - "backup_screen.dart"
Cohesion: 0.07
Nodes (36): autoBackupEnabledProvider, autoBackupLastAtProvider, backupRepositoryProvider, snapshotCoordinatorProvider, _AutoBackupTile, BackupScreen, _BackupScreenState, _BackupTile (+28 more)

### Community 27 - "payment_screen.dart"
Cohesion: 0.07
Nodes (36): build, CartDetailScreen, _ClearCartButton, build, createState, customer, dispose, endsWith (+28 more)

### Community 28 - "backup_repository.dart"
Cohesion: 0.06
Nodes (34): added, _csvEol, csvImportExplanation, CsvImportReport, db, exportCustomers, exportExpenses, exportOrders (+26 more)

### Community 29 - "product_form_screen.dart"
Cohesion: 0.06
Nodes (36): _categoryId, _ComponentEntry, _components, _conversionCtrl, createState, _delete, didChangeDependencies, dispose (+28 more)

### Community 30 - "cart_notifier.dart"
Cohesion: 0.07
Nodes (38): ticketSequenceProvider, CartSession, addItem, addProduct, addProductInSecondaryUnit, allRates, CartNotifier, CartSessionNotifier (+30 more)

### Community 31 - "orders_dao.dart"
Cohesion: 0.06
Nodes (31): completedOrderCount, _escapeLike, getById, getItems, getTaxBreakdown, hasRestockedReturn, historyPage, incrementPrintCount (+23 more)

### Community 32 - "printer_setup_screen.dart"
Cohesion: 0.07
Nodes (29): PrinterDriver, lastSdkNeedingLocationForBle, permissionsForScan, scanNeedsLocation, createState, _devices, _devicesSub, _disconnectSavedPrinter (+21 more)

### Community 33 - "home.dart"
Cohesion: 0.07
Nodes (32): demoDataServiceProvider, posCatalogProvider, posFilterProvider, CartScreen, _CartScreenState, categories, _CategoryRow, _Chip (+24 more)

### Community 34 - "receipt_printer.dart"
Cohesion: 0.07
Nodes (28): address, data, devices, DiscoveredPrinter, driver, escPosPrinterProvider, fmt, fromKey (+20 more)

### Community 35 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.09
Nodes (19): left, processReturn, refundableAmount, refunded, transaction, package:flutter_test/flutter_test.dart, package:pos_app/core/utils/money.dart, package:pos_app/features/products/domain/unit_conversion.dart (+11 more)

### Community 36 - "csv_text.dart"
Cohesion: 0.07
Nodes (29): _bad, boolOf, cell, cellQuoted, _cells, _columns, CsvRow, CsvTable (+21 more)

### Community 37 - "VoidCallback?"
Cohesion: 0.09
Nodes (20): CartItem, build, fmt, icon, item, onPressed, _QtyButton, build (+12 more)

### Community 38 - "app.dart"
Cohesion: 0.07
Nodes (30): ChangeNotifier, GoRouter, AppScrollBehavior, getKeyboardDismissBehavior, ping, POSApp, refresh, routerProvider (+22 more)

### Community 39 - "most_sold_test.dart"
Cohesion: 0.07
Nodes (26): int tea,, package:pos_app/core/services/demo_data_service.dart, QueryInterceptor, ../../_support/query_recorder.dart, db, expectIndexed, from, fullScan (+18 more)

### Community 40 - "app_root.dart"
Cohesion: 0.06
Nodes (30): autoBackupDelay, _autoBackupRun, autoBackupScheduledForTest, _autoBackupTimer, build, child, _closeDatabaseForExit, _container (+22 more)

### Community 41 - "support_screen.dart"
Cohesion: 0.12
Nodes (16): build, cs, gradient, icon, _InfoRow, label, onTap, _SectionHeader (+8 more)

### Community 42 - "product_tile.dart"
Cohesion: 0.07
Nodes (25): ColorScheme, bg, color, cs, icon, onDecrement, onIncrement, onTap (+17 more)

### Community 43 - "order_detail_screen.dart"
Cohesion: 0.10
Nodes (19): businessName, customer, data, db, _DetailData, fmt, isPartlyRefunded, items (+11 more)

### Community 44 - "dart:io"
Cohesion: 0.10
Nodes (18): dart:io, package:pos_app/core/app_version.dart, package:pos_app/features/backup/data/backup_repository.dart, package:pos_app/features/backup/data/csv_text.dart, package:pos_app/features/review/review_providers.dart, main, manifest, rules (+10 more)

### Community 45 - "backup/share_origin_test.dart"
Cohesion: 0.08
Nodes (24): FormatException, package:pos_app/features/backup/data/share_files.dart, package:pos_app/features/backup/presentation/backup_screen.dart, package:pos_app/features/receipts/presentation/receipt_pdf_service.dart, customers, db, main, orders (+16 more)

### Community 46 - "snapshot_providers.dart"
Cohesion: 0.09
Nodes (22): autoBackupDir, autoBackupLastError, create, createAndShare, defaultHiveBoxPaths, docs, inspect, kAutoBackupInterval (+14 more)

### Community 47 - "categories_screen.dart"
Cohesion: 0.13
Nodes (16): categoriesStreamProvider, productsByCategoryProvider, build, CategoriesScreen, category, _CategoryCard, _colorFor, _confirmDelete (+8 more)

### Community 48 - "receipt_roll_pdf.dart"
Cohesion: 0.11
Nodes (18): base, body, bold, buildReceiptRollPdf, buildTestPageRollPdf, dateFmt, doc, font (+10 more)

### Community 49 - "categories_table.dart"
Cohesion: 0.11
Nodes (17): @DataClassName, DateTimeColumn get, Categories, createdAt, id, name, parentId, sortOrder (+9 more)

### Community 50 - "sell_screen_rebuild_test.dart"
Cohesion: 0.08
Nodes (25): AppBar, CustomPaint, FilterChip, GridView, build, ListView, MaterialPageRoute, NavigatorState (+17 more)

### Community 51 - "package:pos_app/core/database/app_database.dart"
Cohesion: 0.08
Nodes (21): _db, log, orderPlaced, orderRefunded, orderVoided, settingChanged, taxOverridden, components (+13 more)

### Community 52 - "report_figures_test.dart"
Cohesion: 0.12
Nodes (14): package:pos_app/features/reports/domain/report_data.dart, package:pos_app/features/reports/presentation/widgets/dashboard_body.dart, audit, c, db, expense, item, main (+6 more)

### Community 53 - "CurrencyFormatter"
Cohesion: 0.18
Nodes (10): CurrencyFormatter, decimalDigits, _fmt, format, formatPlain, locale, _plainFmt, symbol (+2 more)

### Community 54 - "receipt_screen.dart"
Cohesion: 0.09
Nodes (25): build, businessName, createState, customer, data, db, dispose, fmt (+17 more)

### Community 55 - "audit_dao.dart"
Cohesion: 0.10
Nodes (24): @DriftAccessor, _$AuditDaoMixin, _$CustomersDaoMixin, DatabaseAccessor, _$ExpensesDaoMixin, _$InventoryDaoMixin, AuditDao, log (+16 more)

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
Cohesion: 0.11
Nodes (18): package:archive/archive.dart, craftZip, dbFileIn, expectLiveUntouched, expectRejected, hivePathIn, live, main (+10 more)

### Community 60 - "snapshot_photos_test.dart"
Cohesion: 0.09
Nodes (21): File, package:sqlite3/sqlite3.dart, backupOf, dbFileIn, entriesOf, hasProduct, hivePathIn, _indexOf (+13 more)

### Community 61 - "IconData?"
Cohesion: 0.09
Nodes (20): IconData?, action, AppEmptyState, build, icon, subtitle, title, build (+12 more)

### Community 62 - "orders_table.dart"
Cohesion: 0.09
Nodes (22): changeAmount, createdAt, customerId, discountIsPercent, discountTotal, discountValue, id, invoiceNo (+14 more)

### Community 63 - "money.dart"
Cohesion: 0.09
Nodes (22): allowZero, byLoss, cents, eps, exact, isRequired, kMaxMoneyAmount, kMaxMoneyAmountLabel (+14 more)

### Community 64 - "unit_conversion.dart"
Cohesion: 0.20
Nodes (9): isValidConversionRate, kMaxConversionRate, kMinConversionRate, null, parseConversionRate, text, toInt, validateConversionRate (+1 more)

### Community 65 - "onboarding_screen.dart"
Cohesion: 0.09
Nodes (22): _businessNameCtrl, _canProceed, _countries, createState, dispose, _filterCountries, _filtered, _loadingCountries (+14 more)

### Community 66 - "package:flutter/services.dart"
Cohesion: 0.09
Nodes (20): AndroidSdk, _cached, _methods, _read, sdkInt, _devices, dispose, _methods (+12 more)

### Community 67 - "products_screen.dart"
Cohesion: 0.09
Nodes (22): categories, _CategoryChips, categoryName, _Chip, createState, cs, dispose, fmt (+14 more)

### Community 68 - "Return"
Cohesion: 0.15
Nodes (10): initials, name, null, stockCapFor, friendlyPrinterError, known, _match, null (+2 more)

### Community 69 - "tax_dao.dart"
Cohesion: 0.09
Nodes (19): getAll, getById, getRatesForProduct, setProductTaxes, upsertRate, watchActive, primaryKey, productId (+11 more)

### Community 70 - "products_dao.dart"
Cohesion: 0.09
Nodes (21): deductStock, deleteCategory, getAllCategories, getById, getBySku, getComponents, replaceComponents, restock (+13 more)

### Community 71 - "_"
Cohesion: 0.11
Nodes (20): _, _abs, bak, begin, cleanup, committed, markCommitted, message (+12 more)

### Community 72 - "render_receipt.dart"
Cohesion: 0.14
Nodes (13): bytes, customerName, g, isCopy, _kv, method, methodLabel, profile (+5 more)

### Community 73 - "tables_screen.dart"
Cohesion: 0.10
Nodes (21): _assignToCart, _capacityCtrl, createState, dispose, existing, initState, isCurrentCartTable, isOccupied (+13 more)

### Community 74 - "held_tickets_bar.dart"
Cohesion: 0.12
Nodes (21): AnimationController, archivedHeldOrdersProvider, heldOrdersProvider, CheckoutBar, build, _buildActiveList, _buildArchivedList, createState (+13 more)

### Community 75 - "String?"
Cohesion: 0.10
Nodes (19): double?, build, _Chip, color, InventoryFilterBar, label, lowCount, onSelect (+11 more)

### Community 76 - "held_order.dart"
Cohesion: 0.10
Nodes (20): archivedAt, copyWith, createdAt, customerId, customerName, fromJson, id, isArchived (+12 more)

### Community 77 - "StatelessWidget"
Cohesion: 0.10
Nodes (22): build, cs, key_, _KeyChip, keys, label, _SectionHeader, _ShortcutRow (+14 more)

### Community 78 - "order_history.dart"
Cohesion: 0.10
Nodes (20): _changes, copyWith, _db, dispose, error, _generation, hasMore, isLoading (+12 more)

### Community 79 - "products_provider.dart"
Cohesion: 0.10
Nodes (20): applyProductsFilter, clearSearch, copyWith, list, mostSoldWindow, outOfStockOnly, productSalesCountProvider, ProductsFilterNotifier (+12 more)

### Community 80 - "receipt_body.dart"
Cohesion: 0.10
Nodes (19): _BillRow, build, businessName, customer, data, _DataCell, fmt, _HeaderCell (+11 more)

### Community 81 - "thermal_plugin_printer.dart"
Cohesion: 0.10
Nodes (18): dart:async, _connect, _connectTimeout, devices, _disconnect, _ftp, _pluginDevice, _printPages (+10 more)

### Community 82 - "products_table.dart"
Cohesion: 0.10
Nodes (19): categoryId, conversionRate, createdAt, id, imagePath, isActive, isComposite, isHiddenInPos (+11 more)

### Community 83 - "app_theme.dart"
Cohesion: 0.10
Nodes (19): AppTheme, backgroundGradient, _build, ctaButtonStyle, _dark, _darkGrad, _darkScheme, _fontFamily (+11 more)

### Community 84 - "package:intl/intl.dart"
Cohesion: 0.25
Nodes (7): buildReceiptText, dateFmt, join, lines, o, package:intl/intl.dart, package:pos_app/features/receipts/domain/receipt_labels.dart

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
Cohesion: 0.17
Nodes (15): activeHeldOrdersProvider, build, occupied, onSelect, _pickTable, selectedId, session, _TablePickerSheet (+7 more)

### Community 91 - "escpos_raster_test.dart"
Cohesion: 0.11
Nodes (16): dart:typed_data, package:image/image.dart, package:pos_app/core/utils/bundled_fonts.dart, package:pos_app/features/printing/domain/escpos_raster.dart, StateError, main, _blockPage, _countSequence (+8 more)

### Community 92 - "escpos_raster.dart"
Cohesion: 0.11
Nodes (17): dart:isolate, Future, bytes, cached, canvas, escPosProfile, escPosRasterBytes, escPosRasterBytesSync (+9 more)

### Community 93 - "tax_settings_screen.dart"
Cohesion: 0.12
Nodes (15): FormState, createState, dispose, existing, _formKey, _inclusionType, _nameCtrl, onAdd (+7 more)

### Community 94 - "customers_screen.dart"
Cohesion: 0.12
Nodes (17): IconData get, createState, CustomersScreen, _CustomersScreenState, dispose, _filterAndSort, icon, label (+9 more)

### Community 95 - "customer_form.dart"
Cohesion: 0.11
Nodes (18): _addressCtrl, build, createState, customer, CustomerForm, _CustomerFormState, _delete, _discountCtrl (+10 more)

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

### Community 100 - "package:pos_app/core/providers/database_provider.dart"
Cohesion: 0.09
Nodes (18): customerId, customers, watch, build, _confirmReset, activeHeld, cartTableId, tableId (+10 more)

### Community 101 - "order_summary.dart"
Cohesion: 0.09
Nodes (19): addColor, cs, fmt, label, onTap, ref, _showDiscountSheet, _showTaxPicker (+11 more)

### Community 102 - "ConsumerState"
Cohesion: 0.10
Nodes (28): ConsumerState, ConsumerStatefulWidget, lowStockThresholdProvider, _fitsStock, build, InventoryScreen, _InventoryScreenState, PrinterSetupScreen (+20 more)

### Community 103 - "dashboard_body.dart"
Cohesion: 0.12
Nodes (16): ReportData, build, _buildKpiRows, cs, DashboardBody, data, _fmt, isCustomRange (+8 more)

### Community 104 - "schema.dart"
Cohesion: 0.12
Nodes (16): package:drift/internal/migrations.dart, schema_v10.dart, schema_v11.dart, schema_v12.dart, schema_v13.dart, schema_v14.dart, schema_v15.dart, schema_v4.dart (+8 more)

### Community 105 - "restore_recovery_test.dart"
Cohesion: 0.07
Nodes (31): Exception, FileSystemException, RestoreJournalFormatException, PendingRestoreException, RestoreFatalException, RestoreRolledBackException, SnapshotFormatException, backupOf (+23 more)

### Community 106 - "order_taxes_table.dart"
Cohesion: 0.09
Nodes (20): BoolColumn get, color, ExpenseCategories, id, isDefault, name, id, isInclusive (+12 more)

### Community 107 - "package:pos_app/features/orders/domain/order_number.dart"
Cohesion: 0.25
Nodes (7): addBack, customerId, items, label, restockOrderItems, reverseLoyalty, package:pos_app/features/orders/domain/order_number.dart

### Community 108 - "receipt_tax_labels_test.dart"
Cohesion: 0.07
Nodes (28): dart:math, _, CartCalculator, compute, _roundingModeFor, package:pos_app/core/utils/tax_calculator.dart, package:pos_app/features/cart/domain/cart_calculator.dart, package:pos_app/features/cart/domain/cart_session.dart (+20 more)

### Community 109 - "package:flutter/foundation.dart"
Cohesion: 0.12
Nodes (14): apple, _encode, _lineBreak, mailtoLink, query, smsLink, target, to (+6 more)

### Community 110 - "package:pos_app/shared/widgets/app_sheet.dart"
Cohesion: 0.12
Nodes (18): currencyCodeProvider, currencySymbolProvider, build, _CurrencyPickerSheet, CurrencySection, current, _showCurrencyPicker, createState (+10 more)

### Community 111 - "package:pos_app/core/providers/hive_provider.dart"
Cohesion: 0.04
Nodes (47): Box, Directory, _db, DemoDataService, seed, _seedDatabase, _settings, _box (+39 more)

### Community 112 - "package:drift/drift.dart"
Cohesion: 0.13
Nodes (13): getAdjustmentsForProduct, logAdjustment, watchLowStock, package:drift/drift.dart, package:pos_app/core/database/tables/products_table.dart, package:pos_app/core/database/tables/stock_adjustments_table.dart, db, main (+5 more)

### Community 113 - "dashboard_screen.dart"
Cohesion: 0.18
Nodes (12): DateTimeRange?, reportProvider, build, createState, _customRange, DashboardScreen, _DashboardScreenState, _period (+4 more)

### Community 114 - "settingsProvider"
Cohesion: 0.12
Nodes (24): int?, defaultTaxIdProvider, invoicePrefixProvider, loyaltyEarnRateProvider, loyaltyEnabledProvider, loyaltyPointValueProvider, settingsProvider, build (+16 more)

### Community 115 - "star_printer.dart"
Cohesion: 0.10
Nodes (19): SppPrinter, _devices, _discovery, dispose, _events, _found, _isSupported, _methods (+11 more)

### Community 116 - "tax_step.dart"
Cohesion: 0.18
Nodes (9): build, BusinessNameStep, controller, build, currencySymbol, nameController, rateController, TaxStep (+1 more)

### Community 117 - "v1 Roadmap — Flutter Offline-First POS"
Cohesion: 0.13
Nodes (14): Architecture Decisions, Deferred to v2, Drift Schema — Full Table List (v1), Phase 0 — Foundation (No UI yet), Phase 1 — First-Run & Onboarding, Phase 2 — Product & Inventory Core, Phase 3 — Core Sales Loop, Phase 4 — Receipts & Hardware (+6 more)

### Community 118 - "package:drift/native.dart"
Cohesion: 0.20
Nodes (8): databaseFile, dir, kDatabaseFileName, openConnection, package:drift/native.dart, package:path/path.dart, package:path_provider/path_provider.dart, openInMemoryDatabase

### Community 119 - "customers_table.dart"
Cohesion: 0.14
Nodes (13): address, createdAt, Customers, defaultDiscount, defaultDiscountIsPercent, email, id, isTaxExempt (+5 more)

### Community 120 - "store_review_prompter.dart"
Cohesion: 0.10
Nodes (17): _kSupportWhatsAppDigits, kSupportWhatsAppDisplay, native, openSupportWhatsApp, web, _kAndroidListingUrl, maybeRequestReview, openStoreListing (+9 more)

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
Cohesion: 0.07
Nodes (26): CartNotifier get, add, _allowQty, _cart, _committed, _container, _messenger, pickUnit (+18 more)

### Community 130 - "held_orders_notifier.dart"
Cohesion: 0.09
Nodes (21): HeldOrder, archive, archiveAll, _box, build, delete, deleteAllArchived, hold (+13 more)

### Community 131 - "databaseProvider"
Cohesion: 0.13
Nodes (18): auditServiceProvider, databaseProvider, settingsBoxProvider, _delete, _save, _showAddCategoryDialog, finish, _DetailBody (+10 more)

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
Cohesion: 0.10
Nodes (19): Color, action, _ActionChip, _actionColor, _actionIcon, AuditLogScreen, auditLogsProvider, build (+11 more)

### Community 137 - "grid_product_tile.dart"
Cohesion: 0.17
Nodes (10): product, package:pos_app/features/cart/domain/pos_catalog_provider.dart, package:pos_app/features/cart/domain/pos_filter_provider.dart, package:pos_app/features/inventory/presentation/inventory_screen.dart, package:pos_app/features/products/domain/favorites_provider.dart, package:pos_app/shared/widgets/step_button.dart, ids, main (+2 more)

### Community 138 - "onboardingNotifierProvider"
Cohesion: 0.20
Nodes (11): build, onboardingNotifierProvider, _back, build, _finish, initState, _loadCountries, _next (+3 more)

### Community 139 - "Milestone 1: v1 (Foundation & Core POS)"
Cohesion: 0.07
Nodes (26): 1. State Management (Riverpod), 2. Navigation (GoRouter), 3. Data Layer (Drift & Hive), 4. Hardware Integration, Core Pillars, Data Flow, Directory Structure, Overview (+18 more)

### Community 140 - "customer_picker_sheet.dart"
Cohesion: 0.13
Nodes (18): AppRoot, AppRootState, _NoticeOverlay, _NoticeOverlayState, build, createState, CustomerPickerSheet, _CustomerPickerSheetState (+10 more)

### Community 141 - "tax_rates_table.dart"
Cohesion: 0.18
Nodes (10): createdAt, id, inclusionType, isActive, isCompound, name, rate, roundingMode (+2 more)

### Community 142 - "_PrinterSetupScreenState"
Cohesion: 0.20
Nodes (16): printerDeviceAddressProvider, printerDeviceNameProvider, printerDriverProvider, printerPaperWidthProvider, build, _orderDetailProvider, OrderDetailScreen, printerForDriverProvider (+8 more)

### Community 143 - "bundled_fonts.dart"
Cohesion: 0.18
Nodes (10): bundledFontData, bundledPdfFont, cached, _fontData, future, jetBrainsMonoBold, jetBrainsMonoItalic, jetBrainsMonoRegular (+2 more)

### Community 144 - "onboarding_state.dart"
Cohesion: 0.18
Nodes (10): businessName, copyWith, country, OnboardingState, saving, step, taxName, taxRate (+2 more)

### Community 145 - "stock_adjustments_table.dart"
Cohesion: 0.13
Nodes (14): @TableIndex, AuditLog, Expenses, OrderItems, OrderTaxes, Orders, Returns, createdAt (+6 more)

### Community 146 - "review_policy.dart"
Cohesion: 0.18
Nodes (10): first, firstLaunchAt, kReviewMinCompletedSales, kReviewMinDaysBetweenPrompts, kReviewMinDaysSinceInstall, last, lastPromptAt, lastPromptVersion (+2 more)

### Community 147 - "receipt_roll_pdf_test.dart"
Cohesion: 0.18
Nodes (10): package:pdf/pdf.dart, package:pos_app/features/printing/domain/receipt_roll_pdf.dart, package:pos_app/features/printing/domain/render_receipt_image.dart, doc, fmt, main, order, _pageFormats (+2 more)

### Community 148 - "inventory_screen.dart"
Cohesion: 0.13
Nodes (14): Iterable, createState, dispose, _filter, _filtered, filterInventoryProducts, list, _search (+6 more)

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

### Community 153 - "onboarding_notifier.dart"
Cohesion: 0.20
Nodes (9): back, build, next, setBusinessName, setCountry, setSaving, setTaxName, setTaxRate (+1 more)

### Community 154 - "review_controller.dart"
Cohesion: 0.09
Nodes (23): bool get, appVersion, _guard, _inFlight, onReceiptDismissed, prompter, ReviewController, settleDelay (+15 more)

### Community 155 - "learn_screen.dart"
Cohesion: 0.13
Nodes (14): _Article, _ArticleCard, _articles, category, cs, description, icon, LearnScreen (+6 more)

### Community 156 - "close_on_exit.dart"
Cohesion: 0.22
Nodes (8): AppLifecycleListener, Duration, DatabaseExitGuard, dispose, handleExitRequest, _listener, timeout, package:flutter/widgets.dart

### Community 157 - "ConsumerWidget"
Cohesion: 0.14
Nodes (20): ConsumerWidget, themeModeProvider, cartMainUnitQtyProvider, _ListSeparator, build, GridProductTile, _TaxPickerSheet, build (+12 more)

### Community 158 - "app_root_retry_test.dart"
Cohesion: 0.13
Nodes (14): fatal, notice, openStartupStores, recovery, startReviewClock, startUp, StartupResult, wait (+6 more)

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

### Community 163 - "package:go_router/go_router.dart"
Cohesion: 0.10
Nodes (18): _Badge, bg, customer, CustomerCard, fg, icon, label, onEdit (+10 more)

### Community 164 - "review_controller_test.dart"
Cohesion: 0.13
Nodes (14): box, calls, controller, eligible, main, maybeRequestReview, _Mode, now (+6 more)

### Community 165 - "country_step.dart"
Cohesion: 0.22
Nodes (8): build, countries, CountryStep, loading, onSearch, onSelect, searchController, selected

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

### Community 170 - "tables_dao.dart"
Cohesion: 0.25
Nodes (7): deleteById, getAll, getById, upsert, watchAll, package:pos_app/core/database/tables/tables_table.dart, _

### Community 171 - "settings_screen.dart"
Cohesion: 0.15
Nodes (12): build, SettingsScreen, package:pos_app/features/settings/presentation/widgets/appearance_section.dart, package:pos_app/features/settings/presentation/widgets/backup_section.dart, package:pos_app/features/settings/presentation/widgets/currency_section.dart, package:pos_app/features/settings/presentation/widgets/danger_section.dart, package:pos_app/features/settings/presentation/widgets/inventory_section.dart, package:pos_app/features/settings/presentation/widgets/loyalty_section.dart (+4 more)

### Community 172 - "dart:convert"
Cohesion: 0.33
Nodes (5): dart:convert, _cache, CountryRepository, load, static List

### Community 173 - "int get"
Cohesion: 0.33
Nodes (5): int get, billNo, displayNo, paymentLabel, String get

### Community 174 - "migration_test.dart"
Cohesion: 0.18
Nodes (10): generated/schema.dart, package:drift_dev/api/migrations_common.dart, package:drift_dev/api/migrations_native.dart, SchemaVerifier, indexes, main, seedV13, shipped (+2 more)

### Community 177 - "CLAUDE.md"
Cohesion: 0.50
Nodes (3): Database schema changes, graphify, Offline-first (non-negotiable)

### Community 178 - "app_version.dart"
Cohesion: 0.50
Nodes (3): kAppBuildNumber, kAppVersion, kAppVersionFull

### Community 181 - "review_state_store.dart"
Cohesion: 0.18
Nodes (10): _box, _date, ensureFirstLaunch, markPrompted, mergeAfterRestore, mergeReviewStateAfterRestore, read, reviewStateBeforeRestore (+2 more)

### Community 182 - "place_order_test.dart"
Cohesion: 0.25
Nodes (7): audit, db, main, makeItem, makeSession, makeSummary, seedProduct

### Community 183 - "package:pos_app/core/utils/currency_formatter.dart"
Cohesion: 0.29
Nodes (6): build, fmt, _fmtRate, product, UnitPickerSheet, package:pos_app/core/utils/currency_formatter.dart

### Community 184 - "package:pos_app/features/review/domain/review_policy.dart"
Cohesion: 0.29
Nodes (6): package:pos_app/features/review/domain/review_policy.dart, decide, main, now, passing, v

### Community 185 - "utils/share_origin_test.dart"
Cohesion: 0.33
Nodes (5): package:pos_app/core/utils/share_origin.dart, expectUsable, ipad, main, screen

### Community 186 - "review_prompter.dart"
Cohesion: 0.40
Nodes (4): kAndroidPackage, kAppStoreId, maybeRequestReview, openStoreListing

### Community 187 - "main.dart"
Cohesion: 0.40
Nodes (4): main, startup, package:pos_app/app_root.dart, package:pos_app/startup.dart

### Community 188 - "SettingsNotifier"
Cohesion: 0.50
Nodes (4): @immutable, AppSettings, SettingsNotifier, ReviewState

## Knowledge Gaps
- **3609 isolated node(s):** `refresh`, `getKeyboardDismissBehavior`, `_slide`, `ping`, `startupNotice` (+3604 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **5 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Return` connect `Return` to `app_database.dart`, `bundled_fonts.dart`, `package:flutter_riverpod/flutter_riverpod.dart`, `review_policy.dart`, `calc_oracle.dart`, `DataClass`, `percent.dart`, `receipt_printer.dart`, `csv_text.dart`, `receipt_roll_pdf.dart`, `pos_catalog_provider.dart`, `receipt_pdf_service.dart`, `money.dart`, `unit_conversion.dart`, `render_receipt.dart`, `products_provider.dart`, `escpos_raster_test.dart`, `escpos_raster.dart`, `tron_border.dart`, `render_receipt_image.dart`?**
  _High betweenness centrality (0.047) - this node is a cross-community bridge._
- **Why does `CountryDefault` connect `country_default.dart` to `onboarding_state.dart`, `country_step.dart`?**
  _High betweenness centrality (0.021) - this node is a cross-community bridge._
- **Why does `_` connect `_` to `package:flutter/services.dart`, `restore_recovery_test.dart`, `String?`, `dart:convert`, `dart:io`, `package:drift/native.dart`, `cart_notifier.dart`?**
  _High betweenness centrality (0.015) - this node is a cross-community bridge._
- **What connects `refresh`, `getKeyboardDismissBehavior`, `_slide` to the rest of the system?**
  _3609 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `app_database.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.007692307692307693 - nodes in this community are weakly interconnected._
- **Should `schema_v15.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.01818181818181818 - nodes in this community are weakly interconnected._
- **Should `schema_v14.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.019417475728155338 - nodes in this community are weakly interconnected._