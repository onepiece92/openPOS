# Graph Report - lib  (2026-04-22)

## Corpus Check
- 101 files · ~83,584 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 906 nodes · 1135 edges · 42 communities detected
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Services + Payment UI|Services + Payment UI]]
- [[_COMMUNITY_Drift DAOs|Drift DAOs]]
- [[_COMMUNITY_Drift Schema Tables|Drift Schema Tables]]
- [[_COMMUNITY_Drift Generated Companions|Drift Generated Companions]]
- [[_COMMUNITY_Core Providers + Widgets|Core Providers + Widgets]]
- [[_COMMUNITY_Settings Screen|Settings Screen]]
- [[_COMMUNITY_Onboarding Flow|Onboarding Flow]]
- [[_COMMUNITY_Backup Pipeline|Backup Pipeline]]
- [[_COMMUNITY_Cart Detail Sheets|Cart Detail Sheets]]
- [[_COMMUNITY_Held Orders|Held Orders]]
- [[_COMMUNITY_Help Screens|Help Screens]]
- [[_COMMUNITY_Router (app.dart)|Router (app.dart)]]
- [[_COMMUNITY_Expenses Screen|Expenses Screen]]
- [[_COMMUNITY_POS Home Screen|POS Home Screen]]
- [[_COMMUNITY_Cart State|Cart State]]
- [[_COMMUNITY_Currency + Order Detail|Currency + Order Detail]]
- [[_COMMUNITY_Theme + Receipt|Theme + Receipt]]
- [[_COMMUNITY_Audit + Sync Services|Audit + Sync Services]]
- [[_COMMUNITY_Reports Dashboard|Reports Dashboard]]
- [[_COMMUNITY_Store Profile + Side Nav|Store Profile + Side Nav]]
- [[_COMMUNITY_Customers Screen|Customers Screen]]
- [[_COMMUNITY_Country + Tax Settings|Country + Tax Settings]]
- [[_COMMUNITY_Inventory Screen|Inventory Screen]]
- [[_COMMUNITY_Orders History|Orders History]]
- [[_COMMUNITY_Product Form|Product Form]]
- [[_COMMUNITY_Products Screen|Products Screen]]
- [[_COMMUNITY_POS Filter State|POS Filter State]]
- [[_COMMUNITY_Grid Product Tile|Grid Product Tile]]
- [[_COMMUNITY_Tax Calculator|Tax Calculator]]
- [[_COMMUNITY_Print Service|Print Service]]
- [[_COMMUNITY_Onboarding State|Onboarding State]]
- [[_COMMUNITY_Cart Item Model|Cart Item Model]]
- [[_COMMUNITY_Country Default|Country Default]]
- [[_COMMUNITY_Drift Codegen Stub (orders)|Drift Codegen Stub (orders)]]
- [[_COMMUNITY_Drift Codegen Stub (tax)|Drift Codegen Stub (tax)]]
- [[_COMMUNITY_Drift Codegen Stub (customers)|Drift Codegen Stub (customers)]]
- [[_COMMUNITY_Drift Codegen Stub (audit)|Drift Codegen Stub (audit)]]
- [[_COMMUNITY_Drift Codegen Stub (sync)|Drift Codegen Stub (sync)]]
- [[_COMMUNITY_Drift Codegen Stub (products)|Drift Codegen Stub (products)]]
- [[_COMMUNITY_Drift Codegen Stub (inventory)|Drift Codegen Stub (inventory)]]
- [[_COMMUNITY_Drift Codegen Stub (expenses)|Drift Codegen Stub (expenses)]]
- [[_COMMUNITY_String Utils|String Utils]]

