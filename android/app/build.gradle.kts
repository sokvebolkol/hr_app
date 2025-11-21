import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("org.jetbrains.kotlin.android") version "2.1.0"
}

// Load keystore properties
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
keystoreProperties.load(FileInputStream(keystorePropertiesFile))

android {
    namespace = "com.vebol.employee.hr"
    compileSdk = 36
    ndkVersion = "28.0.12433566"
    buildToolsVersion = "36.0.0"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "21"
    }

    defaultConfig {
        applicationId = "com.vebol.employee.hr"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
        ndk {
            abiFilters += listOf("arm64-v8a", "x86_64")
        }
    }

    signingConfigs {
        create("release") {
            storeFile = rootProject.file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation(platform("com.google.firebase:firebase-bom:34.2.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-messaging")
    implementation("com.google.firebase:firebase-firestore")
    implementation("androidx.multidex:multidex:2.0.1")
}

flutter {
    source = "../.."
}

// Task to copy APK to Flutter's expected location
tasks.register<Copy>("copyApkToFlutterOutput") {
    description = "Copies APK to Flutter's expected output directory"
    from("$buildDir/outputs/apk/debug") {
        include("*.apk")
        rename { "app-debug.apk" }
    }
    from("$buildDir/outputs/apk/release") {
        include("*.apk")
        rename { "app-release.apk" }
    }
    into("${rootProject.projectDir}/../build/app/outputs/flutter-apk")
    
    doFirst {
        file("${rootProject.projectDir}/../build/app/outputs/flutter-apk").mkdirs()
    }
}

// Automatically run copy task after assembling
afterEvaluate {
    tasks.named("assembleDebug") {
        finalizedBy("copyApkToFlutterOutput")
    }
    
    tasks.named("assembleRelease") {
        finalizedBy("copyApkToFlutterOutput")
    }
}
