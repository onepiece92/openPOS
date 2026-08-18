# Projects Dependencies

**Analysis Date:** 2026-04-22

## Overview

This POS application focuses on offline reliability and hardware integration (printers). It uses Riverpod for state management and Drift (SQLite) for the primary database.

| Category | Key Packages | Purpose |
| :--- | :--- | :--- |
| **State Management** | `flutter_riverpod` | Logic and UI synchronization (hand-written providers; no codegen). |
| **Database** | `drift`, `sqlite3_flutter_libs` | Relational storage (SQLite). |
| **KV Storage** | `hive`, `hive_flutter` | Lightweight key-value storage. |
| **Hardware** | `flutter_thermal_printer`, `esc_pos_utils_plus` | Thermal printer integration (BLE/USB) and ESC/POS encoding. |
| **PDF/Reports** | `pdf`, `printing` | Generating and printing receipt PDFs. |
| **Utility** | `intl`, `path_provider`, `share_plus`, `file_picker`, `archive` | Formatters, file paths, sharing/picking files, zip backups. Fonts are bundled (`google_fonts` is banned — offline-only). |

## Major Dependencies

### [State Management] flutter_riverpod
- **Category:** Architecture
- **Version:** Specified in `pubspec.yaml` (likely ^2.x)
- **Status:** Critical core dependency.

### [Persistence] drift
- **Category:** Data Storage
- **Version:** ^2.20.0
- **Status:** Critical core dependency. Manages all transactional data (sales, inventory).

### [Hardware] flutter_thermal_printer
- **Category:** POS Hardware
- **Status:** Critical for receipt printing. Supports Bluetooth/Network printers.

## Dev Dependencies

- `drift_dev`: Code generation for the database layer.
- `build_runner`: CLI tool to run all generators.

## Outdated / Deprecated Dependencies

- *None identified during audit.*

---

*Dependency audit: 2026-04-22*
*Update whenever `pubspec.yaml` is modified.*
