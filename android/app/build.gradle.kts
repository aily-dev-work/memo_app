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

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.memo_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
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
