# HeHe

## Local setup

Runtime configuration is loaded from the ignored `env/dev.json` file at
compile time. Copy `env/example.json` to create a local environment, fill in
the Android client keys, and run the app with:

```sh
flutter run --dart-define-from-file=env/dev.json --dart-define=AUTH_DIAGNOSTICS=true
```

For Android Studio, add the following under **Run > Edit Configurations >
Additional run args**:

```text
--dart-define-from-file=env/dev.json --dart-define=AUTH_DIAGNOSTICS=true
```

Debug builds may run without the file, but maps and social login stay
unconfigured. Release builds fail fast when a required Android client key is
missing, preventing an unusable AAB from being uploaded.

## Android release

Release signing credentials live in the ignored `android/key.properties` file.
Build an internal-test bundle with safe OAuth error codes enabled:

```sh
flutter build appbundle --release \
  --dart-define-from-file=env/dev.json \
  --dart-define=AUTH_DIAGNOSTICS=true
```

For production, use a separate ignored environment file and leave
`AUTH_DIAGNOSTICS` false (the default):

```sh
flutter build appbundle --release --dart-define-from-file=env/release.json
```

`dart-define` values are compiled into the application. Only mobile client
configuration belongs in these files; backend-only secrets must never be put
in the app environment.
