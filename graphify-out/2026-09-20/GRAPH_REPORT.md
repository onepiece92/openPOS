# Graph Report - offlinePOS  (2026-08-24)

## Corpus Check
- 134 files · ~165,719 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 3685 nodes · 5797 edges · 135 communities (134 shown, 1 thin omitted)
- Extraction: 98% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 85 edges (avg confidence: 0.87)
- Token cost: 41,012 input · 6,506 output

## Community Hubs (Navigation)
- Drift Database Core
- Drift Table Definitions
- Schema v10 Snapshot
- Schema v11 Snapshot
- Schema v13 Snapshot
- Schema v12 Snapshot
- Schema v9 Snapshot
- Schema v8 Snapshot
- Schema v4 Snapshot
- Schema v7 Snapshot
- Schema v6 Snapshot
- Hive Settings Store
- Settings Providers
- Order Transactions & Audit
- Category & Product CRUD
- Expenses Screen
- Drift Companions & Data Classes
- Backup Screen & Providers
- Shared Chips & Support Screen
- App Router & Scroll Behavior
- Inventory Screen
- POS Home Screen
- Report Data Model
- Thermal Printer Plugin
- Cart Detail & Payment Screens
- Printer Setup Screen
- Orders History Screen
- Customer Picker Sheet
- Receipt PDF Service
- Keyboard Shortcuts Screen
- Snapshot Zip Service
- Order Tax Override Tables
- Favorites & App Entrypoint
- Keyboard Dismiss & Theme Preview
- Cart Calculator & Notifier
- Categories Screen
- Stock Adjustments Schema
- Orders Table Schema
- Categories Table Schema
- DB File & Snapshot Paths
- Orders DAO
- Tax Settings & Onboarding Step
- Store Profile Providers
- Cart Line Item Widgets
- Onboarding Screen
- Products Screen
- Held Tickets Bar
- Order Detail Screen
- Products DAO
- Wizard Header & Schema Imports
- Receipt Screen
- Tables Screen
- Inventory DAO & Components
- Inventory Filter Bar
- Drift DAO Mixins
- Cart & Payment Providers
- Grid Product Tile
- Products Table Schema
- Currency & Inventory Sections
- Ticket Sequence & Cart Session
- Product List Tile
- Inventory Card
- Receipt Body Renderer
- Customer Card
- Customers Screen
- App Theme
- Design Tokens
- Held Order Model
- Dependency Audit
- Expense Category & Tax Rate Schema
- Backup Repository & CSV Export
- Customer Form
- Cart Summary Model
- POS Filter Provider
- Article Detail Screen
- Held Orders Notifier
- Cart Session & Ticket Header
- Demo Data & Auto Print
- Learn Screen
- App Root & Restart
- Dashboard Report Period
- Empty State & Avatar Widgets
- Order Summary Widget
- Receipt Text Renderer
- Dashboard Body & KPIs
- Roadmap Phases & Stack
- Loyalty Settings Section
- Money Utils & Validator
- Architecture Pillars Docs
- Cart Session Model
- Tron Border Painter
- Schema Migration Tests
- Customers Table Schema
- Cart Item Model
- ESC/POS Byte Renderer
- Money & Calculator Tests
- Offline-First Constraints
- Table Selector
- Discount Sheet
- Snapshot Service Tests
- Expenses DAO
- Expenses Table Schema
- Order Items Table Schema
- App Routes
- Async Feedback & Sheets
- Audit Log Screen
- Receipt Printer Abstraction
- Backup Section & Side Nav
- Cart Screen & Favorites
- Currency Formatter
- Tables Provider
- Riverpod & Lint Conventions
- Feature-First Architecture Docs
- Versioned Schema Databases
- App Root & Picker Sheets
- Customers DAO
- Audit Log Table Schema
- Country Default Model
- Onboarding Notifier
- Fonts & Export Stack Docs
- Tax DAO
- Audit Service Events
- Onboarding State
- Tables DAO
- Codegen & Lint Config Docs
- Country Repository
- Audit DAO
- Customers Provider
- Printer Dependency Conflict
- Open POS Brand Logo
- Tax Calculator
- Order Number Formatting
- Demo Data Empty State
- Void Order
- Currency List

## God Nodes (most connected - your core abstractions)
1. `databaseProvider` - 34 edges
2. `cartSessionProvider` - 26 edges
3. `AppDatabase` - 22 edges
4. `currencyFormatterProvider` - 20 edges
5. `DataClass` - 19 edges
6. `settingsProvider` - 19 edges
7. `cartProvider` - 18 edges
8. `Offline-First Non-Negotiable Constraint` - 14 edges
9. `_PaymentScreenState` - 14 edges
10. `Dependency Audit (2026-04-22)` - 13 edges

## Surprising Connections (you probably didn't know these)
- `ROADMAP Phase 1 — Core Foundation & Shared Logic` --semantically_similar_to--> `v1 Phase 0 — Foundation (no UI)`  [INFERRED] [semantically similar]
  ROADMAP.md → v1_roadmap.md
- `ROADMAP Phase 4 — POS Interface (Main Flow)` --semantically_similar_to--> `v1 Phase 3 — Core Sales Loop`  [INFERRED] [semantically similar]
  ROADMAP.md → v1_roadmap.md
