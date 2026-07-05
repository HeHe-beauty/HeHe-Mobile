# HeHe

## Local setup

Social login credentials are loaded from the ignored `env/dev.json` file at
compile time. Run the app with:

```sh
flutter run --dart-define-from-file=env/dev.json
```

For Android Studio, add the following under **Run > Edit Configurations >
Additional run args**:

```text
--dart-define-from-file=env/dev.json
```

Running without this option intentionally leaves Kakao and Naver login
unconfigured.

## Android release

Release signing credentials live in the ignored `android/key.properties` file.
Build the signed app bundle with:

```sh
flutter build appbundle --release --dart-define-from-file=env/dev.json
```
