import java.io.File

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val environmentSigningValues = mapOf(
    "storeFile" to providers.environmentVariable("TOKENFRONT_UPLOAD_STORE_FILE").orNull,
    "storePassword" to providers.environmentVariable("TOKENFRONT_UPLOAD_STORE_PASSWORD").orNull,
    "keyAlias" to providers.environmentVariable("TOKENFRONT_UPLOAD_KEY_ALIAS").orNull,
    "keyPassword" to providers.environmentVariable("TOKENFRONT_UPLOAD_KEY_PASSWORD").orNull,
)

fun completeSigningValues(values: Map<String, String?>): Map<String, String>? {
    if (values.values.any { it.isNullOrBlank() }) return null
    return values.mapValues { it.value!! }
}

val releaseSigningValues = completeSigningValues(environmentSigningValues)
val releaseSigningError =
    "Release signing requires TOKENFRONT_UPLOAD_STORE_FILE, " +
        "TOKENFRONT_UPLOAD_STORE_PASSWORD, TOKENFRONT_UPLOAD_KEY_ALIAS, " +
    "and TOKENFRONT_UPLOAD_KEY_PASSWORD."

val testAdMobAppId = "ca-app-pub-3940256099942544~3347511713"
val productionAdMobAppId = "ca-app-pub-3004906966180197~5057217646"

// Resolve task abbreviations (for example assembleRel) before enforcing release signing.
// The task graph is ready before any task executes, so this catches every app release
// artifact task while leaving debug-only graphs available without credentials.
gradle.taskGraph.whenReady {
    val appReleaseTaskInGraph = allTasks.any { task ->
        task.path.startsWith("${project.path}:") &&
            task.name.contains("release", ignoreCase = true)
    }
    if (appReleaseTaskInGraph && releaseSigningValues == null) {
        throw GradleException(releaseSigningError)
    }
}

android {
    namespace = "com.toris.tokenfront.tokenfront"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.toris.tokenfront.tokenfront"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["admobAppId"] = testAdMobAppId
    }

    signingConfigs {
        releaseSigningValues?.let { values ->
            create("release") {
                val storeFileValue = values.getValue("storeFile")
                storeFile = if (File(storeFileValue).isAbsolute) {
                    File(storeFileValue)
                } else {
                    rootProject.file(storeFileValue)
                }
                storePassword = values.getValue("storePassword")
                keyAlias = values.getValue("keyAlias")
                keyPassword = values.getValue("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            manifestPlaceholders["admobAppId"] = productionAdMobAppId
            releaseSigningValues?.let {
                signingConfig = signingConfigs.getByName("release")
            }
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
