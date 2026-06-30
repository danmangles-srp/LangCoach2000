plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.rivendell.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Rivendell — Android-only v1; min API 26 (8.0) per CLAUDE.md.
        applicationId = "com.rivendell.app"
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // AnkiDroid content-provider API (FR-1.3.3, T4.1). The api-v1.1.0 artifact
    // drags an old kotlin-stdlib; exclude it so the project's Kotlin 2.3.20
    // stdlib wins (the API itself is Java and needs no kotlin-stdlib).
    implementation("com.github.ankidroid:Anki-Android:api-v1.1.0") {
        exclude(group = "org.jetbrains.kotlin")
    }
}
