## Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

## Drift / SQLite
-keep class org.sqlite.** { *; }
-keep class sqlite3.** { *; }

## Play Core (deferred components — referenced by Flutter engine)
-dontwarn com.google.android.play.core.**
