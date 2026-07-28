# Walkthrough - Android Release Configuration

I have successfully configured your Flutter app for release signing.

## Changes Made

### 1. Keystore Generation
I generated a release keystore at [upload-keystore.jks](file:///D:/Flutter_Portfolio/flutter_portfolio-1/android/app/upload-keystore.jks).
- **Alias**: `upload`
- **Password**: `password` (You should change this for production).

### 2. Signing Configuration
I created [key.properties](file:///D:/Flutter_Portfolio/flutter_portfolio-1/android/key.properties) to store the keystore credentials and updated [build.gradle.kts](file:///D:/Flutter_Portfolio/flutter_portfolio-1/android/app/build.gradle.kts) to load them automatically during the release build.

```kotlin
// Added to android/app/build.gradle.kts
signingConfigs {
    create("release") {
        keyAlias = keystoreProperties["keyAlias"] as String
        keyPassword = keystoreProperties["keyPassword"] as String
        storeFile = keystoreProperties["storeFile"]?.let { file(it) }
        storePassword = keystoreProperties["storePassword"] as String
    }
}
```

## Next Steps for You

To finish generating the APK, please perform the following steps:

1.  **Accept Android Licenses**: Run the following command in your terminal and accept all licenses:
    ```bash
    flutter doctor --android-licenses
    ```
2.  **Enable Developer Mode**: On Windows, go to **Settings > System > For developers** and toggle **Developer Mode** to **On**. This is required for Flutter to create symlinks during the build process.
3.  **Build the APK**: Run the build command:
    ```bash
    flutter build apk --release
    ```

The generated APK will be located at `build/app/outputs/flutter-apk/app-release.apk`.
