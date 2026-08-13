import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // NB: o plugin com.google.gms.google-services NÃO é aplicado aqui de propósito.
    // O CarLog inicializa o Firebase por FirebaseOptions explícitas (firebase_options.dart),
    // então não depende do google-services.json em tempo de build. Ao provisionar o
    // Firebase (FIREBASE.md), pode-se manter assim (padrão FlutterFire moderno).
}

// Assinatura de release (chave de upload). Vem de android/key.properties, que
// fica fora do Git. Sem esse arquivo, o release cai na assinatura DEBUG (para
// `flutter run --release` e o CI funcionarem antes de termos a keystore). Manter
// a MESMA chave garante que o app atualize por cima sem "conflito" e sem apagar
// os dados locais.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.vinyapps.carlog"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Exigido pelo flutter_local_notifications (usa APIs java.time).
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.vinyapps.carlog"
        minSdk = 23 // Firebase Auth exige minSdk 23 (Android 6.0+)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Assina com a chave de upload quando key.properties existe (CI com
            // keystore); senão cai no debug para o build funcionar mesmo assim.
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            // R8/minify com as regras do proguard-rules.pro (necessárias para o
            // ML Kit — ignora os reconhecedores de idiomas que não usamos).
            isMinifyEnabled = true
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

dependencies {
    // Necessário para o desugaring das APIs java.time (flutter_local_notifications).
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
