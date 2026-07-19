plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // google_sign_in (FR-1.5.3): consumes google-services.json. The build will
    // fail until that file is dropped into android/app/ — see the PR description
    // for the one-time Google Cloud Console setup.
    id("com.google.gms.google-services")
}

android {
    namespace = "com.rivendell.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications (T5.3, FR-1.4.2) uses java.time, which
        // only ships on Android API 26+ at runtime — desugaring backports it
        // so the plugin works on the minSdk 26 floor. The plugin's AAR metadata
        // check enforces this flag is on.
        isCoreLibraryDesugaringEnabled = true
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
            // R8 minify runs in release (Flutter default). Without these keep rules
            // it strips androidx.work.impl.WorkDatabase_Impl's no-arg ctor, so
            // androidx.startup throws NoSuchMethodException and the app crashes on
            // launch before Flutter loads. See app/proguard-rules.pro.
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
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
    // Core-library desugaring backport (T5.3): supplies java.time to
    // flutter_local_notifications on API 26.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
