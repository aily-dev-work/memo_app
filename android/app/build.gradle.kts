plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.memo_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    flavorDimensions += "env"
    productFlavors {
        create("dev") {
            dimension = "env"
            applicationIdSuffix = ".dev"
            manifestPlaceholders["admobAppId"] = "ca-app-pub-3940256099942544~3347511713"
        }
        create("prod") {
            dimension = "env"
            manifestPlaceholders["admobAppId"] =
                (project.findProperty("admobAppIdProd") as String?) ?: "ca-app-pub-0000000000000000~0000000000"
        }
    }

    defaultConfig {
        applicationId = "com.example.memo_app"
        minSdk = flutter.minSdkVersion
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

flutter {
    source = "../.."
}

// APKをFlutterが期待する場所にコピーするタスク
afterEvaluate {
    tasks.named("assembleDebug") {
        doLast {
            val apkFile = file("${layout.buildDirectory.get()}/outputs/flutter-apk/app-debug.apk")
            val targetDir = file("../../build/app/outputs/flutter-apk")
            val targetFile = file("${targetDir}/app-debug.apk")
            
            if (apkFile.exists()) {
                targetDir.mkdirs()
                apkFile.copyTo(targetFile, overwrite = true)
                println("APK copied to ${targetFile.absolutePath}")
            } else {
                println("APK file not found at ${apkFile.absolutePath}")
            }
        }
    }

    tasks.named("assembleRelease") {
        doLast {
            val apkFile = file("${layout.buildDirectory.get()}/outputs/flutter-apk/app-release.apk")
            val targetDir = file("../../build/app/outputs/flutter-apk")
            val targetFile = file("${targetDir}/app-release.apk")
            
            if (apkFile.exists()) {
                targetDir.mkdirs()
                apkFile.copyTo(targetFile, overwrite = true)
                println("APK copied to ${targetFile.absolutePath}")
            } else {
                println("APK file not found at ${apkFile.absolutePath}")
            }
        }
    }
}