## God Nodes (most connected - your core abstractions)
1. `_` - 54 edges
2. `package:drift/drift.dart` - 42 edges
3. `package:flutter/material.dart` - 38 edges
4. `package:flutter_riverpod/flutter_riverpod.dart` - 37 edges
5. `package:pos_app/core/database/app_database.dart` - 24 edges
6. `package:pos_app/core/providers/database_provider.dart` - 19 edges
7. `package:pos_app/features/products/domain/products_provider.dart` - 17 edges
8. `package:go_router/go_router.dart` - 15 edges
9. `package:pos_app/features/side_nav/presentation/side_nav.dart` - 14 edges
10. `package:flutter/services.dart` - 13 edges

## Surprising Connections (you probably didn't know these)
- None detected - all connections are within the same source files.

## Communities

### Community 0 - "Services + Payment UI"
Cohesion: 0.04
Nodes (55): AuditService, ago, DemoDataService, build, ChoiceChip, Column, dispose, initState (+47 more)

### Community 1 - "Drift DAOs"
Cohesion: 0.05
Nodes (51): ../app_database.dart, connection/native.dart, daos/audit_dao.dart, daos/customers_dao.dart, daos/expenses_dao.dart, daos/inventory_dao.dart, daos/orders_dao.dart, daos/products_dao.dart (+43 more)

### Community 2 - "Drift Schema Tables"
Cohesion: 0.04
Nodes (35): categories_table.dart, customers_table.dart, expense_categories_table.dart, LazyDatabase, openConnection, WasmDatabase, AuditLog, Categories (+27 more)

### Community 3 - "Drift Generated Companions"
Cohesion: 0.04
Nodes (53): _, AuditLogCompanion, AuditLogData, CategoriesCompanion, Category, copyWith, copyWithCompanion, Customer (+45 more)

### Community 4 - "Core Providers + Widgets"
Cohesion: 0.04
Nodes (43): app.dart, core/database/app_database.dart, core/providers/database_provider.dart, ../../../core/providers/hive_provider.dart, dart:math, dart:ui, Connectivity, extractWrappedPath (+35 more)

### Community 5 - "Settings Screen"
Cohesion: 0.05
Nodes (43): _AppearanceSection, _BackupSection, build, Card, Column, _confirmReset, _CurrencyPickerSheet, _CurrencySection (+35 more)

### Community 6 - "Onboarding Flow"
Cohesion: 0.05
Nodes (42): back, build, next, OnboardingNotifier, saveDefaultTaxId, saveOnboardingComplete, setBusinessName, setCountry (+34 more)

### Community 7 - "Backup Pipeline"
Cohesion: 0.07
Nodes (30): dart:io, LazyDatabase, openConnection, BackupService, File, UnimplementedError, BackupRepository, Exception (+22 more)

### Community 8 - "Cart Detail Sheets"
Cohesion: 0.06
Nodes (31): build, CartDetailScreen, _CartLineItem, CheckboxListTile, Container, _CustomerPickerSheet, _CustomerPickerSheetState, _DiscountSheet (+23 more)

### Community 9 - "Held Orders"
Cohesion: 0.07
Nodes (29): archive, archiveAll, delete, deleteAllArchived, HeldOrdersNotifier, hold, holdCurrentCart, unarchive (+21 more)

### Community 10 - "Help Screens"
Cohesion: 0.06
Nodes (28): _Article, _ArticleCard, build, LearnScreen, Scaffold, SizedBox, build, _KeyChip (+20 more)

### Community 11 - "Router (app.dart)"
Cohesion: 0.07
Nodes (29): build, Container, GoRouter, POSApp, SingleActivator, package:pos_app/features/audit/presentation/audit_log_screen.dart, package:pos_app/features/backup/presentation/backup_screen.dart, package:pos_app/features/cart/presentation/cart_detail_screen.dart (+21 more)

### Community 12 - "Expenses Screen"
Cohesion: 0.07
Nodes (28): build, _CategoryChips, Center, _Chip, Color, Column, Container, dispose (+20 more)

### Community 13 - "POS Home Screen"
Cohesion: 0.07
Nodes (28): build, CartScreen, _CartScreenState, _CategoryRow, Center, _Chip, dispose, Divider (+20 more)

