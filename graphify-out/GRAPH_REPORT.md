# Graph Report - integration-1.2.0  (2026-11-26)

## Corpus Check
- 357 files · ~293,444 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 6067 nodes · 9813 edges · 207 communities (203 shown, 4 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `84dfe096`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- app_database.dart
- schema_v16.dart
- schema_v14.dart
- schema_v11.dart
- schema_v12.dart
- schema_v13.dart
- schema_v10.dart
- schema_v9.dart
- schema_v8.dart
- schema_v15.dart
- schema_v4.dart
- schema_v7.dart
- schema_v6.dart
- package:flutter_riverpod/flutter_riverpod.dart
- snapshot_service.dart
- hive_provider.dart
- AppDatabase
- shifts_dao.dart
- Table
- usage_counter.dart
- ConsumerWidget
- package:pos_app/core/database/app_database.dart
- report_data.dart
- package:pos_app/features/cart/domain/cart_item.dart
- cart_notifier.dart
- usage_summary.dart
- app.dart
- calc_oracle.dart
- review_controller_test.dart
- expenses_screen.dart
- package:pos_app/core/providers/database_provider.dart
- DataClass
- most_sold_test.dart
- package:flutter/material.dart
- _
- usage_providers.dart
- StatelessWidget
- VoidCallback?
- orders_screen.dart
- support_contact.dart
- tables_dao.dart
- feature_flags.dart
- backup_repository.dart
- product_form_screen.dart
- usage_screen.dart
- backup/share_origin_test.dart
- features_screen.dart
- payment_screen.dart
- restore_recovery_test.dart
- orders_dao.dart
- backup_screen.dart
- held_tickets_bar.dart
- IconData?
- ConsumerState
- app_root.dart
- restore_merge_test.dart
- receipt_printer.dart
- printer_setup_screen.dart
- package:pos_app/core/utils/currency_formatter.dart
- csv_text.dart
- onboarding_screen.dart
- restore_merge_marker_test.dart
- Milestone 1: v1 (Foundation & Core POS)
- build
- databaseProvider
- snapshot_providers.dart
- orders_table.dart
- receipt_pdf_service.dart
- order_items_table.dart
- home.dart
- order_detail_screen.dart
- usage_constants.dart
- package:flutter_test/flutter_test.dart
- pos_catalog_provider.dart
- settingsProvider
- review_state_store.dart
- usage_screen_test.dart
- store_profile_edit_screen.dart
- usage_no_forbidden_fields_test.dart
- audit_log_screen.dart
- products_screen.dart
- TextColumn get
- money.dart
- learn_screen.dart
- receipt_screen.dart
- sell_screen_rebuild_test.dart
- onboarding_notifier.dart
- IntColumn get
- products_dao.dart
- tokens.dart
- tables_screen.dart
- package:flutter/foundation.dart
- app_theme.dart
- held_order.dart
- receipt_body.dart
- Open POS
- dart:async
- snapshot_service_test.dart
- products_table.dart
- _
- cart_summary.dart
- inventory_card.dart
- onboarding_state.dart
- List
- order_history.dart
- products_provider.dart
- snapshot_photos_test.dart
- customer_form.dart
- confirm_step.dart
- thermal_plugin_printer.dart
- receipt_roll_pdf.dart
- escpos_raster.dart
- escpos_raster_test.dart
- tax_settings_screen.dart
- migration_test.dart
- customers_screen.dart
- order_taxes_table.dart
- article_detail_screen.dart
- dashboard_body.dart
- usage_host.dart
- schema.dart
- side_nav.dart
- Return
- cart_item.dart
- order_summary.dart
- star_platform_test.dart
- usage_ask_controller.dart
- package:flutter/services.dart
- stock_adjustments_table.dart
- sales.dart
- table_selector.dart
- star_printer.dart
- review_policy.dart
- usage_host_test.dart
- inventory_screen.dart
- shifts_table.dart
- package:pos_app/shared/widgets/app_sheet.dart
- loyalty_section.dart
- cart_line_item.dart
- restore_merge_marker.dart
- product_tile.dart
- v1 Roadmap — Flutter Offline-First POS
- pos_cart_actions.dart
- DateTime
- customers_table.dart
- pos_filter_provider.dart
- tron_border.dart
- dashboard_screen.dart
- discount_sheet.dart
- GeneratedDatabase
- expenses_dao.dart
- cart_session.dart
- locale_country.dart
- currency_glyphs_test.dart
- onboarding_test.dart
- expenses_table.dart
- app_sheet.dart
- features_step.dart
- render_receipt_image.dart
- settings_screen.dart
- shifts_dao_test.dart
- _grammar.dart
- int?
- customers_dao.dart
- tax_rates_table.dart
- _PrinterSetupScreenState
- receipt_roll_pdf_test.dart
- dart:io
- audit_log_table.dart
- link_uris.dart
- share_origin.dart
- place_order.dart
- business_type.dart
- country_default.dart
- tables_table.dart
- @visibleForTesting
- dart:convert
- tax_dao.dart
- categories_table.dart
- percent.dart
- customers_provider.dart
- Projects Dependencies
- External Integrations
- @immutable
- State
- package:pos_app/features/orders/domain/order_number.dart
- tax_rate_form_test.dart
- Project Conventions
- Technology Stack
- _
- cartMainUnitQtyProvider
- grid_product_tile.dart
- printer_errors.dart
- usage_event.dart
- shared_product_list_test.dart
- int get
- package:pos_app/features/onboarding/domain/country_default.dart
- install_macos.sh
- StateNotifier
- OnboardingNotifier
- CLAUDE.md
- app_version.dart
- build
- build
- ReportPeriod
- currencies.dart
- @rebuzzpos

## God Nodes (most connected - your core abstractions)
1. `AppDatabase` - 57 edges
2. `_` - 49 edges
3. `featureOnProvider` - 41 edges
4. `Return` - 36 edges
5. `databaseProvider` - 35 edges
6. `settingsProvider` - 28 edges
7. `_` - 28 edges
8. `cartSessionProvider` - 28 edges
9. `currencyFormatterProvider` - 22 edges
10. `AuditService` - 21 edges

## Surprising Connections (you probably didn't know these)
- `_CutAfter` --inherits--> `AppDatabase`  [EXTRACTED]
  test/drift/migration_test.dart → lib/core/database/app_database.dart
- `_GatedAudit` --inherits--> `AuditService`  [EXTRACTED]
  test/features/cart/payment_screen_test.dart → lib/core/services/audit_service.dart
- `_FixedSessionNotifier` --inherits--> `CartSessionNotifier`  [EXTRACTED]
  test/features/tables/occupied_tables_test.dart → lib/features/cart/presentation/providers/cart_notifier.dart
- `FakeReceiptPrinter` --implements--> `ReceiptPrinter`  [EXTRACTED]
  test/features/printing/auto_print_test.dart → lib/features/printing/domain/receipt_printer.dart
- `_NoopPrinter` --implements--> `ReceiptPrinter`  [EXTRACTED]
  test/features/printing/star_platform_test.dart → lib/features/printing/domain/receipt_printer.dart

## Import Cycles
- None detected.

## Communities (207 total, 4 thin omitted)

### Community 0 - "app_database.dart"
Cohesion: 0.01
Nodes (294): class OrderTaxOverride extends, class ProductComponent extends, ColumnFilters, ColumnOrderings, backfillInvoiceNumbers, backfillV14, currentSchemaVersion, migration (+286 more)

### Community 1 - "schema_v16.dart"
Cohesion: 0.02
Nodes (130): Shifts, action, actualTableName, address, _alias, aliasedName, allSchemaEntities, allTables (+122 more)

### Community 2 - "schema_v14.dart"
Cohesion: 0.02
Nodes (119): Index, action, actualTableName, address, _alias, aliasedName, allSchemaEntities, allTables (+111 more)

### Community 3 - "schema_v11.dart"
Cohesion: 0.02
Nodes (117): TaxRates, action, actualTableName, address, _alias, aliasedName, allSchemaEntities, allTables (+109 more)

### Community 4 - "schema_v12.dart"
Cohesion: 0.02
Nodes (116): Orders, action, actualTableName, address, _alias, aliasedName, allSchemaEntities, allTables (+108 more)

### Community 5 - "schema_v13.dart"
Cohesion: 0.02
Nodes (116): ProductComponents, ProductTaxes, action, actualTableName, address, _alias, aliasedName, allSchemaEntities (+108 more)

### Community 6 - "schema_v10.dart"
Cohesion: 0.02
Nodes (114): Customers, TaxGroupMembers, action, actualTableName, address, _alias, aliasedName, allSchemaEntities (+106 more)

### Community 7 - "schema_v9.dart"
Cohesion: 0.02
Nodes (114): OrderTaxOverrides, Tables, action, actualTableName, address, _alias, aliasedName, allSchemaEntities (+106 more)

### Community 8 - "schema_v8.dart"
Cohesion: 0.02
Nodes (111): Categories, Expenses, action, actualTableName, address, _alias, aliasedName, allSchemaEntities (+103 more)

### Community 9 - "schema_v15.dart"
Cohesion: 0.02
Nodes (109): action, actualTableName, address, _alias, aliasedName, allSchemaEntities, allTables, amount (+101 more)

### Community 10 - "schema_v4.dart"
Cohesion: 0.02
Nodes (108): AuditLog, Products, ProductVariants, StockAdjustments, action, actualTableName, address, _alias (+100 more)

### Community 11 - "schema_v7.dart"
Cohesion: 0.02
Nodes (108): ExpenseCategories, OrderItems, Returns, action, actualTableName, address, _alias, aliasedName (+100 more)

### Community 12 - "schema_v6.dart"
Cohesion: 0.02
Nodes (107): GeneratedColumn, OrderTaxes, ProductModifiers, TaxGroups, action, actualTableName, address, _alias (+99 more)

### Community 13 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.03
Nodes (84): Box, Completer, Directory, db, _box, _kFavoriteProductIds, toggle, activeHeld (+76 more)

### Community 14 - "snapshot_service.dart"
Cohesion: 0.02
Nodes (91): FileContent, InputFileStream, _absentSuffix, add, _addDeflated, _addStored, assertNoPendingRestore, _bakSuffix (+83 more)

### Community 15 - "hive_provider.dart"
Cohesion: 0.02
Nodes (90): autoBackupEnabled, autoBackupLastAt, _box, build, businessAddress, businessName, businessNameOrDefault, businessPan (+82 more)

### Community 16 - "AppDatabase"
Cohesion: 0.04
Nodes (76): _, @DriftDatabase, AppDatabase, AuditService, transaction, voidOrder, package:pos_app/core/services/audit_service.dart, package:pos_app/features/orders/presentation/order_detail_screen.dart (+68 more)

### Community 17 - "shifts_dao.dart"
Cohesion: 0.03
Nodes (63): amount, byMethod, cash, cashRefunds, cashSales, cashTips, cashVoids, closedShifts (+55 more)

### Community 18 - "Table"
Cohesion: 0.06
Nodes (63): Table, TableInfo, Categories, OrderItems, ProductModifiers, ProductVariants, StockAdjustments, TaxGroupMembers (+55 more)

### Community 19 - "usage_counter.dart"
Cohesion: 0.04
Nodes (54): bool?, DateTime? get, after, askedVersion, _box, countingEnabled, countingOn, _counts (+46 more)

### Community 20 - "ConsumerWidget"
Cohesion: 0.09
Nodes (53): ConsumerWidget, auditServiceProvider, featureOnProvider, onboardingCompleteProvider, build, CartDetailScreen, _ClearCartButton, PosBottomBars (+45 more)

### Community 21 - "package:pos_app/core/database/app_database.dart"
Cohesion: 0.04
Nodes (43): _db, log, orderPlaced, orderRefunded, orderVoided, settingChanged, taxOverridden, _db (+35 more)

### Community 22 - "report_data.dart"
Cohesion: 0.04
Nodes (51): all, avgOrder, changes, chartDates, chartHighlightIndex, chartTitle, chartTotals, costIsIncomplete (+43 more)

### Community 23 - "package:pos_app/features/cart/domain/cart_item.dart"
Cohesion: 0.04
Nodes (45): dart:math, _, CartCalculator, compute, _roundingModeFor, package:pos_app/core/utils/tax_calculator.dart, package:pos_app/features/cart/data/ticket_sequence.dart, package:pos_app/features/cart/domain/cart_calculator.dart (+37 more)

### Community 24 - "cart_notifier.dart"
Cohesion: 0.05
Nodes (49): defaultTaxIdProvider, invoicePrefixProvider, ticketSequenceProvider, CartSession, addItem, addProduct, addProductInSecondaryUnit, build (+41 more)

### Community 25 - "usage_summary.dart"
Cohesion: 0.04
Nodes (49): appInfo, appVersion, buildUsageSummary, bump, businessType, canSendUsageSummary, chars, count (+41 more)

### Community 26 - "app.dart"
Cohesion: 0.05
Nodes (45): ChangeNotifier, GoRouter, appRedirect, AppScrollBehavior, featureRedirect, flags, getKeyboardDismissBehavior, location (+37 more)

### Community 27 - "calc_oracle.dart"
Cohesion: 0.04
Nodes (46): BigInt, int? discPermille,
  int, balance, base, baseOnHalfCent, bp, cents, d (+38 more)

### Community 28 - "review_controller_test.dart"
Cohesion: 0.05
Nodes (42): bool get, appVersion, _guard, _inFlight, onReceiptDismissed, prompter, ReviewCheck, ReviewController (+34 more)

### Community 29 - "expenses_screen.dart"
Cohesion: 0.05
Nodes (45): _amountCtrl, build, categories, category, _CategoryChips, _categoryId, _check, _Chip (+37 more)

### Community 30 - "package:pos_app/core/providers/database_provider.dart"
Cohesion: 0.05
Nodes (36): AutoPrintService, printOrder, _ref, package:pos_app/core/providers/database_provider.dart, package:pos_app/features/audit/presentation/audit_log_screen.dart, package:pos_app/features/cart/presentation/pos_cart_actions.dart, package:pos_app/features/expenses/presentation/expenses_screen.dart, package:pos_app/features/orders/domain/order_history.dart (+28 more)

### Community 31 - "DataClass"
Cohesion: 0.09
Nodes (41): Insertable, OrderNumberX, UpdateCompanion, AuditLogCompanion, AuditLogData, CategoriesCompanion, Category, Customer (+33 more)

### Community 32 - "most_sold_test.dart"
Cohesion: 0.05
Nodes (35): int tea,, package:pos_app/core/app_version.dart, package:pos_app/core/services/demo_data_service.dart, QueryInterceptor, ../../_support/query_recorder.dart, db, expectIndexed, from (+27 more)

### Community 33 - "package:flutter/material.dart"
Cohesion: 0.06
Nodes (32): double?, EditableText, build, SettingsSectionHeader, title, action, AppEmptyState, build (+24 more)

### Community 34 - "_"
Cohesion: 0.05
Nodes (39): Font, _, bold, boldFallback, bundledFontCodePoints, bundledFontData, bundledPdfFont, cached (+31 more)

### Community 35 - "usage_providers.dart"
Cohesion: 0.06
Nodes (34): dart:ui, ShareFiles, shareFilesWithOs, UsageAskController, c, f, launch, link (+26 more)

### Community 36 - "StatelessWidget"
Cohesion: 0.07
Nodes (34): cs, key_, _KeyChip, keys, label, _SectionHeader, _ShortcutRow, text (+26 more)

### Community 37 - "VoidCallback?"
Cohesion: 0.06
Nodes (33): Color, _Badge, bg, customer, fg, icon, label, onEdit (+25 more)

### Community 38 - "orders_screen.dart"
Cohesion: 0.06
Nodes (36): orderHistoryProvider, _body, _clearQuery, createState, cs, customerName, _debounce, dispose (+28 more)

### Community 39 - "support_contact.dart"
Cohesion: 0.06
Nodes (33): canLaunch, kLinkFailureMessageDuration, kSiteUnavailable, kSupportEmail, kSupportMailUnavailable, _kSupportWhatsAppDigits, kSupportWhatsAppDisplay, kSupportWhatsAppUnavailable (+25 more)

### Community 40 - "tables_dao.dart"
Cohesion: 0.07
Nodes (33): @DriftAccessor, _$AuditDaoMixin, _$CustomersDaoMixin, DatabaseAccessor, _$ExpensesDaoMixin, _$InventoryDaoMixin, AuditDao, log (+25 more)

### Community 41 - "feature_flags.dart"
Cohesion: 0.06
Nodes (34): autoPrint, bundles, costProfit, csvImportExport, customers, dashboardExtras, defaultOn, defaults (+26 more)

### Community 42 - "backup_repository.dart"
Cohesion: 0.06
Nodes (34): added, _csvEol, csvImportExplanation, CsvImportReport, db, exportCustomers, exportExpenses, exportOrders (+26 more)

### Community 43 - "product_form_screen.dart"
Cohesion: 0.06
Nodes (34): _categoryId, _ComponentEntry, _components, _conversionCtrl, createState, _delete, didChangeDependencies, dispose (+26 more)

### Community 44 - "usage_screen.dart"
Cohesion: 0.06
Nodes (30): BusinessType? get, UsageCounter, attachUsageRouteCounter, last, onNavigate, topRouteOf, _businessType, _confirmReset (+22 more)

### Community 45 - "backup/share_origin_test.dart"
Cohesion: 0.06
Nodes (31): FormatException, package:pos_app/features/backup/data/backup_repository.dart, package:pos_app/features/backup/data/csv_text.dart, package:pos_app/features/backup/data/share_files.dart, package:pos_app/features/backup/presentation/backup_screen.dart, package:pos_app/features/receipts/presentation/receipt_pdf_service.dart, customers, db (+23 more)

### Community 46 - "features_screen.dart"
Cohesion: 0.08
Nodes (33): autoBackupEnabledProvider, autoBackupLastAtProvider, featureFlagsProvider, featuresIntroSeenProvider, stockOffSinceProvider, backupRepositoryProvider, snapshotCoordinatorProvider, _AutoBackupTile (+25 more)

### Community 47 - "payment_screen.dart"
Cohesion: 0.06
Nodes (31): createState, customer, dispose, endsWith, fmt, icon, initState, label (+23 more)

### Community 48 - "restore_recovery_test.dart"
Cohesion: 0.07
Nodes (32): Exception, FileSystemException, ShiftStateException, RestoreJournalFormatException, PendingRestoreException, RestoreFatalException, RestoreRolledBackException, SnapshotFormatException (+24 more)

### Community 49 - "orders_dao.dart"
Cohesion: 0.06
Nodes (32): completedOrderCount, _escapeLike, getById, getItems, getTaxBreakdown, hasRestockedReturn, historyPage, incrementPrintCount (+24 more)

### Community 50 - "backup_screen.dart"
Cohesion: 0.06
Nodes (31): _BackupTile, _buildInfoCard, color, _confirmAndImport, _createFullBackup, createState, cs, files (+23 more)

### Community 51 - "held_tickets_bar.dart"
Cohesion: 0.07
Nodes (30): AnimationController, HeldOrder, archive, archiveAll, archivedHeldOrdersProvider, _box, build, delete (+22 more)

### Community 52 - "IconData?"
Cohesion: 0.07
Nodes (28): ColorScheme, IconData?, build, color, cs, icon, KpiCard, label (+20 more)

### Community 53 - "ConsumerState"
Cohesion: 0.08
Nodes (31): ConsumerState, ConsumerStatefulWidget, lowStockThresholdProvider, CartScreen, _CartScreenState, PaymentScreen, _fitsStock, _HeldTicketsSheet (+23 more)

### Community 54 - "app_root.dart"
Cohesion: 0.06
Nodes (31): AppRoot, AppRootState, autoBackupDelay, _autoBackupRun, autoBackupScheduledForTest, _autoBackupTimer, build, child (+23 more)

### Community 55 - "restore_merge_test.dart"
Cohesion: 0.07
Nodes (28): databaseFile, dir, kDatabaseFileName, openConnection, package:drift/native.dart, package:path/path.dart, package:path_provider/path_provider.dart, package:pos_app/features/backup/data/snapshot_service.dart (+20 more)

### Community 56 - "receipt_printer.dart"
Cohesion: 0.06
Nodes (31): address, classicBluetoothDriversAvailable, data, devices, DiscoveredPrinter, driver, escPosPrinterProvider, fmt (+23 more)

### Community 57 - "printer_setup_screen.dart"
Cohesion: 0.07
Nodes (29): PrinterDriver, lastSdkNeedingLocationForBle, permissionsForScan, scanNeedsLocation, createState, _devices, _devicesSub, _disconnectSavedPrinter (+21 more)

### Community 58 - "package:pos_app/core/utils/currency_formatter.dart"
Cohesion: 0.07
Nodes (28): bytes, customerName, g, isCopy, _kv, method, methodLabel, profile (+20 more)

### Community 59 - "csv_text.dart"
Cohesion: 0.07
Nodes (29): _bad, boolOf, cell, cellQuoted, _cells, _columns, CsvRow, CsvTable (+21 more)

### Community 60 - "onboarding_screen.dart"
Cohesion: 0.09
Nodes (29): build, onboardingNotifierProvider, _back, build, _businessNameCtrl, _countries, createState, dispose (+21 more)

### Community 61 - "restore_merge_marker_test.dart"
Cohesion: 0.08
Nodes (25): main, startup, fatal, notice, openStartupStores, recovery, startReviewClock, startUp (+17 more)

### Community 62 - "Milestone 1: v1 (Foundation & Core POS)"
Cohesion: 0.07
Nodes (26): 1. State Management (Riverpod), 2. Navigation (GoRouter), 3. Data Layer (Drift & Hive), 4. Hardware Integration, Core Pillars, Data Flow, Directory Structure, Overview (+18 more)

### Community 63 - "build"
Cohesion: 0.10
Nodes (27): build, posCatalogProvider, posFilterProvider, build, _ProductArea, build, build, build (+19 more)

### Community 64 - "databaseProvider"
Cohesion: 0.09
Nodes (27): databaseProvider, _delete, _showAddCategoryDialog, InventoryCard, categoriesStreamProvider, productsByCategoryProvider, build, CategoriesScreen (+19 more)

### Community 65 - "snapshot_providers.dart"
Cohesion: 0.07
Nodes (27): autoBackupDir, autoBackupLastError, create, createAndShare, defaultHiveBoxPaths, docs, inspect, kAutoBackupInterval (+19 more)

### Community 66 - "orders_table.dart"
Cohesion: 0.07
Nodes (26): changeAmount, createdAt, customerId, discountIsPercent, discountTotal, discountValue, id, invoiceNo (+18 more)

### Community 67 - "receipt_pdf_service.dart"
Cohesion: 0.07
Nodes (26): baseStyle, billRow, boldFallback, boldStyle, buildReceiptPdf, bytes, customerName, _dataCell (+18 more)

### Community 68 - "order_items_table.dart"
Cohesion: 0.08
Nodes (23): getAdjustmentsForOrder, getAdjustmentsForProduct, logAdjustment, stockToRestock, watchLowStock, discount, id, lineTotal (+15 more)

### Community 69 - "home.dart"
Cohesion: 0.08
Nodes (25): demoDataServiceProvider, categories, _CategoryRow, _Chip, createState, dispose, _EmptyProductsState, _EmptyProductsStateState (+17 more)

### Community 70 - "order_detail_screen.dart"
Cohesion: 0.08
Nodes (25): build, businessName, customer, data, db, _DetailData, does, fmt (+17 more)

### Community 71 - "usage_constants.dart"
Cohesion: 0.08
Nodes (25): kFeedbackAreaQuestion, kFeedbackAskAction, kFeedbackAskText, kFeedbackInstruction, kFeedbackMessageMaxLength, kFeedbackSupportRowSubtitle, kFeedbackSupportRowTitle, kOfflineFirstLine (+17 more)

### Community 72 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.08
Nodes (20): package:flutter_test/flutter_test.dart, package:pos_app/core/utils/money.dart, package:pos_app/features/help/presentation/shortcuts_screen.dart, package:pos_app/features/products/domain/stock_level.dart, package:pos_app/features/products/domain/unit_conversion.dart, main, main, audit (+12 more)

### Community 73 - "pos_catalog_provider.dart"
Cohesion: 0.08
Nodes (24): AsyncValue, buildPosSearchIndex, cart, catalogEmpty, categoryId, committedMainUnits, favorites, favoritesOnly (+16 more)

### Community 74 - "settingsProvider"
Cohesion: 0.10
Nodes (23): AppSettings, settingsBoxProvider, SettingsNotifier, settingsProvider, themeModeProvider, _set, finish, _saveFeatures (+15 more)

### Community 75 - "review_state_store.dart"
Cohesion: 0.08
Nodes (22): _box, _date, ensureFirstLaunch, markAnyPromptShown, markPrompted, mergeAfterRestore, mergeReviewStateAfterRestore, read (+14 more)

### Community 76 - "usage_screen_test.dart"
Cohesion: 0.08
Nodes (22): ButtonStyleButton, CheckboxListTile, package:pos_app/core/utils/link_uris.dart, expectSafe, field, main, receipt, counter (+14 more)

### Community 77 - "store_profile_edit_screen.dart"
Cohesion: 0.13
Nodes (23): class, businessAddressProvider, businessNameProvider, businessPanProvider, businessPhoneProvider, businessTaglineProvider, _addressCtrl, build (+15 more)

### Community 78 - "usage_no_forbidden_fields_test.dart"
Cohesion: 0.09
Nodes (21): _grammar.dart, countOf, currentUsageEnvironment, readShopSizeCounts, t, package:pos_app/features/onboarding/domain/business_type.dart, package:pos_app/features/usage/data/usage_inputs.dart, package:pos_app/features/usage/domain/usage_summary.dart (+13 more)

### Community 79 - "audit_log_screen.dart"
Cohesion: 0.09
Nodes (22): currencyCode, decimalDigits, _fmt, format, formatPlain, locale, _plainFmt, symbol (+14 more)

### Community 80 - "products_screen.dart"
Cohesion: 0.08
Nodes (23): categories, _CategoryChips, categoryName, _Chip, createState, cs, dispose, fmt (+15 more)

### Community 81 - "TextColumn get"
Cohesion: 0.10
Nodes (20): BoolColumn get, DateTimeColumn get, color, ExpenseCategories, id, isDefault, name, amount (+12 more)

### Community 82 - "money.dart"
Cohesion: 0.09
Nodes (22): allowZero, byLoss, cents, eps, exact, isRequired, kMaxMoneyAmount, kMaxMoneyAmountLabel (+14 more)

### Community 83 - "learn_screen.dart"
Cohesion: 0.09
Nodes (21): _Article, _ArticleCard, _articles, category, cs, description, icon, LearnScreen (+13 more)

### Community 84 - "receipt_screen.dart"
Cohesion: 0.09
Nodes (22): build, businessName, createState, customer, data, db, dispose, fmt (+14 more)

### Community 85 - "sell_screen_rebuild_test.dart"
Cohesion: 0.09
Nodes (21): AppBar, CustomPaint, FilterChip, GridView, ListView, NavigatorState, package:pos_app/features/cart/presentation/widgets/checkout_bar.dart, package:pos_app/features/cart/presentation/widgets/held_tickets_bar.dart (+13 more)

### Community 86 - "onboarding_notifier.dart"
Cohesion: 0.10
Nodes (20): FeatureFlags get, back, build, _defaults, next, _passed, _reached, _saveProfile (+12 more)

### Community 87 - "IntColumn get"
Cohesion: 0.10
Nodes (19): IntColumn get, componentProductId, compositeProductId, id, ProductComponents, quantity, primaryKey, productId (+11 more)

### Community 88 - "products_dao.dart"
Cohesion: 0.09
Nodes (21): deductStock, deleteCategory, getAllCategories, getById, getBySku, getComponents, replaceComponents, restock (+13 more)

### Community 89 - "tokens.dart"
Cohesion: 0.09
Nodes (21): AppFonts, AppOpacity, heavy, lg, md, medium, mono, monoFallback (+13 more)

### Community 90 - "tables_screen.dart"
Cohesion: 0.10
Nodes (21): _assignToCart, _capacityCtrl, createState, dispose, existing, initState, isCurrentCartTable, isOccupied (+13 more)

### Community 91 - "package:flutter/foundation.dart"
Cohesion: 0.10
Nodes (18): restartNoticeShowing, AndroidSdk, _cached, _methods, _read, sdkInt, _devices, dispose (+10 more)

### Community 92 - "app_theme.dart"
Cohesion: 0.10
Nodes (20): AppTheme, backgroundGradient, _build, ctaButtonStyle, _dark, _darkGrad, _darkScheme, _fontFallback (+12 more)

### Community 93 - "held_order.dart"
Cohesion: 0.10
Nodes (20): archivedAt, copyWith, createdAt, customerId, customerName, fromJson, id, isArchived (+12 more)

### Community 94 - "receipt_body.dart"
Cohesion: 0.10
Nodes (20): _BillRow, build, businessName, customer, data, _DataCell, fmt, _HeaderCell (+12 more)

### Community 95 - "Open POS"
Cohesion: 0.10
Nodes (20): Build from source, Contributing, Customers, Features, Get Open POS, License, macOS, Money and reports (+12 more)

### Community 96 - "dart:async"
Cohesion: 0.11
Nodes (17): AppLifecycleListener?, dart:async, Duration, DatabaseExitGuard, dispose, handleExitRequest, _listener, timeout (+9 more)

### Community 97 - "snapshot_service_test.dart"
Cohesion: 0.10
Nodes (19): ../../drift/generated/schema.dart, package:archive/archive.dart, craftZip, dbFileIn, expectLiveUntouched, expectRejected, hivePathIn, live (+11 more)

### Community 98 - "products_table.dart"
Cohesion: 0.10
Nodes (19): categoryId, conversionRate, createdAt, id, imagePath, isActive, isComposite, isHiddenInPos (+11 more)

### Community 99 - "_"
Cohesion: 0.11
Nodes (20): _, _abs, bak, begin, cleanup, committed, markCommitted, message (+12 more)

### Community 100 - "cart_summary.dart"
Cohesion: 0.10
Nodes (19): amount, CartSummary, isInclusive, loyaltyDiscount, maxRedeemablePoints, name, orderDiscount, pointsRedeemed (+11 more)

### Community 101 - "inventory_card.dart"
Cohesion: 0.10
Nodes (19): _apply, badgeColor, build, canDecrement, canIncrement, cs, _decrement, icon (+11 more)

### Community 102 - "onboarding_state.dart"
Cohesion: 0.10
Nodes (19): businessName, businessType, copyWith, country, current, defaultTaxesOn, isLast, kOnboardingSteps (+11 more)

### Community 103 - "List"
Cohesion: 0.10
Nodes (18): build, BusinessTypeStep, kBusinessTypeSubtitle, kBusinessTypeTitle, onPick, selected, build, countries (+10 more)

### Community 104 - "order_history.dart"
Cohesion: 0.11
Nodes (19): _changes, copyWith, _db, dispose, error, _generation, hasMore, isLoading (+11 more)

### Community 105 - "products_provider.dart"
Cohesion: 0.10
Nodes (19): applyProductsFilter, clearSearch, code, copyWith, list, mostSoldWindow, outOfStockOnly, productSalesCountProvider (+11 more)

### Community 106 - "snapshot_photos_test.dart"
Cohesion: 0.10
Nodes (19): package:sqlite3/sqlite3.dart, backupOf, dbFileIn, entriesOf, hasProduct, hivePathIn, _indexOf, live (+11 more)

### Community 107 - "customer_form.dart"
Cohesion: 0.11
Nodes (18): _addressCtrl, build, createState, customer, CustomerForm, _CustomerFormState, _delete, _discountCtrl (+10 more)

### Community 108 - "confirm_step.dart"
Cohesion: 0.11
Nodes (16): build, c, children, ConfirmStep, currencySummary, icon, isLast, kTaxesOffSummary (+8 more)

### Community 109 - "thermal_plugin_printer.dart"
Cohesion: 0.11
Nodes (17): _connect, _connectTimeout, devices, _disconnect, _ftp, _pluginDevice, _printPages, printReceipt (+9 more)

### Community 110 - "receipt_roll_pdf.dart"
Cohesion: 0.11
Nodes (18): base, body, bold, buildReceiptRollPdf, buildTestPageRollPdf, dateFmt, doc, fmt (+10 more)

### Community 111 - "escpos_raster.dart"
Cohesion: 0.11
Nodes (17): dart:isolate, Future, bytes, cached, canvas, escPosProfile, escPosRasterBytes, escPosRasterBytesSync (+9 more)

### Community 112 - "escpos_raster_test.dart"
Cohesion: 0.11
Nodes (16): dart:typed_data, package:image/image.dart, StateError, _blockPage, _countSequence, _firstRaster, found, fromList (+8 more)

### Community 113 - "tax_settings_screen.dart"
Cohesion: 0.12
Nodes (17): FormState, createState, dispose, existing, _formKey, _inclusionType, _nameCtrl, onAdd (+9 more)

### Community 114 - "migration_test.dart"
Cohesion: 0.11
Nodes (17): generated/schema.dart, package:drift_dev/api/migrations_common.dart, package:drift_dev/api/migrations_native.dart, SchemaVerifier, allIndexes, customStatement, _CutAfter, failAt (+9 more)

### Community 115 - "customers_screen.dart"
Cohesion: 0.12
Nodes (17): IconData get, createState, CustomersScreen, _CustomersScreenState, dispose, _filterAndSort, icon, label (+9 more)

### Community 116 - "order_taxes_table.dart"
Cohesion: 0.11
Nodes (16): createdAt, id, orderId, OrderTaxOverrides, originalTax, overrideTax, reason, id (+8 more)

### Community 117 - "article_detail_screen.dart"
Cohesion: 0.11
Nodes (17): ArticleDetailScreen, ArticleSection, build, category, cs, heading, icon, readTime (+9 more)

### Community 118 - "dashboard_body.dart"
Cohesion: 0.11
Nodes (17): ReportData, build, _buildKpiRows, cs, DashboardBody, data, _fmt, isCustomRange (+9 more)

### Community 119 - "usage_host.dart"
Cohesion: 0.11
Nodes (17): _ask, child, _counter, createState, _disclosing, dispose, initState, kFeedbackAskDuration (+9 more)

### Community 120 - "schema.dart"
Cohesion: 0.11
Nodes (17): package:drift/internal/migrations.dart, schema_v10.dart, schema_v11.dart, schema_v12.dart, schema_v13.dart, schema_v14.dart, schema_v15.dart, schema_v16.dart (+9 more)

### Community 121 - "side_nav.dart"
Cohesion: 0.12
Nodes (16): Feature, f, feature, featureForLocation, featureRedirect, group, icon, kFeaturesIntroFreshText (+8 more)

### Community 122 - "Return"
Cohesion: 0.12
Nodes (14): initials, name, null, stockCapFor, isValidConversionRate, kMaxConversionRate, kMinConversionRate, null (+6 more)

### Community 123 - "cart_item.dart"
Cohesion: 0.12
Nodes (16): copyWith, grossAmount, isSecondaryUnit, isTaxable, lineDiscount, lineSubtotal, mainUnitQty, name (+8 more)

### Community 124 - "order_summary.dart"
Cohesion: 0.12
Nodes (16): addColor, cs, fmt, label, onTap, ref, _showDiscountSheet, _showTaxPicker (+8 more)

### Community 125 - "star_platform_test.dart"
Cohesion: 0.12
Nodes (16): SppPrinter, StarBluetoothPrinter, ThermalPluginPrinter, ReceiptPrinter, package:pos_app/features/printing/data/star_printer.dart, package:pos_app/features/printing/presentation/printer_setup_screen.dart, Stream, FakeReceiptPrinter (+8 more)

### Community 126 - "usage_ask_controller.dart"
Cohesion: 0.12
Nodes (16): afterReviewCheck, appVersion, counter, dispose, evaluate, fossBuild, _inFlight, kFossBuild (+8 more)

### Community 127 - "package:flutter/services.dart"
Cohesion: 0.12
Nodes (14): package:flutter/services.dart, package:pos_app/features/help/support_contact.dart, package:pos_app/features/printing/domain/printer_errors.dart, main, no, opened, record, throws (+6 more)

### Community 128 - "stock_adjustments_table.dart"
Cohesion: 0.12
Nodes (15): @TableIndex, Expenses, OrderItems, OrderTaxes, Orders, Returns, Shifts, createdAt (+7 more)

### Community 129 - "sales.dart"
Cohesion: 0.12
Nodes (15): int? customerId,
  int, line, loyaltyDiscount, paymentMethod, placeOrder, points, pointsRedeemed, pointsToEarn (+7 more)

### Community 130 - "table_selector.dart"
Cohesion: 0.17
Nodes (15): activeHeldOrdersProvider, build, occupied, onSelect, _pickTable, selectedId, session, _TablePickerSheet (+7 more)

### Community 131 - "star_printer.dart"
Cohesion: 0.12
Nodes (15): _devices, _discovery, dispose, _events, _found, isSupported, _methods, _printImages (+7 more)

### Community 132 - "review_policy.dart"
Cohesion: 0.12
Nodes (15): at, first, firstLaunchAt, kMinDaysBetweenAnyPrompts, kReviewMinCompletedSales, kReviewMinDaysBetweenPrompts, kReviewMinDaysSinceInstall, last (+7 more)

### Community 133 - "usage_host_test.dart"
Cohesion: 0.12
Nodes (14): package:flutter/gestures.dart, package:pos_app/core/restart_notice.dart, package:pos_app/features/help/presentation/support_screen.dart, package:pos_app/features/usage/presentation/usage_host.dart, package:pos_app/features/usage/presentation/usage_screen.dart, main, db, expectChargeUncovered (+6 more)

### Community 134 - "inventory_screen.dart"
Cohesion: 0.13
Nodes (14): Iterable, createState, dispose, _filter, _filtered, filterInventoryProducts, list, _search (+6 more)

### Community 135 - "shifts_table.dart"
Cohesion: 0.13
Nodes (14): cashRefunds, cashSales, cashTips, cashVoids, closedAt, countedCash, expectedCash, id (+6 more)

### Community 136 - "package:pos_app/shared/widgets/app_sheet.dart"
Cohesion: 0.18
Nodes (14): currencyCodeProvider, currencySymbolProvider, shareFilesProvider, build, _CurrencyPickerSheet, CurrencySection, current, _showCurrencyPicker (+6 more)

### Community 137 - "loyalty_section.dart"
Cohesion: 0.17
Nodes (14): loyaltyEarnRateProvider, loyaltyEnabledProvider, loyaltyPointValueProvider, build, createState, dispose, _earnCtrl, earnRate (+6 more)

### Community 138 - "cart_line_item.dart"
Cohesion: 0.13
Nodes (13): CurrencyFormatter, CartItem, build, fmt, icon, item, onPressed, _QtyButton (+5 more)

### Community 139 - "restore_merge_marker.dart"
Cohesion: 0.13
Nodes (14): counts, d, deleteRestoreMergeMarker, finishPendingRestoreMerge, kRestoreMergeMarkerName, _markerFile, null, path (+6 more)

### Community 140 - "product_tile.dart"
Cohesion: 0.13
Nodes (14): bg, color, cs, icon, onDecrement, onIncrement, onTap, product (+6 more)

### Community 141 - "v1 Roadmap — Flutter Offline-First POS"
Cohesion: 0.13
Nodes (14): Architecture Decisions, Deferred to v2, Drift Schema — Full Table List (v1), Phase 0 — Foundation (No UI yet), Phase 1 — First-Run & Onboarding, Phase 2 — Product & Inventory Core, Phase 3 — Core Sales Loop, Phase 4 — Receipts & Hardware (+6 more)

### Community 142 - "pos_cart_actions.dart"
Cohesion: 0.14
Nodes (13): CartNotifier get, add, _allowQty, _cart, _committed, _container, _messenger, pickUnit (+5 more)

### Community 143 - "DateTime"
Cohesion: 0.18
Nodes (13): DateTime, BackupRepository, package:csv/csv.dart, bytesOf, db, legacyAllOrdersWithItems, legacyOrdersCsv, legacySalesReportCsv (+5 more)

### Community 144 - "customers_table.dart"
Cohesion: 0.14
Nodes (13): address, createdAt, Customers, defaultDiscount, defaultDiscountIsPercent, email, id, isTaxExempt (+5 more)

### Community 145 - "pos_filter_provider.dart"
Cohesion: 0.14
Nodes (13): clearSearch, copyWith, favoritesOnly, isGrid, PosSortMode, search, selectedCategoryId, setCategory (+5 more)

### Community 146 - "tron_border.dart"
Cohesion: 0.15
Nodes (12): CustomPainter, color, e, extractWrappedPath, f, len, p, paint (+4 more)

### Community 147 - "dashboard_screen.dart"
Cohesion: 0.19
Nodes (12): DateTimeRange?, reportProvider, reportSectionsProvider, build, createState, _customRange, DashboardScreen, _DashboardScreenState (+4 more)

### Community 148 - "discount_sheet.dart"
Cohesion: 0.17
Nodes (12): double get, build, createState, _ctrl, currentDiscount, DiscountSheet, _DiscountSheetState, dispose (+4 more)

### Community 149 - "GeneratedDatabase"
Cohesion: 0.15
Nodes (13): GeneratedDatabase, DatabaseAtV10, DatabaseAtV11, DatabaseAtV12, DatabaseAtV13, DatabaseAtV14, DatabaseAtV15, DatabaseAtV16 (+5 more)

### Community 150 - "expenses_dao.dart"
Cohesion: 0.15
Nodes (12): getAll, getAllCategories, insert, insertCategory, totalForPeriod, updateExpense, upsertCategory, watchAll (+4 more)

### Community 151 - "cart_session.dart"
Cohesion: 0.15
Nodes (12): copyWith, customerId, fresh, heldTicketId, isEditingHeldTicket, loyaltyPointsToRedeem, openedAt, orderDiscount (+4 more)

### Community 152 - "locale_country.dart"
Cohesion: 0.15
Nodes (12): base, byCode, countryForRegion, fromLocale, kFallbackCountry, kUnmatchedCountry, _localeName, normalizeRegion (+4 more)

### Community 153 - "currency_glyphs_test.dart"
Cohesion: 0.15
Nodes (11): package:pdf/widgets.dart, package:pos_app/core/utils/bundled_fonts.dart, main, at, _data, _fmt, main, _missingGlyphWarnings (+3 more)

### Community 154 - "onboarding_test.dart"
Cohesion: 0.15
Nodes (12): package:pos_app/features/onboarding/domain/onboarding_state.dart, package:pos_app/features/onboarding/presentation/onboarding_notifier.dart, package:pos_app/features/onboarding/presentation/onboarding_screen.dart, package:pos_app/features/onboarding/presentation/widgets/confirm_step.dart, package:pos_app/features/onboarding/presentation/widgets/country_step.dart, package:pos_app/features/onboarding/presentation/widgets/features_step.dart, box, container (+4 more)

### Community 155 - "expenses_table.dart"
Cohesion: 0.17
Nodes (11): amount, categoryId, createdAt, date, id, isRecurring, isTaxDeductible, notes (+3 more)

### Community 156 - "app_sheet.dart"
Cohesion: 0.17
Nodes (10): cs, failurePrefix, messenger, draggable, initialSize, minSize, package:pos_app/shared/widgets/keyboard_safe.dart, required WidgetBuilder builder,
  bool (+2 more)

### Community 157 - "features_step.dart"
Cohesion: 0.17
Nodes (11): build, FeaturesStep, kStartMinimal, kSuggestFooter, kSuggestSubtitle, kSuggestTitle, kSuggestWhy, onStartMinimal (+3 more)

### Community 158 - "render_receipt_image.dart"
Cohesion: 0.17
Nodes (11): doc, escPosPrintWidthDots, isCopy, kReceiptDpi, pages, _rasterise, renderReceiptImages, renderTestPageImages (+3 more)

### Community 159 - "settings_screen.dart"
Cohesion: 0.17
Nodes (11): build, package:pos_app/features/settings/presentation/widgets/appearance_section.dart, package:pos_app/features/settings/presentation/widgets/backup_section.dart, package:pos_app/features/settings/presentation/widgets/currency_section.dart, package:pos_app/features/settings/presentation/widgets/danger_section.dart, package:pos_app/features/settings/presentation/widgets/inventory_section.dart, package:pos_app/features/settings/presentation/widgets/loyalty_section.dart, package:pos_app/features/settings/presentation/widgets/printer_section.dart (+3 more)

### Community 160 - "shifts_dao_test.dart"
Cohesion: 0.17
Nodes (11): package:pos_app/core/database/daos/shifts_dao.dart, at, close, dao, day, db, main, order (+3 more)

### Community 161 - "_grammar.dart"
Cohesion: 0.17
Nodes (11): _bucket, _businessTypes, _events, expectGrammar, fixed, i, kUsageLineGrammar, _labels (+3 more)

### Community 162 - "int?"
Cohesion: 0.20
Nodes (10): int?, build, createState, CustomerPickerSheet, _CustomerPickerSheetState, customers, onSelect, _search (+2 more)

### Community 163 - "customers_dao.dart"
Cohesion: 0.18
Nodes (10): addLoyaltyPoints, getAll, getById, namesFor, redeemLoyaltyPoints, search, upsert, watchAll (+2 more)

### Community 164 - "tax_rates_table.dart"
Cohesion: 0.18
Nodes (10): createdAt, id, inclusionType, isActive, isCompound, name, rate, roundingMode (+2 more)

### Community 165 - "_PrinterSetupScreenState"
Cohesion: 0.35
Nodes (10): printerDeviceAddressProvider, printerDeviceNameProvider, printerDriverProvider, printerPaperWidthProvider, receiptPrinterProvider, build, _PrinterSetupScreenState, _printTestPage (+2 more)

### Community 166 - "receipt_roll_pdf_test.dart"
Cohesion: 0.18
Nodes (10): package:pdf/pdf.dart, package:pos_app/features/printing/domain/receipt_roll_pdf.dart, package:pos_app/features/printing/domain/render_receipt_image.dart, doc, fmt, main, order, _pageFormats (+2 more)

### Community 167 - "dart:io"
Cohesion: 0.20
Nodes (7): dart:io, File, main, manifest, rules, main, main

### Community 168 - "audit_log_table.dart"
Cohesion: 0.20
Nodes (9): action, AuditLog, createdAt, entityId, entityType, id, metadata, newValue (+1 more)

### Community 169 - "link_uris.dart"
Cohesion: 0.20
Nodes (9): apple, _encode, _lineBreak, mailtoLink, query, smsLink, target, to (+1 more)

### Community 170 - "share_origin.dart"
Cohesion: 0.20
Nodes (9): bounds, box, fromLTWH, resolveShareOrigin, screen, shareOriginFor, view, widgetRect (+1 more)

### Community 171 - "place_order.dart"
Cohesion: 0.20
Nodes (9): components, cost, invoicePrefix, placeOrder, roundMoney, trackStock, transaction, _unitCostNow (+1 more)

### Community 172 - "business_type.dart"
Cohesion: 0.20
Nodes (9): _app, BusinessType, kAlwaysSuggested, kPresets, label, parseBusinessType, presetSwitches, usageLabel (+1 more)

### Community 173 - "country_default.dart"
Cohesion: 0.20
Nodes (9): code, CountryDefault, currency, fromJson, name, symbol, taxName, taxRate (+1 more)

### Community 174 - "tables_table.dart"
Cohesion: 0.22
Nodes (8): @DataClassName, capacity, createdAt, id, name, notes, Tables, updatedAt

### Community 175 - "@visibleForTesting"
Cohesion: 0.22
Nodes (9): @visibleForTesting, customersCsv, expensesCsv, productsCsv, writeOrdersCsv, writeSalesReportCsv, exactAmountText, voidDialogText (+1 more)

### Community 176 - "dart:convert"
Cohesion: 0.22
Nodes (8): dart:convert, _box, formatTicketNumber, heldOrdersBoxProvider, kTicketSeqKey, next, TicketSequence, _MemorySequence

### Community 177 - "tax_dao.dart"
Cohesion: 0.22
Nodes (8): getAll, getById, getRatesForProduct, setProductTaxes, upsertRate, watchActive, package:pos_app/core/database/tables/product_taxes_table.dart, _

### Community 178 - "categories_table.dart"
Cohesion: 0.22
Nodes (8): Categories, createdAt, id, name, parentId, sortOrder, taxRateId, updatedAt

### Community 179 - "percent.dart"
Cohesion: 0.22
Nodes (8): formatPercent, formatPercentNumber, formatRateForEdit, formatRatePercent, kPercentDecimals, kPercentInputPattern, text, RegExp

### Community 180 - "customers_provider.dart"
Cohesion: 0.22
Nodes (8): _LoyaltyGate, cartCustomerProvider, customerId, customerNamesKey, customerNamesProvider, customers, ref, watch

### Community 181 - "Projects Dependencies"
Cohesion: 0.22
Nodes (8): Dev Dependencies, [Hardware] flutter_thermal_printer, Major Dependencies, Outdated / Deprecated Dependencies, Overview, [Persistence] drift, Projects Dependencies, [State Management] flutter_riverpod

### Community 182 - "External Integrations"
Cohesion: 0.22
Nodes (8): APIs & External Services, Authentication & Identity, CI/CD & Deployment, Data Storage, Environment Configuration, External Integrations, Monitoring & Observability, Webhooks & Callbacks

### Community 183 - "@immutable"
Cohesion: 0.25
Nodes (8): @immutable, FeatureFlags, ReportSections, ReviewState, ShopSizeCounts, UsageCount, UsageEnvironment, UsageSelection

### Community 184 - "State"
Cohesion: 0.32
Nodes (8): RestartNoticeOverlay, RestartNoticeOverlayState, _ReceiptMark, _ReceiptMarkState, _ComponentPickerSheet, _ComponentPickerSheetState, State, StatefulWidget

### Community 185 - "package:pos_app/features/orders/domain/order_number.dart"
Cohesion: 0.25
Nodes (7): addBack, customerId, items, label, restockOrderItems, reverseLoyalty, package:pos_app/features/orders/domain/order_number.dart

### Community 186 - "tax_rate_form_test.dart"
Cohesion: 0.25
Nodes (7): package:pos_app/features/tax/presentation/tax_settings_screen.dart, create, db, main, pumpForm, rateField, TextFormField

### Community 187 - "Project Conventions"
Cohesion: 0.25
Nodes (7): Database (Drift), External Integrations, Feature Architecture, General Standards, Project Conventions, State Management (Riverpod), UI & UX

### Community 188 - "Technology Stack"
Cohesion: 0.25
Nodes (7): Configuration, Frameworks, Key Dependencies, Languages, Platform Requirements, Runtime, Technology Stack

### Community 189 - "_"
Cohesion: 0.33
Nodes (7): _, compoundTax, invoiceTax, lineItemTax, priceBeforeTax, _round, TaxCalculator

### Community 190 - "cartMainUnitQtyProvider"
Cohesion: 0.43
Nodes (7): cartMainUnitQtyProvider, _ListSeparator, build, GridProductTile, build, PosProductTile, favoritesProvider

### Community 191 - "grid_product_tile.dart"
Cohesion: 0.29
Nodes (6): product, stock, units, package:pos_app/features/cart/domain/pos_catalog_provider.dart, package:pos_app/features/products/domain/favorites_provider.dart, package:pos_app/shared/widgets/step_button.dart

### Community 192 - "printer_errors.dart"
Cohesion: 0.29
Nodes (6): friendlyPrinterError, known, kRepairPrinterNote, _match, null, raw

### Community 193 - "usage_event.dart"
Cohesion: 0.29
Nodes (6): area, FeatureArea, label, of, UsageEvent, usageEventForRoute

### Community 194 - "shared_product_list_test.dart"
Cohesion: 0.29
Nodes (6): package:pos_app/features/cart/domain/pos_filter_provider.dart, package:pos_app/features/inventory/presentation/inventory_screen.dart, ids, main, original, source

### Community 195 - "int get"
Cohesion: 0.33
Nodes (5): int get, billNo, displayNo, paymentLabel, String get

### Community 196 - "package:pos_app/features/onboarding/domain/country_default.dart"
Cohesion: 0.33
Nodes (5): _cache, CountryRepository, load, package:pos_app/features/onboarding/domain/country_default.dart, static List

### Community 198 - "StateNotifier"
Cohesion: 0.40
Nodes (5): PosFilterNotifier, PosFilterState, ProductsFilterNotifier, ProductsFilterState, StateNotifier

### Community 199 - "OnboardingNotifier"
Cohesion: 0.40
Nodes (5): deviceRegionProvider, OnboardingState, OnboardingNotifier, _regionCountry, _loadCountries

### Community 200 - "CLAUDE.md"
Cohesion: 0.50
Nodes (3): Database schema changes, graphify, Offline-first (non-negotiable)

### Community 201 - "app_version.dart"
Cohesion: 0.50
Nodes (3): kAppBuildNumber, kAppVersion, kAppVersionFull

### Community 202 - "build"
Cohesion: 0.50
Nodes (4): featuresIntroFreshProvider, build, _FeaturesIntroLine, Route /features

### Community 203 - "build"
Cohesion: 0.67
Nodes (3): build, MaterialPageRoute, main

## Knowledge Gaps
- **4461 isolated node(s):** `refresh`, `router`, `flags`, `location`, `getKeyboardDismissBehavior` (+4456 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **4 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Return` connect `Return` to `app_database.dart`, `review_policy.dart`, `restore_merge_marker.dart`, `package:flutter_riverpod/flutter_riverpod.dart`, `tron_border.dart`, `usage_counter.dart`, `locale_country.dart`, `usage_summary.dart`, `app.dart`, `currency_glyphs_test.dart`, `calc_oracle.dart`, `render_receipt_image.dart`, `DataClass`, `_`, `usage_providers.dart`, `percent.dart`, `customers_provider.dart`, `receipt_printer.dart`, `package:pos_app/core/utils/currency_formatter.dart`, `csv_text.dart`, `printer_errors.dart`, `receipt_pdf_service.dart`, `pos_catalog_provider.dart`, `review_state_store.dart`, `money.dart`, `products_provider.dart`, `receipt_roll_pdf.dart`, `escpos_raster.dart`, `escpos_raster_test.dart`, `side_nav.dart`?**
  _High betweenness centrality (0.048) - this node is a cross-community bridge._
- **Why does `_` connect `_` to `package:flutter/material.dart`, `List`, `dart:io`, `dart:convert`, `restore_recovery_test.dart`, `restore_merge_test.dart`, `package:flutter/foundation.dart`?**
  _High betweenness centrality (0.013) - this node is a cross-community bridge._
- **Why does `AppDatabase` connect `AppDatabase` to `app_database.dart`, `usage_host_test.dart`, `package:flutter_riverpod/flutter_riverpod.dart`, `DateTime`, `package:pos_app/core/database/app_database.dart`, `package:pos_app/features/cart/domain/cart_item.dart`, `onboarding_test.dart`, `app.dart`, `package:pos_app/core/providers/database_provider.dart`, `most_sold_test.dart`, `shifts_dao_test.dart`, `tables_dao.dart`, `backup_repository.dart`, `backup/share_origin_test.dart`, `tax_rate_form_test.dart`, `order_items_table.dart`, `package:flutter_test/flutter_test.dart`, `usage_screen_test.dart`, `usage_no_forbidden_fields_test.dart`, `order_history.dart`, `migration_test.dart`?**
  _High betweenness centrality (0.011) - this node is a cross-community bridge._
- **What connects `refresh`, `router`, `flags` to the rest of the system?**
  _4461 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `app_database.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.006779661016949152 - nodes in this community are weakly interconnected._
- **Should `schema_v16.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.015267175572519083 - nodes in this community are weakly interconnected._
- **Should `schema_v14.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.016666666666666666 - nodes in this community are weakly interconnected._