- `riverpod_generator Omitted` --semantically_similar_to--> `Hand-written Providers, No Riverpod Codegen`  [INFERRED] [semantically similar]
  pubspec.yaml → .planning/codebase/DEPENDENCIES.md
- `Offline-First Non-Negotiable Constraint` --semantically_similar_to--> `Offline Reliability + Hardware Integration Focus`  [INFERRED] [semantically similar]
  CLAUDE.md → .planning/codebase/DEPENDENCIES.md
- `flutter_launcher_icons Config (android/ios/web)` --conceptually_related_to--> `Offline-First Non-Negotiable Constraint`  [AMBIGUOUS]
  pubspec.yaml → CLAUDE.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Offline-First Enforcement Surface** — claude_offline_first_constraint, claude_no_outbound_network_calls, claude_banned_packages, claude_network_permission_ban, claude_deleted_sync_scaffolding, pubspec_jetbrainsmono_font_bundle [EXTRACTED 1.00]
- **Drift Schema Migration Workflow** — claude_database_schema_change_procedure, claude_app_database_current_schema_version, claude_migration_test, claude_migrator_based_migration, _planning_codebase_dependencies_drift_dev, _planning_codebase_dependencies_build_runner, _planning_codebase_dependencies_drift [EXTRACTED 1.00]
- **Receipt Output Stack (thermal + ESC/POS + PDF)** — _planning_codebase_dependencies_flutter_thermal_printer, _planning_codebase_dependencies_esc_pos_utils_plus, _planning_codebase_dependencies_pdf_printing_stack [EXTRACTED 1.00]
- **Offline-First Enforcement Regime** — claude_offline_first_constraint, claude_banned_packages, claude_network_permission_lockdown, claude_deleted_sync_scaffolding, claude_url_launcher_exception, _planning_codebase_integrations_no_external_apis, project_core_mission [EXTRACTED 1.00]
- **End-to-End Tax Calculation Flow** — v1_roadmap_tax_engine, v1_roadmap_phase_2_product_inventory_core, v1_roadmap_phase_3_core_sales_loop, v1_roadmap_phase_4_receipts_hardware, v1_roadmap_phase_6_expenses_reports, v1_roadmap_drift_schema_v1 [EXTRACTED 1.00]
- **Open POS Brand Identity System** — assets_images_logo_open_pos_brand_logo, assets_images_logo_open_pos_wordmark, assets_images_logo_circular_arrow_mark, assets_images_logo_green_blue_gradient_palette [INFERRED 0.85]
- **Riverpod State & DI Layer Contract** — _planning_codebase_architecture_state_management_riverpod, _planning_codebase_conventions_provider_naming, v1_roadmap_riverpod_decision_table, v1_roadmap_provider_hierarchy, v1_roadmap_cart_notifier, project_riverpod_sole_di, pubspec_riverpod_generator_omitted [INFERRED 0.85]

## Communities (135 total, 1 thin omitted)

### Community 0 - "Drift Database Core"
Cohesion: 0.01
Nodes (252): AuditDao, class OrderTaxOverride extends, class ProductComponent extends, ColumnFilters, ColumnOrderings, CustomersDao, ExpensesDao, InventoryDao (+244 more)

### Community 1 - "Drift Table Definitions"
Cohesion: 0.03
Nodes (157): Table, TableInfo, AuditLog, Categories, Customers, ExpenseCategories, Expenses, OrderItems (+149 more)

### Community 2 - "Schema v10 Snapshot"
Cohesion: 0.02
Nodes (119): GeneratedColumn, action, actualTableName, address, _alias, aliasedName, allSchemaEntities, allTables (+111 more)

### Community 3 - "Schema v11 Snapshot"
Cohesion: 0.02
Nodes (101): Categories, action, actualTableName, address, _alias, aliasedName, allSchemaEntities, allTables (+93 more)

### Community 4 - "Schema v13 Snapshot"
Cohesion: 0.02
Nodes (101): Index, OrderTaxOverrides, action, actualTableName, address, _alias, aliasedName, allSchemaEntities (+93 more)

### Community 5 - "Schema v12 Snapshot"
Cohesion: 0.02
Nodes (99): Expenses, Returns, action, actualTableName, address, _alias, aliasedName, allSchemaEntities (+91 more)

### Community 6 - "Schema v9 Snapshot"
Cohesion: 0.02
Nodes (95): OrderTaxes, action, actualTableName, address, _alias, aliasedName, allSchemaEntities, allTables (+87 more)

### Community 7 - "Schema v8 Snapshot"
Cohesion: 0.02
Nodes (93): Customers, Iterable, TaxGroupMembers, action, actualTableName, address, _alias, aliasedName (+85 more)

### Community 8 - "Schema v4 Snapshot"
Cohesion: 0.02
Nodes (92): Products, ProductTaxes, StockAdjustments, TaxGroups, action, actualTableName, address, _alias (+84 more)

### Community 9 - "Schema v7 Snapshot"
Cohesion: 0.02
Nodes (91): OrderItems, ProductModifiers, ProductVariants, Tables, action, actualTableName, address, _alias (+83 more)

### Community 10 - "Schema v6 Snapshot"
Cohesion: 0.02
Nodes (90): AuditLog, ExpenseCategories, Orders, ProductComponents, TaxRates, action, actualTableName, address (+82 more)

### Community 11 - "Hive Settings Store"
Cohesion: 0.03
Nodes (69): autoBackupEnabled, autoBackupLastAt, _box, build, businessAddress, businessName, businessNameOrDefault, businessPan (+61 more)

