# Project Architecture

## Overview

Offline-first POS application built with Flutter, following a **Feature-First Layered Architecture**. The app is designed for desktop/tablet use cases with deep hardware integration for thermal printing. The development is organized into 8 sequential phases as detailed in [ROADMAP.md](file:///Users/aashishbijukchhe/Documents/anti/offlinePOS/ROADMAP.md).

## Core Pillars

### 1. State Management (Riverpod)
- **Providers:** Used for reactive UI updates and dependency injection.
- **AsyncNotifier:** Preferred for complex state that involves asynchronous operations (e.g., database fetching, hardware status).
- **Hooks:** Not explicitly seen in `app.dart`, but standard Riverpod patterns apply.

### 2. Navigation (GoRouter)
- Located in `lib/app.dart`.
- Uses a central `routerProvider`.
- Features global shortcuts (Keyboard modifiers) for power users.
- Includes an `onboarding` redirect logic.

### 3. Data Layer (Drift & Hive)
- **Drift (Relational):** Single source of truth for transactions, products, and inventory. Tables are defined in `lib/core/database/tables/`.
- **Hive (KV Store):** Used for configuration, branding, printer settings, and held order snapshots. Initialized in `main.dart`.

### 4. Hardware Integration
- **ESC/POS Printing:** Managed through `heathen_printer_plus`.
- **PDF Generation:** Vouchers and receipts are generated using the `pdf` package and printed via `printing`.

## Directory Structure

```text
lib/
├── core/               # Shared infrastructure
│   ├── database/       # Drift setup (Tables, DAOs, Connection)
│   ├── providers/      # Global state providers (DB, Hive, Router)
│   ├── theme/          # Design system (Colors, Gradients, Typography)
│   └── utils/          # Extensions, Formatters, Low-level utilities
├── features/           # Modularized feature logic
│   ├── [feature_name]/
│   │   ├── domain/     # Entities, Repositories (optional)
│   │   ├── data/       # Data sources (optional)
│   │   └── presentation/ # Screens, Widgets, Notifiers
├── shared/             # (Planned) Common UI components
├── app.dart            # Main App Widget & Router
└── main.dart           # Initialization entry point
```

## Data Flow

1. **User Interaction:** Triggered in `presentation` layer.
2. **State Logic:** `AsyncNotifier` or `Provider` processes the action.
3. **Persistence:** Logic calls a `DAO` (Data Access Object) from the `core/database` layer.
4. **Reactivity:** Drift stream or Riverpod `ref.watch` updates the UI automatically when data changes.
