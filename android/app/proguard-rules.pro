# Keep AdMob classes
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }

# Keep Flutter local notifications
-keep class com.dexterous.** { *; }

# Keep audioplayers
-keep class xyz.luan.audioplayers.** { *; }

# General Flutter
-keep class io.flutter.** { *; }
-dontwarn io.flutter.embedding.**
