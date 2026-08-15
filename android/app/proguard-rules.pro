# ── Flutter & Dart Core ──────────────────────────────────────────────────────
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ── Flutter Local Notifications ──────────────────────────────────────────────
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# ── Local Authentication (Biometrics) ────────────────────────────────────────
-keep class io.flutter.plugins.localauth.** { *; }

# ── OpenFilex & FileProvider ─────────────────────────────────────────────────
-keep class com.crazecoder.openfile.** { *; }
-keep class androidx.core.content.FileProvider { *; }

# ── Gson / JSON Serialization ────────────────────────────────────────────────
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
-keepattributes Signature, *Annotation*, EnclosingMethod

# ── OkHttp & Dio ─────────────────────────────────────────────────────────────
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase

# ── Kotlin Coroutines & Reflection ───────────────────────────────────────────
-dontwarn kotlin.**
-keep class kotlin.Metadata { *; }
