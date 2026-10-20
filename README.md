# ELEODES

Flutter app for monitoring and controlling an atmospheric water generator (AWG).
It uses Firebase Realtime Database for device readings and commands, Bluetooth
for Wi-Fi provisioning, and Open-Meteo for outdoor weather.

## Find the code

- **Start here:** [Project structure and debugging guide](docs/project-structure.md)
- **Weather and database fields:** [Weather history](docs/weather-history.md)

App code is in `lib/`; tests mirror the feature folders in `test/features/`.

## Run and check

From the project root:

```sh
flutter pub get
flutter run
flutter analyze
flutter test
```

Use a configured Firebase project and a real Android device to verify Bluetooth,
location permissions, phone notifications, and ESP32 control. Unit/widget tests
do not replace those hardware checks.

## Main folders

| Folder | Purpose |
| --- | --- |
| `lib/app/` | App theme selection, first launch, and main navigation |
| `lib/core/` | Shared theme and saved preferences |
| `lib/features/` | Screens, services, models, and widgets grouped by feature |
| `lib/shared/widgets/` | UI shared by multiple features |
| `test/features/` | Automated tests grouped by feature |
| `docs/` | Project notes and debugging guides |
| `assets/images/` | UI images and launcher artwork |
| `android/`, `ios/`, `web/`, `windows/`, `macos/`, `linux/` | Flutter platform projects |

`build/` and `.dart_tool/` are generated folders, not application source.
Use `flutter clean` if you need to clear generated build output.