### Community 12 - "Settings Providers"
Cohesion: 0.05
Nodes (51): @immutable, ConsumerWidget, int?, AppSettings, defaultTaxIdProvider, settingsBoxProvider, SettingsNotifier, settingsProvider (+43 more)

### Community 13 - "Order Transactions & Audit"
Cohesion: 0.06
Nodes (43): AuditService, invoicePrefix, placeOrder, transaction, processReturn, transaction, package:pos_app/core/services/audit_service.dart, package:pos_app/features/cart/data/place_order.dart (+35 more)

### Community 14 - "Category & Product CRUD"
Cohesion: 0.04
Nodes (49): databaseProvider, _save, _delete, _save, _showAddCategoryDialog, categoriesStreamProvider, CategoriesScreen, build (+41 more)

### Community 15 - "Expenses Screen"
Cohesion: 0.06
Nodes (42): ConsumerStatefulWidget, _amountCtrl, build, categories, category, _categoryId, color, createState (+34 more)

### Community 16 - "Drift Companions & Data Classes"
Cohesion: 0.08
Nodes (42): Insertable, initials, name, OrderNumberX, UpdateCompanion, AuditLogCompanion, AuditLogData, CategoriesCompanion (+34 more)

### Community 17 - "Backup Screen & Providers"
Cohesion: 0.06
Nodes (36): backupRepositoryProvider, autoBackupEnabledProvider, autoBackupLastAtProvider, snapshotCoordinatorProvider, _AutoBackupTile, BackupScreen, _BackupScreenState, _BackupTile (+28 more)

### Community 18 - "Shared Chips & Support Screen"
Cohesion: 0.06
Nodes (35): _CategoryRow, _PosProductList, _CategoryChips, _Chip, _ExpenseTile, _TotalBar, build, cs (+27 more)

### Community 19 - "App Router & Scroll Behavior"
Cohesion: 0.06
Nodes (35): ChangeNotifier, GoRouter, AppScrollBehavior, getKeyboardDismissBehavior, ping, refresh, _RouterRefresh, _slide (+27 more)

### Community 20 - "Inventory Screen"
Cohesion: 0.06
Nodes (33): build, createState, dispose, _filter, _filtered, InventoryScreen, _InventoryScreenState, _search (+25 more)

### Community 21 - "POS Home Screen"
Cohesion: 0.06
Nodes (33): _applyFilter, cart, categories, _Chip, createState, dispose, favorites, favoritesOnly (+25 more)

### Community 22 - "Report Data Model"
Cohesion: 0.06
Nodes (30): avgOrder, chartDates, chartHighlightIndex, chartTitle, chartTotals, count, days, db (+22 more)

### Community 23 - "Thermal Printer Plugin"
Cohesion: 0.07
Nodes (28): devices, _ftp, printBytes, startScan, stopScan, ThermalPluginPrinter, ReceiptPrinter, Object? (+20 more)

### Community 24 - "Cart Detail & Payment Screens"
Cohesion: 0.07
Nodes (26): dart:ui, createState, customer, dispose, fmt, icon, label, _loyaltyCtrl (+18 more)

### Community 25 - "Printer Setup Screen"
Cohesion: 0.10
Nodes (27): printerDeviceAddressProvider, printerDeviceNameProvider, printerPaperWidthProvider, build, createState, _devices, _devicesSub, _disconnectSavedPrinter (+19 more)

### Community 26 - "Orders History Screen"
Cohesion: 0.08
Nodes (28): build, createState, cs, customerName, _filter, fmt, _groupByDate, icon (+20 more)

### Community 27 - "Customer Picker Sheet"
Cohesion: 0.07
Nodes (25): CountryDefault?, CartNotifier, clearItems, selectedTaxRatesProvider, build, createState, customers, onSelect (+17 more)

### Community 28 - "Receipt PDF Service"
Cohesion: 0.07
Nodes (27): baseStyle, billRow, boldStyle, buildReceiptPdf, bytes, customerName, data, _dataCell (+19 more)

### Community 29 - "Keyboard Shortcuts Screen"
Cohesion: 0.08
Nodes (24): ColorScheme, build, cs, key_, _KeyChip, keys, label, _SectionHeader (+16 more)

### Community 30 - "Snapshot Zip Service"
Cohesion: 0.07
Nodes (26): File, create, createdAt, dbBytes, dbEntryName, _decode, fileNameFor, filePrefix (+18 more)

### Community 31 - "Order Tax Override Tables"
Cohesion: 0.08
Nodes (24): createdAt, id, orderId, OrderTaxOverrides, originalTax, overrideTax, reason, id (+16 more)

### Community 32 - "Favorites & App Entrypoint"
Cohesion: 0.09
Nodes (22): Box, dart:io, Directory, _box, favoritesProvider, _kFavoriteProductIds, toggle, initFlutter (+14 more)

### Community 33 - "Keyboard Dismiss & Theme Preview"
Cohesion: 0.09
Nodes (20): EditableText, build, SettingsSectionHeader, title, build, ThemePreviewScreen, build, child (+12 more)

### Community 34 - "Cart Calculator & Notifier"
Cohesion: 0.08
Nodes (25): _, CartCalculator, compute, _roundingModeFor, add, addItem, addProduct, addProductInSecondaryUnit (+17 more)

