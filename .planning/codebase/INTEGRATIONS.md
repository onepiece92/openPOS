# External Integrations

**Analysis Date:** 2026-04-22

## APIs & External Services

**Payment Processing:**
- None - This is an offlinePOS app.

**Email/SMS:**
- None - Support is handled via external URL launching (WhatsApp, Email).

**External APIs:**
- None - The app operates fully offline.

## Data Storage

**Databases:**
- Drift (SQLite) - Primary relational data store for persistent application state.
  - Connection: via `.sqlite` file in app documents directory.
  - Client: `drift` / `drift_dev`.
  - Migrations: Handled in `AppDatabase` class.
- Hive - NoSQL key-value store used for session-like data or small key-value pairs.
  - Client: `hive_flutter`.

**File Storage:**
- Path Provider - Managed via Flutter's `path_provider` to access the application's document and cache directories.

**Caching:**
- None (beyond Drift/Hive persistent storage).

## Authentication & Identity

**Auth Provider:**
- Local Auth - Basic local user management (no external auth provider).

## Monitoring & Observability

**Error Tracking:**
- None.

**Analytics:**
- None.

**Logs:**
- stdout - Debug logs only.

## CI/CD & Deployment

**Hosting:**
- Mobile App - Distributed via app stores (presumably).

**CI Pipeline:**
- None detected in `.github/workflows`.

## Environment Configuration

**Development:**
- Standard Flutter environment.

## Webhooks & Callbacks

**Incoming:**
- None.

**Outgoing:**
- None.

---

*Integration audit: 2026-04-22*
*Update when adding/removing external services*
