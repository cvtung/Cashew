# Flutter default rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keepclassmembers class * extends com.google.firebase.auth.FirebaseAuth { *; }

# Google Sign-In / Google APIs
-keep class com.google.api.** { *; }
-keep class com.google.auth.** { *; }

# Local Auth (biometric)
-keep class androidx.biometric.** { *; }

# In-App Review
-keep class com.google.android.play.core.** { *; }

# Kotlin
-keep class kotlin.** { *; }
-keep class org.jetbrains.kotlin.** { *; }

# Keep model/serialization classes
-keep class tungcv.cashew.** { *; }
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Keep enum classes (used in many Flutter plugins)
-keepclassmembers enum * { *; }

# Keep Parcelable implementations
-keepclassmembers class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator CREATOR;
}

# Keep R8 from stripping generic signatures (needed for some reflection)
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Keep JavaScript interface methods
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
