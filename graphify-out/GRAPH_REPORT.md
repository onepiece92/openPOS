# Graph Report - openPOS  (2026-11-25)

## Corpus Check
- 270 files · ~215,581 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 4627 nodes · 7389 edges · 172 communities (168 shown, 4 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 85 edges (avg confidence: 0.87)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `081aac7c`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- app_database.dart
- Table
- schema_v10.dart
- schema_v11.dart
- schema_v13.dart
- schema_v12.dart
- schema_v9.dart
- schema_v8.dart
- schema_v4.dart
- schema_v7.dart
- schema_v6.dart
- hive_provider.dart
- unit_conversion.dart
- AppDatabase
- product_form_screen.dart
- expenses_screen.dart
- DataClass
- backup_screen.dart
- StatelessWidget
- app.dart
- inventory_screen.dart
- home.dart
- report_data.dart
- payment_screen_test.dart
- payment_screen.dart
- printer_setup_screen.dart
- orders_screen.dart
- package:pos_app/features/cart/presentation/providers/cart_notifier.dart
- receipt_pdf_service.dart
- escpos_raster_test.dart
- snapshot_service.dart
- returns_table.dart
- schema_v14.dart
- pos_catalog_provider.dart
- cart_notifier.dart
- settings_screen.dart
- TextColumn get
- orders_table.dart
- IntColumn get
- snapshot_providers.dart
- orders_dao.dart
- tax_settings_screen.dart
- store_profile_edit_screen.dart
- package:flutter/services.dart
- onboarding_screen.dart
- products_screen.dart
- held_tickets_bar.dart
- order_detail_screen.dart
- products_dao.dart
- categories_screen.dart
- receipt_screen.dart
- tables_screen.dart
- order_taxes_table.dart
- inventory_filter_bar.dart
- audit_dao.dart
- schema_v15.dart
- VoidCallback?
- products_table.dart
- cart_session.dart
- package:pos_app/core/utils/currency_formatter.dart
- product_tile.dart
- inventory_card.dart
- receipt_body.dart
- expenses_dao.dart
- customers_screen.dart
- app_theme.dart
- tokens.dart
- held_order.dart
- Dependency Audit (2026-04-22)
- tax_rates_table.dart
- backup_repository.dart
- customer_form.dart
- cart_summary.dart
- order_history.dart
- article_detail_screen.dart
- settingsProvider
- place_order.dart
- _
- learn_screen.dart
- app_root.dart
- package:pos_app/core/providers/database_provider.dart
- String?
- order_summary.dart
- receipt_tax_labels_test.dart
- dashboard_body.dart
- pos_app Package Manifest (v1.0.0+9)
- loyalty_section.dart
- money.dart
- Milestone 1 — v1 Foundation & Core POS
- sales.dart
- tron_border.dart
- migration_test.dart
- customers_table.dart
- cart_item.dart
- render_receipt.dart
- receipt_roll_pdf.dart
- Offline-First Non-Negotiable Constraint
- install_macos.sh
- discount_sheet.dart
- snapshot_service_test.dart
- _PrinterSetupScreenState
- expenses_table.dart
- order_items_table.dart
- build
- app_sheet.dart
- star_printer.dart
- receipt_printer.dart
- customer_card.dart
- schema.dart
- package:pos_app/core/database/app_database.dart
- cartSessionProvider
- Riverpod Architecture Decision (provider type per concern)
- Feature-First Layered Architecture
- GeneratedDatabase
- audit_log_screen.dart
- products_provider.dart
- calc_oracle.dart
- country_default.dart
- held_orders_notifier.dart
- Banned Runtime-Fetching Packages
- package:flutter_test/flutter_test.dart
- onboarding_state.dart
- escpos_raster.dart
- tables_dao.dart
- build_runner Code Generation Workflow
- categories_table.dart
- onboardingNotifierProvider
- sell_screen_rebuild_test.dart
- Hardware Integration Pillar (ESC/POS + PDF)
- Open POS Brand Logo
- pos_filter_provider.dart
- int get
- thermal_plugin_printer.dart
- render_receipt_image.dart
- currencies.dart
- receipt_roll_pdf_test.dart
- _StoreProfileEditScreenState
- package:pos_app/features/orders/domain/order_number.dart
- databaseProvider
- package:flutter/material.dart
- country_step.dart
- Return
- package:flutter_riverpod/flutter_riverpod.dart
- auto_print_test.dart
- _
- most_sold_test.dart
- ConsumerWidget
- package:intl/intl.dart
- package:drift/drift.dart
- dashboard_screen.dart
- confirm_step.dart
- customer_picker_sheet.dart
- stock_adjustments_table.dart
- tax_dao.dart
- DateTime
- dart:convert
- static const
- shared_product_list_test.dart
- percent.dart
- dart:async
- _CartScreenState
- customers_dao.dart
- grid_product_tile.dart
- State
- printer_errors.dart
- native.dart
- main.dart
- _AutoBackupTile
- ReceiptPrinter
- build
- ReportPeriod
- reportProvider

## God Nodes (most connected - your core abstractions)
1. `AppDatabase` - 42 edges
2. `databaseProvider` - 34 edges
3. `cartSessionProvider` - 26 edges
4. `Return` - 23 edges
5. `currencyFormatterProvider` - 22 edges
6. `settingsProvider` - 20 edges
7. `DataClass` - 19 edges
8. `AuditService` - 19 edges
9. `cartProvider` - 19 edges
10. `_PaymentScreenState` - 15 edges

## Surprising Connections (you probably didn't know these)
- `Banned Runtime-Fetching Packages` --semantically_similar_to--> `Bundled Fonts Policy (google_fonts banned)`  [INFERRED] [semantically similar]
  CLAUDE.md → .planning/codebase/DEPENDENCIES.md
- `riverpod_generator Omitted` --semantically_similar_to--> `Hand-written Providers, No Riverpod Codegen`  [INFERRED] [semantically similar]
  pubspec.yaml → .planning/codebase/DEPENDENCIES.md
- `flutter_launcher_icons Config (android/ios/web)` --conceptually_related_to--> `Offline-First Non-Negotiable Constraint`  [AMBIGUOUS]
  pubspec.yaml → CLAUDE.md
- `Offline-First Non-Negotiable Constraint` --semantically_similar_to--> `Offline Reliability + Hardware Integration Focus`  [INFERRED] [semantically similar]
  CLAUDE.md → .planning/codebase/DEPENDENCIES.md
- `ROADMAP Phase 1 — Core Foundation & Shared Logic` --semantically_similar_to--> `v1 Phase 0 — Foundation (no UI)`  [INFERRED] [semantically similar]
  ROADMAP.md → v1_roadmap.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Drift Schema Migration Workflow** — claude_database_schema_change_procedure, claude_app_database_current_schema_version, claude_migration_test, claude_migrator_based_migration, _planning_codebase_dependencies_drift_dev, _planning_codebase_dependencies_build_runner, _planning_codebase_dependencies_drift [EXTRACTED 1.00]
- **Offline-First Enforcement Regime** — claude_offline_first_constraint, claude_banned_packages, claude_network_permission_lockdown, claude_deleted_sync_scaffolding, claude_url_launcher_exception, _planning_codebase_integrations_no_external_apis, project_core_mission [EXTRACTED 1.00]
- **Offline-First Enforcement Surface** — claude_offline_first_constraint, claude_no_outbound_network_calls, claude_banned_packages, claude_network_permission_ban, claude_deleted_sync_scaffolding, pubspec_jetbrainsmono_font_bundle [EXTRACTED 1.00]
- **Receipt Output Stack (thermal + ESC/POS + PDF)** — _planning_codebase_dependencies_flutter_thermal_printer, _planning_codebase_dependencies_esc_pos_utils_plus, _planning_codebase_dependencies_pdf_printing_stack [EXTRACTED 1.00]
- **End-to-End Tax Calculation Flow** — v1_roadmap_tax_engine, v1_roadmap_phase_2_product_inventory_core, v1_roadmap_phase_3_core_sales_loop, v1_roadmap_phase_4_receipts_hardware, v1_roadmap_phase_6_expenses_reports, v1_roadmap_drift_schema_v1 [EXTRACTED 1.00]
- **Open POS Brand Identity System** — assets_images_logo_open_pos_brand_logo, assets_images_logo_open_pos_wordmark, assets_images_logo_circular_arrow_mark, assets_images_logo_green_blue_gradient_palette [INFERRED 0.85]
- **Riverpod State & DI Layer Contract** — _planning_codebase_architecture_state_management_riverpod, _planning_codebase_conventions_provider_naming, v1_roadmap_riverpod_decision_table, v1_roadmap_provider_hierarchy, v1_roadmap_cart_notifier, project_riverpod_sole_di, pubspec_riverpod_generator_omitted [INFERRED 0.85]

## Communities (172 total, 4 thin omitted)

### Community 0 - "app_database.dart"
Cohesion: 0.01
Nodes (259): class OrderTaxOverride extends, class ProductComponent extends, ColumnFilters, ColumnOrderings, backfillInvoiceNumbers, backfillV14, currentSchemaVersion, migration (+251 more)

### Community 1 - "Table"
Cohesion: 0.02
Nodes (193): Table, TableInfo, AuditLog, Categories, Customers, ExpenseCategories, Expenses, OrderItems (+185 more)

### Community 2 - "schema_v10.dart"
Cohesion: 0.02
Nodes (119): Categories, action, actualTableName, address, _alias, aliasedName, allSchemaEntities, allTables (+111 more)

### Community 3 - "schema_v11.dart"
Cohesion: 0.02
Nodes (101): ProductModifiers, action, actualTableName, address, _alias, aliasedName, allSchemaEntities, allTables (+93 more)

### Community 4 - "schema_v13.dart"
Cohesion: 0.02
Nodes (101): Index, TaxGroups, action, actualTableName, address, _alias, aliasedName, allSchemaEntities (+93 more)

### Community 5 - "schema_v12.dart"
Cohesion: 0.02
Nodes (98): ProductComponents, action, actualTableName, address, _alias, aliasedName, allSchemaEntities, allTables (+90 more)

### Community 6 - "schema_v9.dart"
Cohesion: 0.02
Nodes (95): StockAdjustments, action, actualTableName, address, _alias, aliasedName, allSchemaEntities, allTables (+87 more)

### Community 7 - "schema_v8.dart"
Cohesion: 0.02
Nodes (93): ExpenseCategories, Expenses, ProductVariants, action, actualTableName, address, _alias, aliasedName (+85 more)

### Community 8 - "schema_v4.dart"
Cohesion: 0.02
Nodes (91): OrderItems, Orders, ProductTaxes, action, actualTableName, address, _alias, aliasedName (+83 more)

### Community 9 - "schema_v7.dart"
Cohesion: 0.02
Nodes (91): OrderTaxes, OrderTaxOverrides, Returns, Tables, action, actualTableName, address, _alias (+83 more)

### Community 10 - "schema_v6.dart"
Cohesion: 0.02
Nodes (90): AuditLog, GeneratedColumn, Products, TaxGroupMembers, TaxRates, action, actualTableName, address (+82 more)

### Community 11 - "hive_provider.dart"
Cohesion: 0.03
Nodes (71): autoBackupEnabled, autoBackupLastAt, _box, build, businessAddress, businessName, businessNameOrDefault, businessPan (+63 more)

### Community 12 - "unit_conversion.dart"
Cohesion: 0.20
Nodes (9): isValidConversionRate, kMaxConversionRate, kMinConversionRate, null, parseConversionRate, text, toInt, validateConversionRate (+1 more)

### Community 13 - "AppDatabase"
Cohesion: 0.05
Nodes (57): _, @DriftDatabase, AppDatabase, AuditService, package:pos_app/features/reports/domain/report_data.dart, package:pos_app/features/reports/presentation/widgets/dashboard_body.dart, package:pos_app/features/returns/domain/process_return.dart, package:pos_app/features/returns/domain/void_order.dart (+49 more)

### Community 14 - "product_form_screen.dart"
Cohesion: 0.05
Nodes (38): _categoryId, _ComponentEntry, _ComponentPickerSheet, _ComponentPickerSheetState, _components, _conversionCtrl, createState, _delete (+30 more)

### Community 15 - "expenses_screen.dart"
Cohesion: 0.05
Nodes (49): _amountCtrl, build, categories, category, _CategoryChips, _categoryId, _check, _Chip (+41 more)

### Community 16 - "DataClass"
Cohesion: 0.10
Nodes (38): Insertable, OrderNumberX, UpdateCompanion, AuditLogCompanion, AuditLogData, CategoriesCompanion, Category, Customer (+30 more)

### Community 17 - "backup_screen.dart"
Cohesion: 0.07
Nodes (32): File, backupRepositoryProvider, snapshotCoordinatorProvider, BackupScreen, _BackupScreenState, _BackupTile, _buildInfoCard, color (+24 more)

### Community 18 - "StatelessWidget"
Cohesion: 0.08
Nodes (28): build, cs, key_, _KeyChip, keys, label, _SectionHeader, _ShortcutRow (+20 more)

### Community 19 - "app.dart"
Cohesion: 0.05
Nodes (38): ChangeNotifier, EditableText, GoRouter, AppScrollBehavior, getKeyboardDismissBehavior, ping, POSApp, refresh (+30 more)

### Community 20 - "inventory_screen.dart"
Cohesion: 0.08
Nodes (29): Iterable, lowStockThresholdProvider, _fitsStock, build, createState, dispose, _filter, _filtered (+21 more)

### Community 21 - "home.dart"
Cohesion: 0.08
Nodes (26): demoDataServiceProvider, categories, _CategoryRow, _Chip, createState, dispose, _EmptyProductsState, _EmptyProductsStateState (+18 more)

### Community 22 - "report_data.dart"
Cohesion: 0.04
Nodes (46): avgOrder, changes, chartDates, chartHighlightIndex, chartTitle, chartTotals, costIsIncomplete, costOfGoods (+38 more)

### Community 23 - "payment_screen_test.dart"
Cohesion: 0.04
Nodes (57): Box, Completer, dart:io, Directory, _box, formatTicketNumber, kTicketSeqKey, next (+49 more)

### Community 24 - "payment_screen.dart"
Cohesion: 0.06
Nodes (44): currencyCodeProvider, currencySymbolProvider, build, CartDetailScreen, _ClearCartButton, build, createState, customer (+36 more)

### Community 25 - "printer_setup_screen.dart"
Cohesion: 0.07
Nodes (29): PrinterDriver, lastSdkNeedingLocationForBle, permissionsForScan, scanNeedsLocation, createState, _devices, _devicesSub, _disconnectSavedPrinter (+21 more)

### Community 26 - "orders_screen.dart"
Cohesion: 0.06
Nodes (37): orderHistoryProvider, _body, build, _clearQuery, createState, cs, customerName, _debounce (+29 more)

### Community 27 - "package:pos_app/features/cart/presentation/providers/cart_notifier.dart"
Cohesion: 0.06
Nodes (37): transaction, voidOrder, package:pos_app/core/services/audit_service.dart, package:pos_app/features/cart/data/place_order.dart, package:pos_app/features/cart/data/ticket_sequence.dart, package:pos_app/features/cart/domain/cart_item.dart, package:pos_app/features/cart/presentation/providers/cart_notifier.dart, item (+29 more)

### Community 28 - "receipt_pdf_service.dart"
Cohesion: 0.09
Nodes (22): baseStyle, billRow, boldStyle, buildReceiptPdf, bytes, customerName, _dataCell, dateFmt (+14 more)

### Community 29 - "escpos_raster_test.dart"
Cohesion: 0.12
Nodes (15): package:image/image.dart, package:pos_app/core/utils/bundled_fonts.dart, package:pos_app/features/printing/domain/escpos_raster.dart, StateError, main, _blockPage, _countSequence, _firstRaster (+7 more)

### Community 30 - "snapshot_service.dart"
Cohesion: 0.04
Nodes (45): _absentSuffix, _backupDb, _bakSuffix, cause, create, createdAt, dbBytes, dbEntryName (+37 more)

### Community 31 - "returns_table.dart"
Cohesion: 0.12
Nodes (15): createdAt, id, orderId, OrderTaxOverrides, originalTax, overrideTax, reason, amount (+7 more)

### Community 32 - "schema_v14.dart"
Cohesion: 0.02
Nodes (102): Customers, action, actualTableName, address, _alias, aliasedName, allSchemaEntities, allTables (+94 more)

### Community 33 - "pos_catalog_provider.dart"
Cohesion: 0.08
Nodes (24): AsyncValue, buildPosSearchIndex, cart, catalogEmpty, categoryId, committedMainUnits, favorites, favoritesOnly (+16 more)

### Community 34 - "cart_notifier.dart"
Cohesion: 0.06
Nodes (43): @immutable, AppSettings, defaultTaxIdProvider, SettingsNotifier, heldOrdersBoxProvider, ticketSequenceProvider, CartSession, addItem (+35 more)

### Community 35 - "settings_screen.dart"
Cohesion: 0.17
Nodes (11): build, package:pos_app/features/settings/presentation/widgets/appearance_section.dart, package:pos_app/features/settings/presentation/widgets/backup_section.dart, package:pos_app/features/settings/presentation/widgets/currency_section.dart, package:pos_app/features/settings/presentation/widgets/danger_section.dart, package:pos_app/features/settings/presentation/widgets/inventory_section.dart, package:pos_app/features/settings/presentation/widgets/loyalty_section.dart, package:pos_app/features/settings/presentation/widgets/printer_section.dart (+3 more)

### Community 36 - "TextColumn get"
Cohesion: 0.08
Nodes (23): @DataClassName, DateTimeColumn get, action, createdAt, entityId, entityType, id, metadata (+15 more)

### Community 37 - "orders_table.dart"
Cohesion: 0.09
Nodes (22): changeAmount, createdAt, customerId, discountIsPercent, discountTotal, discountValue, id, invoiceNo (+14 more)

### Community 38 - "IntColumn get"
Cohesion: 0.10
Nodes (19): IntColumn get, componentProductId, compositeProductId, id, ProductComponents, quantity, primaryKey, productId (+11 more)

### Community 39 - "snapshot_providers.dart"
Cohesion: 0.11
Nodes (17): autoBackupDir, autoBackupLastError, create, createAndShare, docs, inspect, kAutoBackupInterval, kAutoBackupKeep (+9 more)

### Community 40 - "orders_dao.dart"
Cohesion: 0.06
Nodes (30): _escapeLike, getById, getItems, getTaxBreakdown, hasRestockedReturn, historyPage, incrementPrintCount, insertItems (+22 more)

### Community 41 - "tax_settings_screen.dart"
Cohesion: 0.10
Nodes (20): FormState, taxRatesStreamProvider, build, createState, dispose, existing, _formKey, _inclusionType (+12 more)

### Community 42 - "store_profile_edit_screen.dart"
Cohesion: 0.15
Nodes (12): class, _addressCtrl, build, createState, dispose, _initialised, _label, _loading (+4 more)

### Community 43 - "package:flutter/services.dart"
Cohesion: 0.09
Nodes (20): AndroidSdk, _cached, _methods, _read, sdkInt, _devices, dispose, _methods (+12 more)

### Community 44 - "onboarding_screen.dart"
Cohesion: 0.09
Nodes (22): _businessNameCtrl, _canProceed, _countries, createState, dispose, _filterCountries, _filtered, _loadingCountries (+14 more)

### Community 45 - "products_screen.dart"
Cohesion: 0.09
Nodes (22): categories, _CategoryChips, categoryName, _Chip, createState, cs, dispose, fmt (+14 more)

### Community 46 - "held_tickets_bar.dart"
Cohesion: 0.09
Nodes (27): AnimationController, ConsumerState, ConsumerStatefulWidget, heldOrdersProvider, CheckoutBar, _buildActiveList, _buildArchivedList, createState (+19 more)

### Community 47 - "order_detail_screen.dart"
Cohesion: 0.09
Nodes (23): auditServiceProvider, businessName, customer, data, db, _DetailBody, _DetailData, fmt (+15 more)

### Community 48 - "products_dao.dart"
Cohesion: 0.09
Nodes (21): deductStock, deleteCategory, getAllCategories, getById, getBySku, getComponents, replaceComponents, restock (+13 more)

### Community 49 - "categories_screen.dart"
Cohesion: 0.09
Nodes (21): categoriesStreamProvider, productsByCategoryProvider, build, CategoriesScreen, category, _CategoryCard, _colorFor, _confirmDelete (+13 more)

### Community 50 - "receipt_screen.dart"
Cohesion: 0.11
Nodes (18): ReceiptBodyData, businessName, customer, data, db, fmt, _handle, items (+10 more)

### Community 51 - "tables_screen.dart"
Cohesion: 0.10
Nodes (21): _assignToCart, _capacityCtrl, createState, dispose, existing, initState, isCurrentCartTable, isOccupied (+13 more)

### Community 52 - "order_taxes_table.dart"
Cohesion: 0.12
Nodes (14): BoolColumn get, color, ExpenseCategories, id, isDefault, name, id, isInclusive (+6 more)

### Community 53 - "inventory_filter_bar.dart"
Cohesion: 0.17
Nodes (11): build, _Chip, color, InventoryFilterBar, label, lowCount, onSelect, onTap (+3 more)

### Community 54 - "audit_dao.dart"
Cohesion: 0.10
Nodes (24): @DriftAccessor, _$AuditDaoMixin, _$CustomersDaoMixin, DatabaseAccessor, _$ExpensesDaoMixin, _$InventoryDaoMixin, AuditDao, log (+16 more)

### Community 55 - "schema_v15.dart"
Cohesion: 0.02
Nodes (109): action, actualTableName, address, _alias, aliasedName, allSchemaEntities, allTables, amount (+101 more)

### Community 56 - "VoidCallback?"
Cohesion: 0.13
Nodes (13): build, _labels, onSkip, step, WizardHeader, build, canNext, onBack (+5 more)

### Community 57 - "products_table.dart"
Cohesion: 0.10
Nodes (19): categoryId, conversionRate, createdAt, id, imagePath, isActive, isComposite, isHiddenInPos (+11 more)

### Community 58 - "cart_session.dart"
Cohesion: 0.14
Nodes (13): bool get, copyWith, customerId, fresh, heldTicketId, isEditingHeldTicket, loyaltyPointsToRedeem, openedAt (+5 more)

### Community 59 - "package:pos_app/core/utils/currency_formatter.dart"
Cohesion: 0.08
Nodes (23): CurrencyFormatter, decimalDigits, _fmt, format, formatPlain, locale, _plainFmt, symbol (+15 more)

### Community 60 - "product_tile.dart"
Cohesion: 0.15
Nodes (12): bg, color, cs, icon, onDecrement, onIncrement, onTap, product (+4 more)

### Community 61 - "inventory_card.dart"
Cohesion: 0.10
Nodes (19): _apply, badgeColor, build, canDecrement, canIncrement, cs, _decrement, icon (+11 more)

### Community 62 - "receipt_body.dart"
Cohesion: 0.10
Nodes (19): _BillRow, build, businessName, customer, data, _DataCell, fmt, _HeaderCell (+11 more)

### Community 63 - "expenses_dao.dart"
Cohesion: 0.15
Nodes (12): getAll, getAllCategories, insert, insertCategory, totalForPeriod, updateExpense, upsertCategory, watchAll (+4 more)

### Community 64 - "customers_screen.dart"
Cohesion: 0.12
Nodes (18): IconData get, build, createState, CustomersScreen, _CustomersScreenState, dispose, _filterAndSort, icon (+10 more)

### Community 65 - "app_theme.dart"
Cohesion: 0.10
Nodes (19): AppTheme, backgroundGradient, _build, ctaButtonStyle, _dark, _darkGrad, _darkScheme, _fontFamily (+11 more)

### Community 66 - "tokens.dart"
Cohesion: 0.11
Nodes (18): AppFonts, AppOpacity, heavy, lg, md, medium, mono, Radii (+10 more)

### Community 67 - "held_order.dart"
Cohesion: 0.10
Nodes (20): archivedAt, copyWith, createdAt, customerId, customerName, fromJson, id, isArchived (+12 more)

### Community 68 - "Dependency Audit (2026-04-22)"
Cohesion: 0.18
Nodes (18): build_runner (Generator CLI), Dependency Audit (2026-04-22), drift (SQLite Relational Storage), drift_dev (Database Layer Codegen), esc_pos_utils_plus (ESC/POS Encoding), flutter_riverpod (State Management), flutter_thermal_printer (POS Hardware), hive / hive_flutter (KV Storage) (+10 more)

### Community 69 - "tax_rates_table.dart"
Cohesion: 0.18
Nodes (10): createdAt, id, inclusionType, isActive, isCompound, name, rate, roundingMode (+2 more)

### Community 70 - "backup_repository.dart"
Cohesion: 0.09
Nodes (22): @visibleForTesting, handleExitRequest, _csvEol, db, exportCustomers, exportExpenses, exportOrders, exportProducts (+14 more)

### Community 71 - "customer_form.dart"
Cohesion: 0.11
Nodes (18): _addressCtrl, build, createState, customer, CustomerForm, _CustomerFormState, _delete, _discountCtrl (+10 more)

### Community 72 - "cart_summary.dart"
Cohesion: 0.10
Nodes (19): amount, CartSummary, isInclusive, loyaltyDiscount, maxRedeemablePoints, name, orderDiscount, pointsRedeemed (+11 more)

### Community 73 - "order_history.dart"
Cohesion: 0.10
Nodes (20): _changes, copyWith, _db, dispose, error, _generation, hasMore, isLoading (+12 more)

### Community 74 - "article_detail_screen.dart"
Cohesion: 0.11
Nodes (17): ArticleDetailScreen, ArticleSection, build, category, cs, heading, icon, readTime (+9 more)

### Community 75 - "settingsProvider"
Cohesion: 0.15
Nodes (18): int?, invoicePrefixProvider, loyaltyEarnRateProvider, loyaltyEnabledProvider, loyaltyPointValueProvider, settingsProvider, _selectDevice, _save (+10 more)

### Community 76 - "place_order.dart"
Cohesion: 0.22
Nodes (8): components, cost, invoicePrefix, placeOrder, roundMoney, transaction, _unitCostNow, required double tenderedAmount,
  String

### Community 77 - "_"
Cohesion: 0.10
Nodes (20): dart:math, _, CartCalculator, compute, _roundingModeFor, package:pos_app/core/utils/tax_calculator.dart, package:pos_app/features/cart/domain/cart_calculator.dart, package:pos_app/features/cart/domain/cart_session.dart (+12 more)

### Community 78 - "learn_screen.dart"
Cohesion: 0.07
Nodes (27): ColorScheme, _Article, _ArticleCard, _articles, category, cs, description, icon (+19 more)

### Community 79 - "app_root.dart"
Cohesion: 0.07
Nodes (28): autoBackupDelay, _autoBackupRun, _autoBackupTimer, build, child, _closeDatabaseForExit, _container, createState (+20 more)

### Community 80 - "package:pos_app/core/providers/database_provider.dart"
Cohesion: 0.10
Nodes (19): _db, DemoDataService, seed, _seedDatabase, _settings, back, build, next (+11 more)

### Community 81 - "String?"
Cohesion: 0.07
Nodes (28): double?, IconData?, action, AppEmptyState, build, icon, subtitle, title (+20 more)

### Community 82 - "order_summary.dart"
Cohesion: 0.12
Nodes (16): addColor, cs, fmt, label, onTap, ref, _showDiscountSheet, _showTaxPicker (+8 more)

### Community 83 - "receipt_tax_labels_test.dart"
Cohesion: 0.11
Nodes (16): package:pos_app/features/printing/domain/render_receipt.dart, package:pos_app/features/receipts/domain/receipt_text.dart, fmt, item, main, null, order, _sampleData (+8 more)

### Community 84 - "dashboard_body.dart"
Cohesion: 0.12
Nodes (16): ReportData, build, _buildKpiRows, cs, DashboardBody, data, _fmt, isCustomRange (+8 more)

### Community 85 - "pos_app Package Manifest (v1.0.0+9)"
Cohesion: 0.17
Nodes (15): Technology Stack (Dart 3.5+, Flutter 3.24+), pos_app Package Manifest (v1.0.0+9), ROADMAP Phase 1 — Core Foundation & Shared Logic, ROADMAP Phase 3 — Product Management (The Catalog), ROADMAP Phase 4 — POS Interface (Main Flow), Append-Only Audit Log, Connectivity Detection task (0.5, connectivity_plus), Drift Schema — Full v1 Table List (+7 more)

### Community 86 - "loyalty_section.dart"
Cohesion: 0.22
Nodes (9): createState, dispose, _earnCtrl, earnRate, _LoyaltyRateSheet, _LoyaltyRateSheetState, pointValue, _showRateSheet (+1 more)

### Community 87 - "money.dart"
Cohesion: 0.09
Nodes (22): allowZero, byLoss, cents, eps, exact, isRequired, kMaxMoneyAmount, kMaxMoneyAmountLabel (+14 more)

### Community 88 - "Milestone 1 — v1 Foundation & Core POS"
Cohesion: 0.18
Nodes (14): Dual Data Layer (Drift + Hive), Navigation Pillar (GoRouter routerProvider), Drift Layout Convention (tables, daos, AppDatabase migrations), Responsive Desktop POS Layout Rule, No Hardcoded Colors (AppTheme / colorScheme), Local Auth (no external identity provider), Platform Requirements (Android API 21+, iOS 12+), Premium Glassmorphic Dark Aesthetic (+6 more)

### Community 89 - "sales.dart"
Cohesion: 0.13
Nodes (14): int? customerId,
  int, line, loyaltyDiscount, paymentMethod, placeOrder, points, pointsRedeemed, pointsToEarn (+6 more)

### Community 90 - "tron_border.dart"
Cohesion: 0.15
Nodes (12): CustomPainter, color, e, extractWrappedPath, f, len, p, paint (+4 more)

### Community 91 - "migration_test.dart"
Cohesion: 0.18
Nodes (10): generated/schema.dart, package:drift_dev/api/migrations_common.dart, package:drift_dev/api/migrations_native.dart, SchemaVerifier, indexes, main, seedV13, shipped (+2 more)

### Community 92 - "customers_table.dart"
Cohesion: 0.14
Nodes (13): address, createdAt, Customers, defaultDiscount, defaultDiscountIsPercent, email, id, isTaxExempt (+5 more)

### Community 93 - "cart_item.dart"
Cohesion: 0.12
Nodes (16): copyWith, grossAmount, isSecondaryUnit, isTaxable, lineDiscount, lineSubtotal, mainUnitQty, name (+8 more)

### Community 94 - "render_receipt.dart"
Cohesion: 0.14
Nodes (13): bytes, customerName, g, isCopy, _kv, method, methodLabel, profile (+5 more)

### Community 95 - "receipt_roll_pdf.dart"
Cohesion: 0.11
Nodes (18): base, body, bold, buildReceiptRollPdf, buildTestPageRollPdf, dateFmt, doc, font (+10 more)

### Community 96 - "Offline-First Non-Negotiable Constraint"
Cohesion: 0.19
Nodes (13): Zero External APIs / Services, Deleted Sync / Cloud-Backup Scaffolding, Graphify Knowledge Graph Workflow Rule, Sandbox-Blocked Release Binary (no INTERNET / network entitlements), Platform Network Permission Lockdown, No Outbound Network Calls Rule, Offline-First Non-Negotiable Constraint, url_launcher Network-Adjacent Exception (+5 more)

### Community 98 - "discount_sheet.dart"
Cohesion: 0.18
Nodes (10): double get, build, createState, _ctrl, currentDiscount, dispose, initState, isPercent (+2 more)

### Community 99 - "snapshot_service_test.dart"
Cohesion: 0.09
Nodes (23): Exception, RestoreFatalException, RestoreRolledBackException, SnapshotFormatException, package:archive/archive.dart, package:sqlite3/sqlite3.dart, craftZip, dbFileIn (+15 more)

### Community 100 - "_PrinterSetupScreenState"
Cohesion: 0.24
Nodes (14): printerDeviceAddressProvider, printerDeviceNameProvider, printerDriverProvider, printerPaperWidthProvider, build, _orderDetailProvider, OrderDetailScreen, receiptPrinterProvider (+6 more)

### Community 101 - "expenses_table.dart"
Cohesion: 0.17
Nodes (11): amount, categoryId, createdAt, date, id, isRecurring, isTaxDeductible, notes (+3 more)

### Community 102 - "order_items_table.dart"
Cohesion: 0.15
Nodes (12): discount, id, lineTotal, orderId, productId, productName, quantity, taxAmount (+4 more)

### Community 103 - "build"
Cohesion: 0.17
Nodes (16): build, build, build, build, Route /cart, Route /categories, Route /customers, Route /expenses (+8 more)

### Community 104 - "app_sheet.dart"
Cohesion: 0.17
Nodes (10): cs, failurePrefix, messenger, draggable, initialSize, minSize, package:pos_app/shared/widgets/keyboard_safe.dart, required WidgetBuilder builder,
  bool (+2 more)

### Community 105 - "star_printer.dart"
Cohesion: 0.13
Nodes (14): _devices, _discovery, dispose, _events, _found, _isSupported, _methods, _printImages (+6 more)

### Community 106 - "receipt_printer.dart"
Cohesion: 0.06
Nodes (30): address, data, devices, DiscoveredPrinter, driver, escPosPrinterProvider, fmt, fromKey (+22 more)

### Community 107 - "customer_card.dart"
Cohesion: 0.11
Nodes (16): Color, _Badge, bg, customer, CustomerCard, fg, icon, label (+8 more)

### Community 108 - "schema.dart"
Cohesion: 0.12
Nodes (16): package:drift/internal/migrations.dart, schema_v10.dart, schema_v11.dart, schema_v12.dart, schema_v13.dart, schema_v14.dart, schema_v15.dart, schema_v4.dart (+8 more)

### Community 109 - "package:pos_app/core/database/app_database.dart"
Cohesion: 0.07
Nodes (23): _db, log, orderPlaced, orderRefunded, orderVoided, settingChanged, taxOverridden, customerId (+15 more)

### Community 110 - "cartSessionProvider"
Cohesion: 0.09
Nodes (32): cartSessionProvider, clear, activeHeldOrdersProvider, _HeldTicketsSheetState, _loadTicket, build, occupied, onSelect (+24 more)

### Community 111 - "Riverpod Architecture Decision (provider type per concern)"
Cohesion: 0.24
Nodes (10): Data Flow (UI to Notifier to DAO to Stream), State Management Pillar (Riverpod), Package-Imports-Only Rule, Provider Suffix Naming Convention, No Error Tracking, Analytics, or CI Pipeline, Enforced Lint Rules (analysis_options), Riverpod as Sole DI Mechanism, Testing Practice (unit for domain, widget for shared) (+2 more)

### Community 112 - "Feature-First Layered Architecture"
Cohesion: 0.20
Nodes (10): lib/ Directory Structure (core, features, shared), Feature-First Layered Architecture, Presentation-Domain-Data Feature Pattern, drift as Critical Persistence Dependency, graphify Knowledge Graph Workflow, Core Mission (100% offline POS), Guiding Principles (offline-first, hardware, feature-first, premium), Offline-First Flutter POS (project charter) (+2 more)

### Community 113 - "GeneratedDatabase"
Cohesion: 0.17
Nodes (12): GeneratedDatabase, DatabaseAtV10, DatabaseAtV11, DatabaseAtV12, DatabaseAtV13, DatabaseAtV14, DatabaseAtV15, DatabaseAtV4 (+4 more)

### Community 114 - "audit_log_screen.dart"
Cohesion: 0.20
Nodes (11): action, _ActionChip, _actionColor, _actionIcon, AuditLogScreen, auditLogsProvider, build, color (+3 more)

### Community 115 - "products_provider.dart"
Cohesion: 0.10
Nodes (20): applyProductsFilter, clearSearch, copyWith, list, mostSoldWindow, outOfStockOnly, productSalesCountProvider, ProductsFilterNotifier (+12 more)

### Community 116 - "calc_oracle.dart"
Cohesion: 0.04
Nodes (46): BigInt, int? discPermille,
  int, balance, base, baseOnHalfCent, bp, cents, d (+38 more)

### Community 117 - "country_default.dart"
Cohesion: 0.20
Nodes (9): code, CountryDefault, currency, fromJson, name, symbol, taxName, taxRate (+1 more)

### Community 118 - "held_orders_notifier.dart"
Cohesion: 0.13
Nodes (14): HeldOrder, archive, archiveAll, archivedHeldOrdersProvider, _box, build, delete, deleteAllArchived (+6 more)

### Community 119 - "Banned Runtime-Fetching Packages"
Cohesion: 0.28
Nodes (9): Bundled Fonts Policy (google_fonts banned), google_fonts listed as Utility dependency, Local-Only Data Storage (Drift file + Hive + path_provider), Banned Runtime-Fetching Packages, Export & Sharing Stack (share_plus, csv, file_picker, permission_handler), Bundled JetBrainsMono Font Family, ROADMAP Phase 6 — Order History & Local Reporting, v1 Phase 5 — Backup & Data Safety (local-only) (+1 more)

### Community 120 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.09
Nodes (19): left, processReturn, refundableAmount, refunded, transaction, package:flutter_test/flutter_test.dart, package:pos_app/core/utils/money.dart, package:pos_app/features/products/domain/unit_conversion.dart (+11 more)

### Community 121 - "onboarding_state.dart"
Cohesion: 0.22
Nodes (8): businessName, copyWith, country, saving, step, taxName, taxRate, package:pos_app/features/onboarding/domain/country_default.dart

### Community 122 - "escpos_raster.dart"
Cohesion: 0.11
Nodes (17): dart:isolate, Future, bytes, cached, canvas, escPosProfile, escPosRasterBytes, escPosRasterBytesSync (+9 more)

### Community 123 - "tables_dao.dart"
Cohesion: 0.25
Nodes (7): deleteById, getAll, getById, upsert, watchAll, package:pos_app/core/database/tables/tables_table.dart, _

### Community 124 - "build_runner Code Generation Workflow"
Cohesion: 0.29
Nodes (7): build_runner Code Generation Workflow, Code Generation Dev Dependencies (riverpod_generator, drift_dev, build_runner), build.yaml Code Generation Config, custom_lint Analyzer Plugin (enabled in analysis_options), Generated-File Exclusion (*.g.dart, *.freezed.dart), custom_lint / riverpod_lint Commented Out, riverpod_generator Omitted

### Community 125 - "categories_table.dart"
Cohesion: 0.22
Nodes (8): Categories, createdAt, id, name, parentId, sortOrder, taxRateId, updatedAt

### Community 126 - "onboardingNotifierProvider"
Cohesion: 0.20
Nodes (11): build, onboardingNotifierProvider, _back, build, _finish, initState, _loadCountries, _next (+3 more)

### Community 127 - "sell_screen_rebuild_test.dart"
Cohesion: 0.09
Nodes (22): AppBar, CustomPaint, FilterChip, GridView, ListView, NavigatorState, package:pos_app/features/cart/presentation/widgets/checkout_bar.dart, package:pos_app/features/cart/presentation/widgets/grid_product_tile.dart (+14 more)

### Community 128 - "Hardware Integration Pillar (ESC/POS + PDF)"
Cohesion: 0.47
Nodes (6): Hardware Integration Pillar (ESC/POS + PDF), PrintingService Abstraction, heathen_printer_plus (documented printer package), flutter_thermal_printer dependency, ROADMAP Phase 5 — Hardware Deep Integration, v1 Phase 4 — Receipts & Hardware

### Community 129 - "Open POS Brand Logo"
Cohesion: 0.53
Nodes (6): Interlocking Circular Arrow Mark, Green-to-Blue Gradient Brand Palette, Open POS Brand Logo, OPEN POS Wordmark, Point-of-Sale Product Identity, Transaction Cycle Visual Metaphor

### Community 130 - "pos_filter_provider.dart"
Cohesion: 0.12
Nodes (16): clearSearch, copyWith, favoritesOnly, isGrid, PosFilterNotifier, PosFilterState, PosSortMode, search (+8 more)

### Community 131 - "int get"
Cohesion: 0.40
Nodes (4): int get, billNo, displayNo, String get

### Community 132 - "thermal_plugin_printer.dart"
Cohesion: 0.12
Nodes (15): _connect, _connectTimeout, devices, _disconnect, _ftp, _pluginDevice, _printPages, printReceipt (+7 more)

### Community 133 - "render_receipt_image.dart"
Cohesion: 0.15
Nodes (12): dart:typed_data, doc, escPosPrintWidthDots, isCopy, kReceiptDpi, pages, _rasterise, renderReceiptImages (+4 more)

### Community 135 - "receipt_roll_pdf_test.dart"
Cohesion: 0.18
Nodes (10): package:pdf/pdf.dart, package:pos_app/features/printing/domain/receipt_roll_pdf.dart, package:pos_app/features/printing/domain/render_receipt_image.dart, doc, fmt, main, order, _pageFormats (+2 more)

### Community 136 - "_StoreProfileEditScreenState"
Cohesion: 0.42
Nodes (10): businessAddressProvider, businessNameProvider, businessPanProvider, businessPhoneProvider, businessTaglineProvider, didChangeDependencies, _StoreProfileEditScreenState, build (+2 more)

### Community 137 - "package:pos_app/features/orders/domain/order_number.dart"
Cohesion: 0.25
Nodes (7): addBack, customerId, items, label, restockOrderItems, reverseLoyalty, package:pos_app/features/orders/domain/order_number.dart

### Community 138 - "databaseProvider"
Cohesion: 0.15
Nodes (16): databaseProvider, settingsBoxProvider, _delete, _save, _showAddCategoryDialog, OnboardingState, finish, OnboardingNotifier (+8 more)

### Community 139 - "package:flutter/material.dart"
Cohesion: 0.07
Nodes (23): BackupSection, build, build, SettingsSectionHeader, title, build, i, _indexFor (+15 more)

### Community 140 - "country_step.dart"
Cohesion: 0.22
Nodes (8): build, countries, CountryStep, loading, onSearch, onSelect, searchController, selected

### Community 141 - "Return"
Cohesion: 0.11
Nodes (16): bundledFontData, bundledPdfFont, cached, _fontData, future, jetBrainsMonoBold, jetBrainsMonoItalic, jetBrainsMonoRegular (+8 more)

### Community 142 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.05
Nodes (42): CartNotifier get, db, add, _allowQty, _cart, _committed, _container, _messenger (+34 more)

### Community 143 - "auto_print_test.dart"
Cohesion: 0.12
Nodes (15): package:pos_app/features/printing/domain/auto_print.dart, box, db, devices, failWith, main, makeContainer, printed (+7 more)

### Community 144 - "_"
Cohesion: 0.33
Nodes (7): _, compoundTax, invoiceTax, lineItemTax, priceBeforeTax, _round, TaxCalculator

### Community 145 - "most_sold_test.dart"
Cohesion: 0.07
Nodes (28): int tea,, package:drift/native.dart, package:pos_app/core/services/demo_data_service.dart, QueryInterceptor, ../../_support/query_recorder.dart, db, expectIndexed, from (+20 more)

### Community 146 - "ConsumerWidget"
Cohesion: 0.23
Nodes (15): ConsumerWidget, cartMainUnitQtyProvider, _ListSeparator, build, GridProductTile, _TaxPickerSheet, build, PosProductTile (+7 more)

### Community 147 - "package:intl/intl.dart"
Cohesion: 0.14
Nodes (12): AutoPrintService, printOrder, _ref, buildReceiptText, dateFmt, join, lines, o (+4 more)

### Community 148 - "package:drift/drift.dart"
Cohesion: 0.13
Nodes (13): getAdjustmentsForProduct, logAdjustment, watchLowStock, package:drift/drift.dart, package:pos_app/core/database/tables/products_table.dart, package:pos_app/core/database/tables/stock_adjustments_table.dart, db, main (+5 more)

### Community 149 - "dashboard_screen.dart"
Cohesion: 0.22
Nodes (8): DateTimeRange?, createState, _customRange, _period, _pickDateRange, _rangeLabelFmt, package:pos_app/features/side_nav/presentation/side_nav.dart, static final

### Community 150 - "confirm_step.dart"
Cohesion: 0.07
Nodes (22): build, BusinessNameStep, controller, build, children, ConfirmStep, icon, isLast (+14 more)

### Community 151 - "customer_picker_sheet.dart"
Cohesion: 0.20
Nodes (10): build, createState, CustomerPickerSheet, _CustomerPickerSheetState, customers, onSelect, _search, selectedId (+2 more)

### Community 152 - "stock_adjustments_table.dart"
Cohesion: 0.13
Nodes (14): @TableIndex, AuditLog, Expenses, OrderItems, OrderTaxes, Orders, Returns, createdAt (+6 more)

### Community 153 - "tax_dao.dart"
Cohesion: 0.22
Nodes (8): getAll, getById, getRatesForProduct, setProductTaxes, upsertRate, watchActive, package:pos_app/core/database/tables/product_taxes_table.dart, _

### Community 154 - "DateTime"
Cohesion: 0.18
Nodes (13): DateTime, BackupRepository, package:csv/csv.dart, package:pos_app/features/backup/data/backup_repository.dart, bytesOf, db, legacyAllOrdersWithItems, legacyOrdersCsv (+5 more)

### Community 155 - "dart:convert"
Cohesion: 0.33
Nodes (5): dart:convert, _cache, CountryRepository, load, static List

### Community 156 - "static const"
Cohesion: 0.25
Nodes (8): themeModeProvider, AppearanceSection, build, current, _options, _showThemePicker, static const, ThemeMode

### Community 157 - "shared_product_list_test.dart"
Cohesion: 0.25
Nodes (7): package:pos_app/features/cart/domain/pos_filter_provider.dart, package:pos_app/features/inventory/presentation/inventory_screen.dart, ../../_support/fake_products.dart, ids, main, original, source

### Community 158 - "percent.dart"
Cohesion: 0.22
Nodes (8): formatPercent, formatPercentNumber, formatRateForEdit, formatRatePercent, kPercentDecimals, kPercentInputPattern, text, RegExp

### Community 159 - "dart:async"
Cohesion: 0.17
Nodes (11): AppLifecycleListener, dart:async, dart:ui, Duration, DatabaseExitGuard, dispose, _listener, timeout (+3 more)

### Community 160 - "_CartScreenState"
Cohesion: 0.33
Nodes (6): posCatalogProvider, posFilterProvider, CartScreen, _CartScreenState, initState, _ProductArea

### Community 161 - "customers_dao.dart"
Cohesion: 0.20
Nodes (9): addLoyaltyPoints, getAll, getById, redeemLoyaltyPoints, search, upsert, watchAll, package:pos_app/core/database/tables/customers_table.dart (+1 more)

### Community 162 - "grid_product_tile.dart"
Cohesion: 0.33
Nodes (5): product, package:pos_app/features/cart/domain/pos_catalog_provider.dart, package:pos_app/features/cart/presentation/pos_cart_actions.dart, package:pos_app/features/products/domain/favorites_provider.dart, package:pos_app/shared/widgets/step_button.dart

### Community 163 - "State"
Cohesion: 0.32
Nodes (8): AppRoot, AppRootState, _NoticeOverlay, _NoticeOverlayState, DiscountSheet, _DiscountSheetState, State, StatefulWidget

### Community 164 - "printer_errors.dart"
Cohesion: 0.33
Nodes (5): friendlyPrinterError, known, _match, null, raw

### Community 165 - "native.dart"
Cohesion: 0.29
Nodes (6): databaseFile, dir, kDatabaseFileName, openConnection, package:path/path.dart, package:path_provider/path_provider.dart

### Community 166 - "main.dart"
Cohesion: 0.33
Nodes (5): initFlutter, main, wait, package:pos_app/app_root.dart, package:pos_app/features/backup/data/snapshot_providers.dart

### Community 167 - "_AutoBackupTile"
Cohesion: 0.67
Nodes (4): autoBackupEnabledProvider, autoBackupLastAtProvider, _AutoBackupTile, build

### Community 168 - "ReceiptPrinter"
Cohesion: 0.40
Nodes (5): SppPrinter, StarBluetoothPrinter, ThermalPluginPrinter, ReceiptPrinter, FakeReceiptPrinter

### Community 169 - "build"
Cohesion: 0.67
Nodes (3): build, MaterialPageRoute, main

## Ambiguous Edges - Review These
- `flutter_launcher_icons Config (android/ios/web)` → `Offline-First Non-Negotiable Constraint`  [AMBIGUOUS]
  pubspec.yaml · relation: conceptually_related_to
- `v1 Phase 3 — Core Sales Loop` → `pos_app Package Manifest (v1.0.0+9)`  [AMBIGUOUS]
  v1_roadmap.md · relation: references
- `v1 Phase 7 — Customers, Loyalty & Audit` → `pos_app Package Manifest (v1.0.0+9)`  [AMBIGUOUS]
  v1_roadmap.md · relation: references
- `Responsive Desktop POS Layout Rule` → `Platform Requirements (Android API 21+, iOS 12+)`  [AMBIGUOUS]
  .planning/codebase/CONVENTIONS.md · relation: conceptually_related_to

## Knowledge Gaps
- **3225 isolated node(s):** `refresh`, `getKeyboardDismissBehavior`, `_slide`, `ping`, `_container` (+3220 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **4 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `flutter_launcher_icons Config (android/ios/web)` and `Offline-First Non-Negotiable Constraint`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **What is the exact relationship between `v1 Phase 3 — Core Sales Loop` and `pos_app Package Manifest (v1.0.0+9)`?**
  _Edge tagged AMBIGUOUS (relation: references) - confidence is low._
- **What is the exact relationship between `v1 Phase 7 — Customers, Loyalty & Audit` and `pos_app Package Manifest (v1.0.0+9)`?**
  _Edge tagged AMBIGUOUS (relation: references) - confidence is low._
- **What is the exact relationship between `Responsive Desktop POS Layout Rule` and `Platform Requirements (Android API 21+, iOS 12+)`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **Why does `Return` connect `Return` to `app_database.dart`, `pos_catalog_provider.dart`, `printer_errors.dart`, `render_receipt_image.dart`, `escpos_raster.dart`, `receipt_printer.dart`, `unit_conversion.dart`, `package:flutter_riverpod/flutter_riverpod.dart`, `DataClass`, `products_provider.dart`, `calc_oracle.dart`, `money.dart`, `render_receipt.dart`, `tron_border.dart`, `receipt_pdf_service.dart`, `escpos_raster_test.dart`, `percent.dart`, `receipt_roll_pdf.dart`?**
  _High betweenness centrality (0.040) - this node is a cross-community bridge._
- **Why does `CountryDefault` connect `country_default.dart` to `onboarding_state.dart`, `country_step.dart`?**
  _High betweenness centrality (0.012) - this node is a cross-community bridge._
- **Why does `AppDatabase` connect `AppDatabase` to `app_database.dart`, `backup_repository.dart`, `order_history.dart`, `package:pos_app/core/database/app_database.dart`, `package:flutter_riverpod/flutter_riverpod.dart`, `auto_print_test.dart`, `package:pos_app/core/providers/database_provider.dart`, `most_sold_test.dart`, `receipt_tax_labels_test.dart`, `package:drift/drift.dart`, `audit_dao.dart`, `payment_screen_test.dart`, `package:flutter_test/flutter_test.dart`, `DateTime`, `package:pos_app/features/cart/presentation/providers/cart_notifier.dart`?**
  _High betweenness centrality (0.010) - this node is a cross-community bridge._