### Community 35 - "Categories Screen"
Cohesion: 0.08
Nodes (24): productsByCategoryProvider, build, category, _CategoryCard, _colorFor, _confirmDelete, onDelete, onEdit (+16 more)

### Community 36 - "Stock Adjustments Schema"
Cohesion: 0.09
Nodes (22): @DataClassName, DateTimeColumn get, createdAt, delta, id, notes, productId, reasonCode (+14 more)

### Community 37 - "Orders Table Schema"
Cohesion: 0.08
Nodes (24): @TableIndex, changeAmount, createdAt, customerId, discountIsPercent, discountTotal, discountValue, id (+16 more)

### Community 38 - "Categories Table Schema"
Cohesion: 0.09
Nodes (22): IntColumn get, Categories, createdAt, id, name, parentId, sortOrder, taxRateId (+14 more)

### Community 39 - "DB File & Snapshot Paths"
Cohesion: 0.09
Nodes (22): dart:isolate, databaseFile, dir, kDatabaseFileName, openConnection, autoBackupDir, create, createAndShare (+14 more)

### Community 40 - "Orders DAO"
Cohesion: 0.08
Nodes (23): getAllOrdersWithItems, getById, getItems, getTaxBreakdown, incrementPrintCount, insertItems, insertOrder, insertReturn (+15 more)

### Community 41 - "Tax Settings & Onboarding Step"
Cohesion: 0.09
Nodes (22): build, currencySymbol, nameController, rateController, TaxStep, createState, dispose, existing (+14 more)

### Community 42 - "Store Profile Providers"
Cohesion: 0.13
Nodes (22): class, businessAddressProvider, businessNameProvider, businessPanProvider, businessPhoneProvider, businessTaglineProvider, _addressCtrl, build (+14 more)

### Community 43 - "Cart Line Item Widgets"
Cohesion: 0.09
Nodes (20): IconData, CartItem, fmt, icon, item, onPressed, _QtyButton, build (+12 more)

### Community 44 - "Onboarding Screen"
Cohesion: 0.09
Nodes (22): _businessNameCtrl, _canProceed, _countries, createState, dispose, _filterCountries, _filtered, _loadingCountries (+14 more)

### Community 45 - "Products Screen"
Cohesion: 0.09
Nodes (22): _applyFilter, categories, _CategoryChips, categoryName, _Chip, createState, cs, dispose (+14 more)

### Community 46 - "Held Tickets Bar"
Cohesion: 0.13
Nodes (21): AnimationController, activeHeldOrdersProvider, archivedHeldOrdersProvider, heldOrdersProvider, build, _buildActiveList, _buildArchivedList, createState (+13 more)

### Community 47 - "Order Detail Screen"
Cohesion: 0.10
Nodes (21): auditServiceProvider, businessName, customer, data, db, _DetailBody, _DetailData, fmt (+13 more)

### Community 48 - "Products DAO"
Cohesion: 0.09
Nodes (21): adjustStock, deductStock, deleteCategory, getAllCategories, getById, getBySku, getComponents, replaceComponents (+13 more)

### Community 49 - "Wizard Header & Schema Imports"
Cohesion: 0.09
Nodes (20): build, _labels, onSkip, step, WizardHeader, package:drift/internal/migrations.dart, schema_v10.dart, schema_v11.dart (+12 more)

### Community 50 - "Receipt Screen"
Cohesion: 0.10
Nodes (21): ReceiptBodyData, build, businessName, customer, data, db, fmt, _handle (+13 more)

### Community 51 - "Tables Screen"
Cohesion: 0.10
Nodes (21): _assignToCart, _capacityCtrl, createState, dispose, existing, initState, isCurrentCartTable, isOccupied (+13 more)

### Community 52 - "Inventory DAO & Components"
Cohesion: 0.10
Nodes (17): openConnection, getAdjustmentsForProduct, logAdjustment, watchLowStock, componentProductId, compositeProductId, id, ProductComponents (+9 more)

### Community 53 - "Inventory Filter Bar"
Cohesion: 0.10
Nodes (19): build, _Chip, color, InventoryFilterBar, label, lowCount, onSelect, onTap (+11 more)

### Community 54 - "Drift DAO Mixins"
Cohesion: 0.17
Nodes (20): @DriftAccessor, @DriftDatabase, _$AuditDaoMixin, _$CustomersDaoMixin, DatabaseAccessor, _$ExpensesDaoMixin, _$InventoryDaoMixin, AppDatabase (+12 more)

### Community 55 - "Cart & Payment Providers"
Cohesion: 0.16
Nodes (20): cartCustomerProvider, invoicePrefixProvider, build, CartDetailScreen, build, initState, _PaymentActionBar, PaymentScreen (+12 more)

### Community 56 - "Grid Product Tile"
Cohesion: 0.10
Nodes (18): CurrencyFormatter, build, fmt, GridProductTile, isFavorite, onDecrement, onIncrement, onLongPress (+10 more)

### Community 57 - "Products Table Schema"
Cohesion: 0.10
Nodes (19): categoryId, conversionRate, createdAt, id, imagePath, isActive, isComposite, isHiddenInPos (+11 more)

### Community 58 - "Currency & Inventory Sections"
Cohesion: 0.12
Nodes (18): currencyCodeProvider, currencySymbolProvider, lowStockThresholdProvider, build, CurrencySection, current, _showCurrencyPicker, build (+10 more)

