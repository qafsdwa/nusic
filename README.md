# Muse Player

A cross-platform Material Design 3 music player client.

**Current status:** Phase 1 — project architecture, Mock UI and startup configuration only.
No real audio playback or backend calls are implemented yet.

## Stack

- Flutter 3.x / Dart
- Material Design 3
- `flutter_riverpod`
- Responsive desktop-first layout
- JSON asset configuration with startup initialization
- Future backend: Rust REST API + WebSocket

## Project structure

```text
assets/
└── config/
    └── app_config.json        # Startup configuration

lib/
├── main.dart                  # Bootstrap + ProviderScope
├── app/
│   ├── app.dart               # App root and responsive shell
│   ├── breakpoints.dart       # Mobile / Tablet / Desktop breakpoints
│   ├── theme.dart             # Light / dark Material 3 themes
│   └── router.dart            # Named routes
├── core/
│   ├── config/                # AppConfig / loader / provider / bootstrap
│   ├── constants/             # Sizes and navigation sections
│   ├── extensions/            # Context breakpoint helpers
│   ├── network/               # Rust API endpoint placeholders
│   └── utils/                 # Shared formatters
├── mock/
│   └── mock_music.dart        # Phase 1 mock data
├── models/                    # Song, Album, Playlist
├── providers/                 # Riverpod player and navigation providers
├── pages/                     # Home, Search, Library, Playlist, Now Playing
└── widgets/                   # Player, song, album, navigation, common widgets
```

## Configuration

The app loads `assets/config/app_config.json` before `runApp`:

```dart
final AppConfig config = await initializeApp();

runApp(
  ProviderScope(
    overrides: [appConfigProvider.overrideWithValue(config)],
    child: const MuseApp(),
  ),
);
```

Configuration includes app name, environment, mock/network flags, Rust backend
endpoints, initial player defaults and the Material 3 theme palette / theme mode. The loader falls back to `AppConfig.fallback`
if the asset is missing or malformed, so tests and local runs still work.

See [docs/configuration.md](docs/configuration.md) for all fields.
The Settings page also offers a runtime theme-mode toggle (`system` / `light` / `dark`).

## Run

```bash
flutter pub get
flutter run
```

## Check

```bash
dart format .
flutter analyze
flutter test
```
