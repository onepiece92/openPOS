# Technology Stack

**Analysis Date:** 2026-04-22

## Languages

**Primary:**
- Dart 3.5+ - All application logic, UI, and data handling.

**Secondary:**
- Kotlin/Swift - Platform-specific implementations (standard Flutter bridge).

## Runtime

**Environment:**
- Flutter SDK 3.24.0+
- Multi-platform support: Android, iOS (Primary targets).

**Package Manager:**
- pub - Dart's package manager.
- Lockfile: `pubspec.lock` present.

## Frameworks

**Core:**
- Flutter - UI Framework.
- Riverpod - Reactive state management.
- Go Router - Declarative routing.

**Database / Persistence:**
- Drift (SQLite) - Primary relational database for offline-first transactional data.
- Hive - NoSQL key-value store for lightweight local state/settings.

**Hardware / IO:**
- Heathen Printer Plus - Interface for ESC/POS thermal printers.
- ESC/POS Utils Plus - POS printing utilities.

## Key Dependencies

**Critical:**
- `drift` & `drift_sqlite3` - Relational data persistence logic.
- `flutter_riverpod` - Application state synchronization and dependency injection.
- `go_router` - Deep-linkable app navigation.
- `heathen_printer_plus` - Core POS printing functionality.
- `pdf` - PDF generation for receipts and reports.
- `share_plus` - Exporting data (CSV/PDF) to other apps.

**Infrastructure:**
- `path_provider` - Secure local file system location management.
- `intl` - Localization and number formatting for currency/dates.

## Configuration

**Environment:**
- Configured via static constants and build-time environment variables (if any).
- `drift` database path managed via `path_provider`.

**Build:**
- `pubspec.yaml` - Dependency and asset management.
- `build.yaml` - Configuration for code generation (Drift, Freezed, etc.).

## Platform Requirements

**Development:**
- macOS with Xcode (for iOS/macOS builds).
- Android Studio with Android SDK.
- Flutter SDK.

**Production:**
- Android 5.0 (API 21) or higher.
- iOS 12.0 or higher.
