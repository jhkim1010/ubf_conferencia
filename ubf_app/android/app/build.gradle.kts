import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// 릴리스 서명 설정.
//
// 예전에는 릴리스도 **디버그 키**로 서명했다. 디버그 키스토어는 기계마다
// 자동 생성되므로 SHA-1 이 빌드하는 곳마다 달라진다 — GitHub 러너는 매번
// 새로 만들어지니 빌드할 때마다 바뀐다. 구글 로그인은 패키지명 + SHA-1 로
// 앱을 식별하는데, 움직이는 지문은 콘솔에 등록할 수가 없다. 그래서 안드로이드
// 로그인이 sign_in_failed(ApiException: 10)로 계속 실패했다.
//
// key.properties 위치:
//   1) android/key.properties            (저장소 안 — gitignore 됨)
//   2) $UBF_KEY_PROPERTIES               (환경변수로 지정)
//   3) ~/.ubf-keys/key.properties        (기본. 저장소 밖에 둔다)
val keystoreProperties = Properties().apply {
    val candidates = listOfNotNull(
        rootProject.file("key.properties").takeIf { it.exists() },
        System.getenv("UBF_KEY_PROPERTIES")?.let { file(it) }?.takeIf { it.exists() },
        file("${System.getProperty("user.home")}/.ubf-keys/key.properties").takeIf { it.exists() },
    )
    candidates.firstOrNull()?.inputStream()?.use { load(it) }
}

android {
    namespace = "com.ubf.ubf_app"
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
        applicationId = "com.ubf.ubf_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystoreProperties.getProperty("storeFile") != null) {
            create("release") {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            val hasReleaseKey = signingConfigs.findByName("release") != null
            // 키가 없으면 **조용히 디버그로 되돌아가지 않는다.** 예전에 그렇게
            // 두었다가, 서명이 바뀐 줄 모른 채 배포한 APK 로 구글 로그인이
            // 막혔다. 실패는 빌드 시점에 드러나야 한다.
            //
            // flutter run --release 를 키 없이 돌려야 할 때만
            // -PallowDebugSigning=true 로 열어 준다.
            if (hasReleaseKey) {
                signingConfig = signingConfigs.getByName("release")
            } else if (project.hasProperty("allowDebugSigning")) {
                logger.warn("⚠ 릴리스를 디버그 키로 서명합니다. 배포용으로 쓰지 마십시오.")
                signingConfig = signingConfigs.getByName("debug")
            } else {
                throw GradleException(
                    "릴리스 서명 키가 없습니다. ~/.ubf-keys/key.properties 를 두거나 " +
                    "UBF_KEY_PROPERTIES 로 경로를 지정하십시오. " +
                    "(임시로 디버그 서명하려면 -PallowDebugSigning=true)"
                )
            }
        }
    }
}

flutter {
    source = "../.."
}