### Community 59 - "Ticket Sequence & Cart Session"
Cohesion: 0.11
Nodes (18): _box, formatTicketNumber, kTicketSeqKey, next, TicketSequence, ticketSequenceProvider, CartSession, CartSessionNotifier (+10 more)

### Community 60 - "Product List Tile"
Cohesion: 0.10
Nodes (19): bg, build, color, cs, fmt, icon, isFavorite, onDecrement (+11 more)

### Community 61 - "Inventory Card"
Cohesion: 0.10
Nodes (19): _apply, badgeColor, build, canDecrement, canIncrement, cs, _decrement, icon (+11 more)

### Community 62 - "Receipt Body Renderer"
Cohesion: 0.10
Nodes (19): _BillRow, build, businessName, customer, data, _DataCell, fmt, _HeaderCell (+11 more)

### Community 63 - "Customer Card"
Cohesion: 0.11
Nodes (17): Color, _Badge, bg, build, customer, CustomerCard, fg, icon (+9 more)

### Community 64 - "Customers Screen"
Cohesion: 0.12
Nodes (18): ConsumerState, IconData get, createState, CustomersScreen, _CustomersScreenState, dispose, _filterAndSort, icon (+10 more)

### Community 65 - "App Theme"
Cohesion: 0.11
Nodes (18): AppTheme, backgroundGradient, _build, ctaButtonStyle, dark, _darkGrad, _darkScheme, _fontFamily (+10 more)

### Community 66 - "Design Tokens"
Cohesion: 0.11
Nodes (18): AppFonts, AppOpacity, heavy, lg, md, medium, mono, Radii (+10 more)

### Community 67 - "Held Order Model"
Cohesion: 0.11
Nodes (18): archivedAt, copyWith, createdAt, customerId, customerName, fromJson, id, isArchived (+10 more)

### Community 68 - "Dependency Audit"
Cohesion: 0.18
Nodes (18): build_runner (Generator CLI), Dependency Audit (2026-04-22), drift (SQLite Relational Storage), drift_dev (Database Layer Codegen), esc_pos_utils_plus (ESC/POS Encoding), flutter_riverpod (State Management), flutter_thermal_printer (POS Hardware), hive / hive_flutter (KV Storage) (+10 more)

### Community 69 - "Expense Category & Tax Rate Schema"
Cohesion: 0.11
Nodes (16): BoolColumn get, color, ExpenseCategories, id, isDefault, name, createdAt, id (+8 more)

### Community 70 - "Backup Repository & CSV Export"
Cohesion: 0.13
Nodes (17): DateTime, BackupRepository, backupRepositoryProvider, db, exportCustomers, exportExpenses, exportOrders, exportProducts (+9 more)

### Community 71 - "Customer Form"
Cohesion: 0.12
Nodes (17): FormState, _addressCtrl, build, createState, customer, CustomerForm, _CustomerFormState, _delete (+9 more)

### Community 72 - "Cart Summary Model"
Cohesion: 0.11
Nodes (17): amount, CartSummary, isInclusive, loyaltyDiscount, name, orderDiscount, pointsToEarn, rate (+9 more)

### Community 73 - "POS Filter Provider"
Cohesion: 0.12
Nodes (17): clearSearch, copyWith, favoritesOnly, isGrid, PosFilterNotifier, posFilterProvider, PosFilterState, PosSortMode (+9 more)

### Community 74 - "Article Detail Screen"
Cohesion: 0.11
Nodes (17): ArticleDetailScreen, ArticleSection, build, category, cs, heading, icon, readTime (+9 more)

### Community 75 - "Held Orders Notifier"
Cohesion: 0.12
Nodes (16): cartCustomerNameProvider, heldOrdersBoxProvider, HeldOrder, archive, archiveAll, _box, build, delete (+8 more)

### Community 76 - "Cart Session & Ticket Header"
Cohesion: 0.15
Nodes (16): customersStreamProvider, cartSessionProvider, clear, _loadTicket, build, OrderSummary, _showDiscountSheet, build (+8 more)

### Community 77 - "Demo Data & Auto Print"
Cohesion: 0.13
Nodes (14): auditServiceProvider, _db, DemoDataService, seed, _settings, autoPrintOrder, AutoPrintService, autoPrintServiceProvider (+6 more)

### Community 78 - "Learn Screen"
Cohesion: 0.12
Nodes (16): _Article, _ArticleCard, _articles, build, category, cs, description, icon (+8 more)

### Community 79 - "App Root & Restart"
Cohesion: 0.12
Nodes (15): dart:async, build, child, _container, createState, dispose, initState, message (+7 more)

### Community 80 - "Dashboard Report Period"
Cohesion: 0.14
Nodes (15): DateTimeRange?, ReportPeriod, ReportPeriodX, reportProvider, build, createState, _customRange, DashboardScreen (+7 more)

### Community 81 - "Empty State & Avatar Widgets"
Cohesion: 0.12
Nodes (14): double?, action, AppEmptyState, build, icon, subtitle, title, build (+6 more)

### Community 82 - "Order Summary Widget"
Cohesion: 0.12
Nodes (15): addColor, cs, fmt, label, onTap, ref, _showTaxPicker, summary (+7 more)

