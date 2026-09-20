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

## Star StarXpand SDK (TSP100III printing)
## The AAR ships an empty proguard.txt but carries native libraries that
## call back into these classes by name — R8 renaming them breaks printing
## in release builds only.
-keep class com.starmicronics.** { *; }
-dontwarn com.starmicronics.**
