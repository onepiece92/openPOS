## Offline-first (non-negotiable)

This is a **100% offline** Flutter POS app. Treat this as a hard constraint, not a preference.

- **Never** add code that makes outbound network calls — no HTTP/Dio/HttpClient, no Firebase/Supabase/cloud SDKs, no analytics/telemetry/crash reporting, no remote config, no update checkers.
- **Never** add packages that fetch resources at runtime — specifically banned: `google_fonts` (use bundled `assets/fonts/JetBrainsMono-*.ttf` via `fontFamily: 'JetBrainsMono'`), `connectivity_plus`, `workmanager` (for sync), Firebase/Supabase clients.
- **Never** re-introduce the deleted sync/cloud-backup scaffolding (outbox queue, sync_service, sync_dao, connectivity_provider, BackupService.uploadToCloud/restoreFromCloud).
- **Never** re-add `INTERNET` permission to [android/app/src/main/AndroidManifest.xml](android/app/src/main/AndroidManifest.xml) or `com.apple.security.network.*` to [macos/Runner/Release.entitlements](macos/Runner/Release.entitlements). The release binary must be sandbox-blocked from the network.
- **Allowed network-adjacent code**: `url_launcher` for user-initiated `mailto:`/`tel:`/`sms:`/`https://` links that hand off to native apps (these don't make the app itself reach the network).
- If a feature genuinely needs network access (e.g. real Bluetooth-printer firmware update over WiFi), call it out explicitly and get confirmation before wiring it up.

## graphify

This project has a graphify knowledge graph at graphify-out/.

Rules:
- Before answering architecture or codebase questions, read graphify-out/GRAPH_REPORT.md for god nodes and community structure
- If graphify-out/wiki/index.md exists, navigate it instead of reading raw files
- After modifying code files in this session, run `graphify update .` to keep the graph current (AST-only, no API cost)