### Community 83 - "Receipt Text Renderer"
Cohesion: 0.13
Nodes (14): buildReceiptText, dateFmt, join, lines, o, package:pos_app/core/utils/currency_formatter.dart, package:pos_app/features/receipts/presentation/receipt_body.dart, fmt (+6 more)

### Community 84 - "Dashboard Body & KPIs"
Cohesion: 0.12
Nodes (15): ReportData, build, _buildKpiRows, cs, DashboardBody, data, _fmt, isCustomRange (+7 more)

### Community 85 - "Roadmap Phases & Stack"
Cohesion: 0.17
Nodes (15): Technology Stack (Dart 3.5+, Flutter 3.24+), pos_app Package Manifest (v1.0.0+9), ROADMAP Phase 1 — Core Foundation & Shared Logic, ROADMAP Phase 3 — Product Management (The Catalog), ROADMAP Phase 4 — POS Interface (Main Flow), Append-Only Audit Log, Connectivity Detection task (0.5, connectivity_plus), Drift Schema — Full v1 Table List (+7 more)

### Community 86 - "Loyalty Settings Section"
Cohesion: 0.17
Nodes (14): loyaltyEarnRateProvider, loyaltyEnabledProvider, loyaltyPointValueProvider, build, createState, dispose, _earnCtrl, earnRate (+6 more)

### Community 87 - "Money Utils & Validator"
Cohesion: 0.13
Nodes (14): allowZero, eps, isRequired, kMaxMoneyAmount, kMaxMoneyAmountLabel, noun, nudged, null (+6 more)

### Community 88 - "Architecture Pillars Docs"
Cohesion: 0.18
Nodes (14): Dual Data Layer (Drift + Hive), Navigation Pillar (GoRouter routerProvider), Drift Layout Convention (tables, daos, AppDatabase migrations), Responsive Desktop POS Layout Rule, No Hardcoded Colors (AppTheme / colorScheme), Local Auth (no external identity provider), Platform Requirements (Android API 21+, iOS 12+), Premium Glassmorphic Dark Aesthetic (+6 more)

### Community 89 - "Cart Session Model"
Cohesion: 0.14
Nodes (13): bool get, copyWith, customerId, fresh, heldTicketId, isEditingHeldTicket, loyaltyPointsToRedeem, openedAt (+5 more)

### Community 90 - "Tron Border Painter"
Cohesion: 0.14
Nodes (13): CustomPainter, dart:math, color, e, extractWrappedPath, f, len, p (+5 more)

### Community 91 - "Schema Migration Tests"
Cohesion: 0.15
Nodes (11): generated/schema.dart, db, package:drift_dev/api/migrations_common.dart, package:drift_dev/api/migrations_native.dart, package:drift/native.dart, package:pos_app/core/database/app_database.dart, SchemaVerifier, main (+3 more)

### Community 92 - "Customers Table Schema"
Cohesion: 0.14
Nodes (13): address, createdAt, Customers, defaultDiscount, defaultDiscountIsPercent, email, id, isTaxExempt (+5 more)

### Community 93 - "Cart Item Model"
Cohesion: 0.14
Nodes (13): copyWith, isSecondaryUnit, isTaxable, lineDiscount, lineSubtotal, mainUnitQty, name, productId (+5 more)

### Community 94 - "ESC/POS Byte Renderer"
Cohesion: 0.14
Nodes (13): bytes, customerName, g, isCopy, _kv, method, methodLabel, profile (+5 more)

### Community 95 - "Money & Calculator Tests"
Cohesion: 0.15
Nodes (11): package:flutter_test/flutter_test.dart, package:pos_app/core/utils/money.dart, package:pos_app/features/cart/domain/cart_calculator.dart, main, main, item, main, money (+3 more)

### Community 96 - "Offline-First Constraints"
Cohesion: 0.19
Nodes (13): Zero External APIs / Services, Deleted Sync / Cloud-Backup Scaffolding, Graphify Knowledge Graph Workflow Rule, Sandbox-Blocked Release Binary (no INTERNET / network entitlements), Platform Network Permission Lockdown, No Outbound Network Calls Rule, Offline-First Non-Negotiable Constraint, url_launcher Network-Adjacent Exception (+5 more)

### Community 97 - "Table Selector"
Cohesion: 0.19
Nodes (12): cartTableProvider, build, occupied, onSelect, _pickTable, selectedId, session, _TablePickerSheet (+4 more)

### Community 98 - "Discount Sheet"
Cohesion: 0.17
Nodes (12): double get, build, createState, _ctrl, currentDiscount, DiscountSheet, _DiscountSheetState, dispose (+4 more)

### Community 99 - "Snapshot Service Tests"
Cohesion: 0.15
Nodes (12): Exception, SnapshotFormatException, package:pos_app/features/backup/data/snapshot_service.dart, dbFileIn, hivePathIn, live, main, openDb (+4 more)

### Community 100 - "Expenses DAO"
Cohesion: 0.15
Nodes (12): getAll, getAllCategories, insert, insertCategory, totalForPeriod, updateExpense, upsertCategory, watchAll (+4 more)

### Community 101 - "Expenses Table Schema"
Cohesion: 0.15
Nodes (12): amount, categoryId, createdAt, date, Expenses, id, isRecurring, isTaxDeductible (+4 more)

### Community 102 - "Order Items Table Schema"
Cohesion: 0.15
Nodes (12): discount, id, lineTotal, orderId, OrderItems, productId, productName, quantity (+4 more)

