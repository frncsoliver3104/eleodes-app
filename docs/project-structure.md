# Project structure and debugging

## Startup flow

1. `lib/main.dart`: initialize Flutter, pairing preferences, app settings,
   Firebase, and local notifications.
2. `lib/app/app.dart`: build the app and select light/dark mode.
3. `lib/app/startup_screen.dart`: check `termsAccepted` and open terms or the app.
4. `lib/features/legal/screens/terms_agreement_screen.dart`: accept terms.
5. `lib/app/main_screen.dart`: dashboard, devices, and settings tabs.

The active loading screen now lives in `app/startup_screen.dart`. The old,
unreferenced `lib/loading_screen.dart` was a separate duplicate and was removed.

## Where to debug

All paths in this table are relative to `lib/`.

| Problem or change | Start in |
| --- | --- |
| App initialization / Firebase startup | `main.dart`, `firebase_options.dart` |
| First-launch terms | `app/startup_screen.dart`, `features/legal/screens/terms_agreement_screen.dart` |
| Main tabs / bottom navigation | `app/main_screen.dart`, `app/widgets/dashboard_bottom_nav.dart` |
| Live readings / connection / Start-Stop / uptime | `features/dashboard/screens/dashboard_screen.dart` |
| Sensor reading data model | `features/dashboard/models/sensor_data.dart` |
| Tank animation | `features/dashboard/widgets/animated_water_tank.dart` |
| Dashboard notification bell | `features/dashboard/widgets/dashboard_topbar.dart` |
| Saved devices / Connected button | `features/devices/screens/devices_list_screen.dart` |
| Device ID and secret verification | `features/devices/screens/device_setup_screen.dart` |
| Wi-Fi setup screen | `features/devices/screens/wifi_connection_screen.dart` |
| Bluetooth communication | `features/devices/services/ble_wifi_provisioning_service.dart` |
| Saved pairing / forgetting device | `features/devices/services/device_pairing_store.dart` |
| Disconnect confirmation | `features/devices/widgets/device_disconnect_dialog.dart` |
| Notification feed / mark as read | `features/notifications/screens/notification_screen.dart` |
| Unread/read card colors | `features/notifications/widgets/notification_card.dart` |
| Saving notifications / phone pop-ups / cooldowns | `features/notifications/services/notification_service.dart` |
| Sensor alert thresholds | `features/notifications/services/sensor_alert_evaluator.dart` |
| Production history section | `features/production/widgets/production_history_section.dart` |
| Daily/weekly table and totals | `features/production/widgets/production_comparison.dart` |
| Current location / refresh weather buttons | `features/production/widgets/weather_production_history.dart` |
| Open-Meteo fetching and parsing | `features/production/services/weather_history_service.dart` |
| Settings switches and links | `features/settings/screens/settings_screen.dart` |
| Saved preferences / Notification switch | `core/settings/app_settings.dart` |
| Colors / dark mode | `core/theme/app_theme.dart` |
| Privacy policy / terms text | `features/legal/screens/` |
| Shared page headings | `shared/widgets/tab_header.dart` |

## Folder conventions

- `screens/`: full pages and their UI state.
- `widgets/`: smaller UI components owned by that feature.
- `services/`: device communication, storage, API access, or alert logic.
- `models/`: data objects.
- Shared code belongs in `core/` or `shared/`; feature-specific code stays
  inside its feature.
- Internal imports use `package:ELEODES/...` so the location is clear.
- Put new tests in `test/features/<feature>/`.

## Checks

Run all tests with `flutter test`, or one feature with:

```sh
flutter test test/features/devices
flutter test test/features/notifications
flutter analyze
```

Hardware-dependent flows still need testing with the ESP32 and phone.
The source tree contains no ESP32 firmware. Daily production is written by
the ESP32/backend; the Flutter app reads `AWG/productionByDate`.
See [weather-history.md](weather-history.md) for the database fields.

## Cleanup record

The following Dart files had no import/export path from `lib/main.dart` or
any test and were removed:

| Old path | Reason |
| --- | --- |
| `lib/AWGsetup.dart` | Unused setup screen; active setup is in the devices feature |
| `lib/home.dart` | Duplicate, unused main navigation |
| `lib/loading_screen.dart` | Duplicate, unused startup/navigation implementation |
| `lib/firebase_service.dart` | Unused legacy service; active Firebase readers are in feature code |
| `lib/widgets/bottom_nav.dart` | Unused alternative navigation widget |
| `lib/widgets/dashboard_card.dart` | Unused card widget |
| `lib/models/notification_model.dart` | Empty file |

Also removed the empty root file `cdcd` and generated crash log `flutter_01.log`.
Platform projects, Firebase configuration, artwork, and IDE settings were kept.
Generated build/cache folders remain ignored by Git.

## Existing configuration items to check

- The startup screen references `assets/images/Logo.png`, which is absent.
  Its existing fallback icon is displayed instead.
- Launcher icon configuration references
  `assets/images/eleodes_launcher_foreground.png`, which is absent.
  Supply the intended artwork before regenerating launcher icons.
- Startup currently opens the main screen if loading the acceptance preference
  throws an error. This existing behavior was preserved during organization.


## Low-water notification

The app checks the ESP32's percentage at `AWG/live/waterLevel`. If the ESP32
derives that percentage from an ultrasonic sensor, this alert uses that reading;
the app does not convert raw ultrasonic distance to percentage.

- Alert at 20% or below; rearm only after a valid reading above 25%.
- Require Notification to be enabled and the device to be online.
- Ignore missing, non-finite, and out-of-range values.
- Suppress low-water alerts when the device reports the tank is full.
- Use the existing notification feed and phone pop-up service. Existing unread
  duplicate suppression still applies.
- Evaluation runs through the dashboard's live-data handling; this is not a
  standalone backend alert that is guaranteed to run when the app is closed.

Implementation: `lib/features/notifications/services/sensor_alert_evaluator.dart`.
Tests: `test/features/notifications/sensor_alert_evaluator_test.dart`.