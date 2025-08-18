# Flutter embedding
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.app.** { *; }

# Flutter plugins genel kuralı
# Bu kural, tüm Flutter pluginlerinin Java/Kotlin kodunun
# kaldırılmasını engeller. Çoğu MissingPluginException hatasını çözer.
-keep class io.flutter.plugins.** { *; }
-keep class * extends io.flutter.plugin.common.MethodCallHandler { *; }
-keep public class * extends io.flutter.plugin.common.MethodChannel$MethodCallHandler {*;}

# permission_handler
# MissingPluginException hatasının ana kaynağı budur.
# Daha spesifik ve güvenli kurallar ekledik.
-keep class com.baseflow.permissionhandler.** { *; }
-keep class com.baseflow.permissionhandler.PermissionHandlerPlugin { *; }
-dontwarn com.baseflow.**

# Play Core / Deferred Components
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**
-keep interface com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Split compatibility
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }

# ffmpeg-kit
-keep class com.arthenica.** { *; }
-dontwarn com.arthenica.**

# flutter_foreground_task
-keep class com.pravera.** { *; }
-dontwarn com.pravera.**

# Reflection için ek koruma (opsiyonel ama önerilen)
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses