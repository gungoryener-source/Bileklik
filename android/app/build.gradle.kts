import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Yayın imzası şu sırayla aranır:
// 1. android/key.properties (yerel bilgisayar; depoya girmez):
//      storeFile=/tam/yol/bileklik-yukleme.jks
//      storePassword=…  keyAlias=…  keyPassword=…
// 2. Ortam değişkenleri (GitHub Actions, gizli değerlerden):
//      BILEKLIK_KEYSTORE, BILEKLIK_KEYSTORE_PASSWORD, BILEKLIK_KEY_ALIAS,
//      BILEKLIK_KEY_PASSWORD
// 3. Hiçbiri yoksa depodaki deneme anahtarı (android/deneme-imza). Yalnızca
//    telefona elle yüklenen deneme sürümleri içindir; şifresi depoda açık
//    olduğundan Google Play'e bununla yüklenmez.
val keyProps = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}

fun signingValue(prop: String, env: String): String? =
    keyProps.getProperty(prop) ?: System.getenv(env)?.takeIf { it.isNotBlank() }

val releaseStore = signingValue("storeFile", "BILEKLIK_KEYSTORE")

// Google Haritalar anahtarı depoya yazılmaz: android/key.properties içinde
// mapsApiKey=… ya da MAPS_API_KEY ortam değişkeni (GitHub Actions gizli
// değeri). Anahtar yoksa uygulama haritayı açmaz, kodla çizilmiş zemini
// gösterir (Dart tarafında --dart-define=GOOGLE_MAPS=true verilmez).
val mapsApiKey = signingValue("mapsApiKey", "MAPS_API_KEY") ?: ""

android {
    namespace = "com.bileklik.bileklik"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Google Play'e ilk yüklemeden sonra değiştirilemez.
        applicationId = "com.bileklik.bileklik"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // Health Connect (health eklentisi) Android 8.0 (API 26) ister.
        minSdk = maxOf(flutter.minSdkVersion, 26)
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["mapsApiKey"] = mapsApiKey
    }

    signingConfigs {
        create("release") {
            if (releaseStore != null) {
                storeFile = file(releaseStore)
                storePassword = signingValue("storePassword", "BILEKLIK_KEYSTORE_PASSWORD")
                keyAlias = signingValue("keyAlias", "BILEKLIK_KEY_ALIAS")
                keyPassword = signingValue("keyPassword", "BILEKLIK_KEY_PASSWORD")
            } else {
                storeFile = rootProject.file("deneme-imza/bileklik-deneme.p12")
                storeType = "pkcs12"
                storePassword = "bileklik-deneme"
                keyAlias = "bileklik-deneme"
                keyPassword = "bileklik-deneme"
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            // Kod küçültme şimdilik kapalı: JNI ile adıyla çağrılan eklenti
            // yöntemleri (shared_preferences 2.5+) R8'de siliniyor ve uygulama
            // açılmıyordu. Play'e çıkmadan önce kurallarla yeniden açılıp
            // telefonda denenecek.
            isMinifyEnabled = false
            isShrinkResources = false
            // Eklentilerin istediği R8 kuralları (küçültme açılınca).
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
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
