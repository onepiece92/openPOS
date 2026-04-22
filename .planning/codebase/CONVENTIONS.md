# Project Conventions

## General Standards
- **Naming:** Follow official [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style).
- **Imports:** Always use package imports (`package:pos_app/...`). Avoid relative imports.
- **Lints:** Enforced via `analysis_options.yaml` (includes `flutter_lints`).
- **Generation:** Many files rely on code generation (`drift`, `riverpod_generator`). Run `dart run build_runner build --delete-conflicting-outputs`.

## Feature Architecture
Each feature must follow the **Presentation-Domain-Data** pattern if applicable:
- **Presentation:** Contains `screens`, `widgets`, and `notifiers/providers`.
- **Domain:** Interface definitions and business entities.
- **Data:** Repository implementations and data sources.

## State Management (Riverpod)
- **Providers:** Define in the feature's `presentation` or `domain` folder.
- **Notifiers:** Use the `Notifier` or `AsyncNotifier` classes (Riverpod 2.0+).
- **Naming:** Name providers with the suffix `Provider` (e.g., `cartNotifierProvider`).

## Database (Drift)
- **Tables:** Defined in `lib/core/database/tables/`.
- **DAOs:** Defined in `lib/core/database/daos/`.
- **Migrations:** Handled in `AppDatabase` (in `lib/core/database/app_database.dart`).

## UI & UX
- **Theme:** Do not hardcode colors. Use `Theme.of(context).colorScheme` or custom theme extensions in `AppTheme`.
- **Responsive Layout:** Ensure screens handle horizontal scaling for desktop POS use cases.
- **Navigation:** Use `context.go()` or `context.push()` from `go_router`.

## External Integrations
- **Print Logic:** Abstracted via `PrintingService`.
- **PDF Logic:** Managed within respective receipt/report generators.
