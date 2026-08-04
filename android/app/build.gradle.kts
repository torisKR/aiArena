import java.io.File
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseKeyProperties = Properties()
val releaseKeyPropertiesFile = rootProject.file("key.properties")
if (releaseKeyPropertiesFile.isFile) {
    releaseKeyPropertiesFile.inputStream().use(releaseKeyProperties::load)
}

val environmentSigningValues = mapOf(
    "storeFile" to providers.environmentVariable("TOKENFRONT_UPLOAD_STORE_FILE").orNull,
    "storePassword" to providers.environmentVariable("TOKENFRONT_UPLOAD_STORE_PASSWORD").orNull,
    "keyAlias" to providers.environmentVariable("TOKENFRONT_UPLOAD_KEY_ALIAS").orNull,
    "keyPassword" to providers.environmentVariable("TOKENFRONT_UPLOAD_KEY_PASSWORD").orNull,
)
val keyPropertiesSigningValues = mapOf(
    "storeFile" to releaseKeyProperties.getProperty("storeFile"),
    "storePassword" to releaseKeyProperties.getProperty("storePassword"),
    "keyAlias" to releaseKeyProperties.getProperty("keyAlias"),
    "keyPassword" to releaseKeyProperties.getProperty("keyPassword"),
)

fun completeSigningValues(values: Map<String, String?>): Map<String, String>? {
    if (values.values.any { it.isNullOrBlank() }) return null
    return values.mapValues { it.value!! }
}

// Environment variables are preferred; an ignored android/key.properties file is
// supported for local builds. A release task always fails before compilation when
// neither source contains all four values.
val releaseSigningValues = completeSigningValues(environmentSigningValues)
    ?: completeSigningValues(keyPropertiesSigningValues)
val releaseTaskRequested = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true)
}
if (releaseTaskRequested && releaseSigningValues == null) {
    throw GradleException(
        "Release signing requires TOKENFRONT_UPLOAD_STORE_FILE, " +
            "TOKENFRONT_UPLOAD_STORE_PASSWORD, TOKENFRONT_UPLOAD_KEY_ALIAS, " +
            "and TOKENFRONT_UPLOAD_KEY_PASSWORD, or a complete android/key.properties file.",
    )
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
