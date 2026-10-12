# ── OkHttp / OpenJSSE ────────────────────────────────────────────────────────
# R8 cannot find org.openjsse.net.ssl.OpenJSSE which is referenced by
# okhttp3.internal.platform.OpenJSSEPlatform but is not present on Android.
# Tell R8 to ignore missing classes in the OpenJSSE namespace entirely.
-dontwarn org.openjsse.**
-dontwarn okhttp3.internal.platform.OpenJSSEPlatform
-dontwarn okhttp3.internal.platform.ConscryptPlatform

# Keep OkHttp internals that are accessed reflectively
-keep class okhttp3.** { *; }
-dontwarn okhttp3.**

# ── Flutter ──────────────────────────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ── Google ML Kit ─────────────────────────────────────────────────────────────
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# ── General ──────────────────────────────────────────────────────────────────
# Keep line number info for crash reporting
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