### Community 103 - "App Routes"
Cohesion: 0.18
Nodes (12): build, POSApp, routerProvider, build, Route /customers, Route /expenses, Route /help/shortcuts, Route /inventory (+4 more)

### Community 104 - "Async Feedback & Sheets"
Cohesion: 0.17
Nodes (10): cs, failurePrefix, messenger, draggable, initialSize, minSize, package:pos_app/shared/widgets/keyboard_safe.dart, required WidgetBuilder builder,
  bool (+2 more)

### Community 105 - "Audit Log Screen"
Cohesion: 0.20
Nodes (11): action, _ActionChip, _actionColor, _actionIcon, AuditLogScreen, _auditLogsProvider, build, color (+3 more)

### Community 106 - "Receipt Printer Abstraction"
Cohesion: 0.17
Nodes (11): address, devices, DiscoveredPrinter, name, printBytes, PrinterTransport, receiptPrinterProvider, startScan (+3 more)

### Community 107 - "Backup Section & Side Nav"
Cohesion: 0.17
Nodes (10): BackupSection, build, build, i, _indexFor, _label, PosDrawer, _routes (+2 more)

### Community 108 - "Cart Screen & Favorites"
Cohesion: 0.22
Nodes (11): favoritesProvider, build, CartScreen, _CartScreenState, initState, productSalesCountProvider, build, posFilterProvider (+3 more)

### Community 109 - "Currency Formatter"
Cohesion: 0.18
Nodes (10): CurrencyFormatter, decimalDigits, _fmt, format, formatPlain, locale, symbol, tryParse (+2 more)

### Community 110 - "Tables Provider"
Cohesion: 0.22
Nodes (10): activeHeld, cartTableId, cartTableProvider, occupiedTableIdsProvider, tableId, tables, tablesStreamProvider, watch (+2 more)

### Community 111 - "Riverpod & Lint Conventions"
Cohesion: 0.24
Nodes (10): Data Flow (UI to Notifier to DAO to Stream), State Management Pillar (Riverpod), Package-Imports-Only Rule, Provider Suffix Naming Convention, No Error Tracking, Analytics, or CI Pipeline, Enforced Lint Rules (analysis_options), Riverpod as Sole DI Mechanism, Testing Practice (unit for domain, widget for shared) (+2 more)

### Community 112 - "Feature-First Architecture Docs"
Cohesion: 0.20
Nodes (10): lib/ Directory Structure (core, features, shared), Feature-First Layered Architecture, Presentation-Domain-Data Feature Pattern, drift as Critical Persistence Dependency, graphify Knowledge Graph Workflow, Core Mission (100% offline POS), Guiding Principles (offline-first, hardware, feature-first, premium), Offline-First Flutter POS (project charter) (+2 more)

### Community 113 - "Versioned Schema Databases"
Cohesion: 0.20
Nodes (10): GeneratedDatabase, DatabaseAtV10, DatabaseAtV11, DatabaseAtV12, DatabaseAtV13, DatabaseAtV4, DatabaseAtV6, DatabaseAtV7 (+2 more)

### Community 114 - "App Root & Picker Sheets"
Cohesion: 0.27
Nodes (10): AppRoot, AppRootState, _NoticeOverlay, _NoticeOverlayState, CustomerPickerSheet, _CustomerPickerSheetState, _ComponentPickerSheet, _ComponentPickerSheetState (+2 more)

### Community 115 - "Customers DAO"
Cohesion: 0.20
Nodes (9): addLoyaltyPoints, getAll, getById, redeemLoyaltyPoints, search, upsert, watchAll, package:pos_app/core/database/tables/customers_table.dart (+1 more)

### Community 116 - "Audit Log Table Schema"
Cohesion: 0.20
Nodes (9): action, AuditLog, createdAt, entityId, entityType, id, metadata, newValue (+1 more)

### Community 117 - "Country Default Model"
Cohesion: 0.20
Nodes (9): code, CountryDefault, currency, fromJson, name, symbol, taxName, taxRate (+1 more)

### Community 118 - "Onboarding Notifier"
Cohesion: 0.22
Nodes (10): onboardingNotifierProvider, _back, build, _finish, initState, _loadCountries, _next, _selectCountry (+2 more)

### Community 119 - "Fonts & Export Stack Docs"
Cohesion: 0.28
Nodes (9): Bundled Fonts Policy (google_fonts banned), google_fonts listed as Utility dependency, Local-Only Data Storage (Drift file + Hive + path_provider), Banned Runtime-Fetching Packages, Export & Sharing Stack (share_plus, csv, file_picker, permission_handler), Bundled JetBrainsMono Font Family, ROADMAP Phase 6 — Order History & Local Reporting, v1 Phase 5 — Backup & Data Safety (local-only) (+1 more)

### Community 120 - "Tax DAO"
Cohesion: 0.22
Nodes (8): getAll, getById, getRatesForProduct, setProductTaxes, upsertRate, watchActive, package:pos_app/core/database/tables/product_taxes_table.dart, _

### Community 121 - "Audit Service Events"
Cohesion: 0.22
Nodes (8): AuditService, _db, log, orderPlaced, orderRefunded, orderVoided, settingChanged, taxOverridden

### Community 122 - "Onboarding State"
Cohesion: 0.22
Nodes (8): businessName, copyWith, country, OnboardingState, saving, step, taxName, taxRate

