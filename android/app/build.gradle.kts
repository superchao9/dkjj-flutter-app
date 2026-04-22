plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.io.FileInputStream
import java.util.Properties

fun loadPropertiesIfExists(filePath: String): Properties {
    val properties = Properties()
    val file = rootProject.file(filePath)
    if (file.exists()) {
        FileInputStream(file).use { properties.load(it) }
    }
    return properties
}

val devKeyProps = loadPropertiesIfExists("key_dev.properties")
val testKeyProps = loadPropertiesIfExists("key_test.properties")
val prodKeyProps = loadPropertiesIfExists("key_prod.properties")

android {
    namespace = "com.dkjj.app.mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.dkjj.app.mobile"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("devRelease") {
            val hasCustomSigning = devKeyProps.isNotEmpty()
            if (hasCustomSigning) {
                keyAlias = devKeyProps["keyAlias"] as String?
                keyPassword = devKeyProps["keyPassword"] as String?
                storeFile = file(devKeyProps["storeFile"] as String)
                storePassword = devKeyProps["storePassword"] as String?
            } else {
                initWith(getByName("debug"))
            }
        }
        create("testRelease") {
            val hasCustomSigning = testKeyProps.isNotEmpty()
            if (hasCustomSigning) {
                keyAlias = testKeyProps["keyAlias"] as String?
                keyPassword = testKeyProps["keyPassword"] as String?
                storeFile = file(testKeyProps["storeFile"] as String)
                storePassword = testKeyProps["storePassword"] as String?
            } else {
                initWith(getByName("debug"))
            }
        }
        create("prodRelease") {
            val hasCustomSigning = prodKeyProps.isNotEmpty()
            if (hasCustomSigning) {
                keyAlias = prodKeyProps["keyAlias"] as String?
                keyPassword = prodKeyProps["keyPassword"] as String?
                storeFile = file(prodKeyProps["storeFile"] as String)
                storePassword = prodKeyProps["storePassword"] as String?
            } else {
                initWith(getByName("debug"))
            }
        }
    }

    flavorDimensions += "env"
    productFlavors {
        create("dev") {
            dimension = "env"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
            resValue("string", "app_name", "低空基础设施管理系统-开发")
            signingConfig = signingConfigs.getByName("devRelease")
        }
        create("qa") {
            dimension = "env"
            applicationIdSuffix = ".test"
            versionNameSuffix = "-test"
            resValue("string", "app_name", "低空基础设施管理系统-测试")
            signingConfig = signingConfigs.getByName("testRelease")
        }
        create("prod") {
            dimension = "env"
            resValue("string", "app_name", "低空基础设施管理系统")
            signingConfig = signingConfigs.getByName("prodRelease")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("prodRelease")
        }
    }
}

flutter {
    source = "../.."
}
