# Offline-First Flutter POS

A professional, tablet-first Point of Sale application built with Flutter, designed for performance, reliability, and deep hardware integration in offline environments.

## Core Mission
To provide a seamless POS experience that functions 100% offline, synchronizing data only when necessary, and integrating deeply with business hardware like thermal printers.

## Guiding Principles
- **Offline-First:** All transactional data must be persisted locally in Drift (SQLite) before any network operations.
- **Hardware Integration:** Stable and high-performance integration with thermal printers (ESC/POS) is non-negotiable.
- **Feature-First Architecture:** The project is organized by business feature (Auth, POS, Inventory) rather than technical layer (Models, Views, Controllers).
- **Premium Aesthetics:** A sleek, dark-themed, glassmorphic UI that feels professional and responsive.

## Technology Stack
- **UI:** Flutter
- **State Management:** Riverpod
- **Local Database:** Drift (SQLite)
- **Local Settings:** Hive
- **Printing:** Heathen Printer Plus (ESC/POS)
- **Routing:** GoRouter

## Architectural Decisions
- **Decision Layering:** Domain logic resides in `features/domain`, UI in `features/presentation`, and data access in `features/data` or `core/database`.
- **Theme:** Vibrant, curated color palettes with HSL-tailored dark mode.
- **Dependency DI:** Riverpod is the sole DI and state synchronization mechanism.

## Standard Practices
- **Linting:** Strict adherence to `flutter_lints` and project-specific conventions.
- **Testing:** Unit tests for domain logic; Widget tests for shared components.
- **PRD:** Tracked in [ROADMAP.md](file:///Users/aashishbijukchhe/Documents/anti/offlinePOS/ROADMAP.md).