### Community 14 - "Cart State"
Cohesion: 0.07
Nodes (26): add, addItem, addProduct, build, CartNotifier, CartSession, CartSessionNotifier, CartSummary (+18 more)

### Community 15 - "Currency + Order Detail"
Cohesion: 0.08
Nodes (23): CurrencyFormatter, format, formatPlain, build, Column, Container, _DetailBody, _DetailData (+15 more)

### Community 16 - "Theme + Receipt"
Cohesion: 0.08
Nodes (23): backgroundGradient, BoxDecoration, _build, Color, ctaButtonStyle, dark, _darkScheme, frostedBar (+15 more)

### Community 17 - "Audit + Sync Services"
Cohesion: 0.08
Nodes (21): dart:convert, ../database/app_database.dart, ../database/tables/audit_log_table.dart, ../database/tables/outbox_queue_table.dart, StateError, AuditService, _sendEntry, SyncService (+13 more)

### Community 18 - "Reports Dashboard"
Cohesion: 0.08
Nodes (23): _Body, build, Card, Column, Container, DashboardScreen, _DashboardScreenState, DateTime (+15 more)

### Community 19 - "Store Profile + Side Nav"
Cohesion: 0.09
Nodes (21): build, didChangeDependencies, dispose, _label, saveBusinessAddress, saveBusinessName, saveBusinessPan, saveBusinessPhone (+13 more)

### Community 20 - "Customers Screen"
Cohesion: 0.1
Nodes (20): _Badge, build, Card, Center, Container, _CustomerCard, _CustomerForm, _CustomerFormState (+12 more)

### Community 21 - "Country + Tax Settings"
Cohesion: 0.1
Nodes (19): ../domain/country_default.dart, CountryRepository, build, Center, dispose, ListTile, Padding, PopupMenuItem (+11 more)

### Community 22 - "Inventory Screen"
Cohesion: 0.1
Nodes (19): _badgeColor, build, Card, Center, _Chip, Column, Container, dispose (+11 more)

### Community 23 - "Orders History"
Cohesion: 0.1
Nodes (19): build, Card, Center, Container, CustomScrollView, _EmptyState, _methodLabel, _OrderCard (+11 more)

### Community 24 - "Product Form"
Cohesion: 0.11
Nodes (18): build, _ComponentEntry, _ComponentPickerSheet, _ComponentPickerSheetState, didChangeDependencies, dispose, Divider, DraggableScrollableSheet (+10 more)

### Community 25 - "Products Screen"
Cohesion: 0.11
Nodes (18): build, _CategoryChips, Center, _Chip, Container, dispose, Divider, _EmptyState (+10 more)

### Community 26 - "POS Filter State"
Cohesion: 0.22
Nodes (8): clearSearch, copyWith, PosFilterNotifier, PosFilterState, setCategory, setSearch, setSortMode, toggleView

### Community 27 - "Grid Product Tile"
Cohesion: 0.25
Nodes (7): build, Color, GestureDetector, GridProductTile, SizedBox, Spacer, _StepBtn

### Community 28 - "Tax Calculator"
Cohesion: 0.33
Nodes (5): compoundTax, lineItemTax, priceBeforeTax, _round, TaxCalculator

### Community 29 - "Print Service"
Cohesion: 0.33
Nodes (5): PrintService, ReceiptData, ReceiptLineItem, ReceiptTaxLine, UnimplementedError

### Community 30 - "Onboarding State"
Cohesion: 0.5
Nodes (3): country_default.dart, copyWith, OnboardingState

### Community 31 - "Cart Item Model"
Cohesion: 0.67
Nodes (2): CartItem, copyWith

### Community 32 - "Country Default"
Cohesion: 1.0
Nodes (1): CountryDefault

### Community 33 - "Drift Codegen Stub (orders)"
Cohesion: 1.0
Nodes (1): _

### Community 34 - "Drift Codegen Stub (tax)"
Cohesion: 1.0
Nodes (1): _

### Community 35 - "Drift Codegen Stub (customers)"
Cohesion: 1.0
Nodes (1): _