### Community 123 - "Tables DAO"
Cohesion: 0.25
Nodes (7): deleteById, getAll, getById, upsert, watchAll, package:pos_app/core/database/tables/tables_table.dart, _

### Community 124 - "Codegen & Lint Config Docs"
Cohesion: 0.29
Nodes (7): build_runner Code Generation Workflow, Code Generation Dev Dependencies (riverpod_generator, drift_dev, build_runner), build.yaml Code Generation Config, custom_lint Analyzer Plugin (enabled in analysis_options), Generated-File Exclusion (*.g.dart, *.freezed.dart), custom_lint / riverpod_lint Commented Out, riverpod_generator Omitted

### Community 125 - "Country Repository"
Cohesion: 0.29
Nodes (6): dart:convert, _cache, CountryRepository, load, package:pos_app/features/onboarding/domain/country_default.dart, static List

### Community 126 - "Audit DAO"
Cohesion: 0.29
Nodes (6): log, queryByDateRange, queryByEntity, watchRecent, package:pos_app/core/database/tables/audit_log_table.dart, _

### Community 127 - "Customers Provider"
Cohesion: 0.29
Nodes (6): cartCustomerNameProvider, cartCustomerProvider, customerId, customers, customersStreamProvider, watch

### Community 128 - "Printer Dependency Conflict"
Cohesion: 0.47
Nodes (6): Hardware Integration Pillar (ESC/POS + PDF), PrintingService Abstraction, heathen_printer_plus (documented printer package), flutter_thermal_printer dependency, ROADMAP Phase 5 — Hardware Deep Integration, v1 Phase 4 — Receipts & Hardware

### Community 129 - "Open POS Brand Logo"
Cohesion: 0.53
Nodes (6): Interlocking Circular Arrow Mark, Green-to-Blue Gradient Brand Palette, Open POS Brand Logo, OPEN POS Wordmark, Point-of-Sale Product Identity, Transaction Cycle Visual Metaphor

### Community 130 - "Tax Calculator"
Cohesion: 0.40
Nodes (6): _, compoundTax, lineItemTax, priceBeforeTax, _round, TaxCalculator

### Community 131 - "Order Number Formatting"
Cohesion: 0.40
Nodes (4): int get, billNo, displayNo, String get

### Community 132 - "Demo Data Empty State"
Cohesion: 0.50
Nodes (4): demoDataServiceProvider, _EmptyProductsState, _EmptyProductsStateState, _loadDemo

### Community 133 - "Void Order"
Cohesion: 0.50
Nodes (3): transaction, voidOrder, package:pos_app/features/orders/domain/order_number.dart

## Ambiguous Edges - Review These
- `v1 Phase 3 — Core Sales Loop` → `pos_app Package Manifest (v1.0.0+9)`  [AMBIGUOUS]
  v1_roadmap.md · relation: references
- `v1 Phase 7 — Customers, Loyalty & Audit` → `pos_app Package Manifest (v1.0.0+9)`  [AMBIGUOUS]
  v1_roadmap.md · relation: references
- `Offline-First Non-Negotiable Constraint` → `flutter_launcher_icons Config (android/ios/web)`  [AMBIGUOUS]
  pubspec.yaml · relation: conceptually_related_to
- `Responsive Desktop POS Layout Rule` → `Platform Requirements (Android API 21+, iOS 12+)`  [AMBIGUOUS]
  .planning/codebase/CONVENTIONS.md · relation: conceptually_related_to

## Knowledge Gaps
- **2471 isolated node(s):** `action`, `_actionColor`, `_actionIcon`, `color`, `_entityLabel` (+2466 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **1 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `v1 Phase 3 — Core Sales Loop` and `pos_app Package Manifest (v1.0.0+9)`?**
  _Edge tagged AMBIGUOUS (relation: references) - confidence is low._
- **What is the exact relationship between `v1 Phase 7 — Customers, Loyalty & Audit` and `pos_app Package Manifest (v1.0.0+9)`?**
  _Edge tagged AMBIGUOUS (relation: references) - confidence is low._
- **What is the exact relationship between `Offline-First Non-Negotiable Constraint` and `flutter_launcher_icons Config (android/ios/web)`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **What is the exact relationship between `Responsive Desktop POS Layout Rule` and `Platform Requirements (Android API 21+, iOS 12+)`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **Why does `AppDatabase` connect `Drift DAO Mixins` to `Drift Database Core`, `Backup Repository & CSV Export`, `Demo Data & Auto Print`, `Order Transactions & Audit`, `Inventory DAO & Components`, `Thermal Printer Plugin`, `Audit Service Events`, `Schema Migration Tests`?**
  _High betweenness centrality (0.013) - this node is a cross-community bridge._
- **Why does `OrdersDao` connect `Drift DAO Mixins` to `Drift Database Core`, `Orders DAO`, `Backup Repository & CSV Export`?**
  _High betweenness centrality (0.011) - this node is a cross-community bridge._
- **Why does `Return` connect `Drift Companions & Data Classes` to `Drift Database Core`, `Inventory Screen`, `Money Utils & Validator`, `Tron Border Painter`, `Schema Migration Tests`, `Receipt PDF Service`, `ESC/POS Byte Renderer`?**
  _High betweenness centrality (0.010) - this node is a cross-community bridge._