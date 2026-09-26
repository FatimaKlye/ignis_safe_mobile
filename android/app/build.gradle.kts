plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.ignis_safe"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.example.ignis_safe"
        minSdk = 25
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")

            // Flutter supplies three ABIs by default at the build-type level,
            // which takes precedence over defaultConfig filters. The embedded
            // Unity export only contains ARM64, so keep the release APK aligned
            // with the architecture that can run every simulation.
            ndk {
                abiFilters.clear()
                abiFilters += "arm64-v8a"
            }
        }
    }

    // Compress native libraries inside the APK. Android extracts them during
    // installation, so runtime behavior stays the same while the shared APK is
    // substantially smaller to download.
    packaging {
        jniLibs {
            useLegacyPackaging = true
        }
    }
}

dependencies {
    implementation(project(":unityLibrary"))
}

flutter {
    source = "../.."
}