### Community 36 - "Drift Codegen Stub (audit)"
Cohesion: 1.0
Nodes (1): _

### Community 37 - "Drift Codegen Stub (sync)"
Cohesion: 1.0
Nodes (1): _

### Community 38 - "Drift Codegen Stub (products)"
Cohesion: 1.0
Nodes (1): _

### Community 39 - "Drift Codegen Stub (inventory)"
Cohesion: 1.0
Nodes (1): _

### Community 40 - "Drift Codegen Stub (expenses)"
Cohesion: 1.0
Nodes (1): _

### Community 41 - "String Utils"
Cohesion: 1.0
Nodes (0): 

## Knowledge Gaps
- **749 isolated node(s):** `app.dart`, `core/database/app_database.dart`, `core/providers/database_provider.dart`, `POSApp`, `build` (+744 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Country Default`** (2 nodes): `country_default.dart`, `CountryDefault`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Drift Codegen Stub (orders)`** (1 nodes): `_`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Drift Codegen Stub (tax)`** (1 nodes): `_`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Drift Codegen Stub (customers)`** (1 nodes): `_`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Drift Codegen Stub (audit)`** (1 nodes): `_`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Drift Codegen Stub (sync)`** (1 nodes): `_`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Drift Codegen Stub (products)`** (1 nodes): `_`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Drift Codegen Stub (inventory)`** (1 nodes): `_`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Drift Codegen Stub (expenses)`** (1 nodes): `_`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `String Utils`** (1 nodes): `string_utils.dart`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `package:flutter/material.dart` connect `Core Providers + Widgets` to `Services + Payment UI`, `Settings Screen`, `Onboarding Flow`, `Backup Pipeline`, `Cart Detail Sheets`, `Held Orders`, `Help Screens`, `Router (app.dart)`, `Expenses Screen`, `POS Home Screen`, `Currency + Order Detail`, `Theme + Receipt`, `Audit + Sync Services`, `Reports Dashboard`, `Store Profile + Side Nav`, `Customers Screen`, `Country + Tax Settings`, `Inventory Screen`, `Orders History`, `Product Form`, `Products Screen`, `Grid Product Tile`?**
  _High betweenness centrality (0.238) - this node is a cross-community bridge._
- **Why does `package:drift/drift.dart` connect `Drift Schema Tables` to `Services + Payment UI`, `Drift DAOs`, `Onboarding Flow`, `Backup Pipeline`, `Expenses Screen`, `Currency + Order Detail`, `Audit + Sync Services`, `Customers Screen`, `Country + Tax Settings`, `Product Form`?**
  _High betweenness centrality (0.219) - this node is a cross-community bridge._
- **Why does `package:flutter_riverpod/flutter_riverpod.dart` connect `Core Providers + Widgets` to `Services + Payment UI`, `Settings Screen`, `Onboarding Flow`, `Backup Pipeline`, `Cart Detail Sheets`, `Held Orders`, `Router (app.dart)`, `Expenses Screen`, `POS Home Screen`, `Cart State`, `Currency + Order Detail`, `Audit + Sync Services`, `Reports Dashboard`, `Store Profile + Side Nav`, `Customers Screen`, `Country + Tax Settings`, `Inventory Screen`, `Orders History`, `Product Form`, `Products Screen`, `POS Filter State`?**
  _High betweenness centrality (0.197) - this node is a cross-community bridge._
- **What connects `app.dart`, `core/database/app_database.dart`, `core/providers/database_provider.dart` to the rest of the system?**
  _749 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Services + Payment UI` be split into smaller, more focused modules?**
  _Cohesion score 0.04 - nodes in this community are weakly interconnected._
- **Should `Drift DAOs` be split into smaller, more focused modules?**
  _Cohesion score 0.05 - nodes in this community are weakly interconnected._
- **Should `Drift Schema Tables` be split into smaller, more focused modules?**
  _Cohesion score 0.04 - nodes in this community are weakly interconnected._