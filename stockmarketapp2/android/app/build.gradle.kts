plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    // ─── ADD THIS LINE ──────────────────────────────────────────────────
    ndkVersion = "27.0.12077973"      // ← same version the plugins expect
    // ────────────────────────────────────────────────────────────────────

    namespace    = "com.example.stockmarketapp2"
    compileSdk   = flutter.compileSdkVersion
    ndkVersion   = flutter.ndkVersion        // you may safely delete this line
    // (it will now be overridden)
    defaultConfig {
        applicationId = "com.example.stockmarketapp2"
        minSdk        = flutter.minSdkVersion
        targetSdk     = flutter.targetSdkVersion
        versionCode   = flutter.versionCode
        versionName   = flutter.versionName
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
