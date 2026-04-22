# dkjj_flutter_app

Flutter mobile client scaffold for `dkjj-ui` + `dkjj-admin`.

## Multi environment startup

Project supports three entrypoints:

- `lib/main_dev.dart`
- `lib/main_test.dart`
- `lib/main_prod.dart`

Native flavor names:

- `dev`
- `test`
- `prod`

Default environment mapping:

- `dev` -> `http://10.0.2.2:48080/admin-api`
- `test` -> `http://10.0.2.2:48080/admin-api`
- `prod` -> `http://10.0.2.2:48080/admin-api`

## Run examples

```bash
# dev
flutter run --flavor dev -t lib/main_dev.dart

# test
flutter run --flavor qa -t lib/main_test.dart

# prod
flutter run --flavor prod -t lib/main_prod.dart
```

## Startup params (dart-define)

You can override app name and API address via startup params.

```bash
# global override (works for any env entrypoint)
flutter run -t lib/main_dev.dart \
  --dart-define=APP_NAME=DKJJ-Mobile-Local \
  --dart-define=API_BASE_URL=http://192.168.1.20:48080/admin-api
```

Also supports env-specific defines:

```bash
--dart-define=APP_NAME_DEV=DKJJ Dev
--dart-define=APP_NAME_TEST=DKJJ Test
--dart-define=APP_NAME_PROD=DKJJ
--dart-define=API_BASE_URL_DEV=http://10.0.2.2:48080/admin-api
--dart-define=API_BASE_URL_TEST=https://test.example.com/admin-api
--dart-define=API_BASE_URL_PROD=https://prod.example.com/admin-api
```

## Android flavor signing

`android/app/build.gradle.kts` already supports per-flavor signing:

- `dev` -> `android/key_dev.properties`
- `test` -> `android/key_test.properties`
- `prod` -> `android/key_prod.properties`

You can create from templates:

- `android/key_dev.properties.example`
- `android/key_test.properties.example`
- `android/key_prod.properties.example`

Build examples:

```bash
flutter build apk --flavor dev -t lib/main_dev.dart
flutter build apk --flavor qa -t lib/main_test.dart
flutter build apk --flavor prod -t lib/main_prod.dart
```

## iOS flavor setup

iOS flavor schemes are added:

- `dev` scheme -> `Debug-dev / Profile-dev / Release-dev`
- `test` scheme -> `Debug-test / Profile-test / Release-test`
- `prod` scheme -> `Debug-prod / Profile-prod / Release-prod`

Environment config files:

- `ios/Flutter/Env/dev.xcconfig`
- `ios/Flutter/Env/test.xcconfig`
- `ios/Flutter/Env/prod.xcconfig`

App icons are split:

- `AppIcon-dev`
- `AppIcon-test`
- `AppIcon-prod`

iOS build examples (on macOS):

```bash
flutter build ios --flavor dev -t lib/main_dev.dart
flutter build ios --flavor test -t lib/main_test.dart
flutter build ios --flavor prod -t lib/main_prod.dart
```
