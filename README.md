# Muse Player

A cross-platform Material Design 3 music player client.

**Current status:** Phase 3 — the Rust engine (real `rodio` playback), the
Flutter bridge for it, and Bilibili online search / playback are all
implemented. The app calls Rust **in-process** through `flutter_rust_bridge`:
no HTTP, no WebSocket, no JSON round trip. If the native library cannot be
loaded it falls back to the built-in mock player instead of failing.

Not yet wired: the library and playlist pages still read `MockMusic` directly,
queue editing has no bridge command yet, and the Rust crate still also carries
an unused-by-the-app HTTP/WS front-end.

## Stack

- Flutter 3.x / Dart
- Material Design 3
- `flutter_riverpod`
- `window_manager` for desktop custom title bar
- Responsive desktop-first layout
- JSON asset configuration with startup initialization
- Rust backend: REST API + WebSocket (`rust/backend/`, implemented)
- `flutter_rust_bridge` data contract for the in-process bridge (`rust/`)
- `bpi-rs` for Bilibili online search and DASH audio tracks (`rust/backend/src/online.rs`)

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
│   ├── window/                # Desktop window setup + custom title bar switch
│   └── utils/                 # Shared formatters
├── core/bridge/              # flutter_rust_bridge DTO contract + mapper
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
See [docs/rust-bridge.md](docs/rust-bridge.md) for the Flutter ↔ Rust data contract.
See [docs/backend-api.md](docs/backend-api.md) for the Rust REST / WebSocket API.
The Settings page also offers a runtime theme-mode toggle (`system` / `light` / `dark`).

## Run

```bash
flutter pub get
flutter run
```

On Windows / Linux / macOS the native title bar is hidden and replaced by
`CustomTitleBar` with drag, minimize, maximize and close controls.

### Rust backend

The REST + WebSocket server lives in `rust/backend/` and runs standalone:

```bash
cd rust/backend
cargo run              # http://127.0.0.1:8080
```

Point it at a music folder to serve and play real files instead of the built-in
seed catalog (which streams silent placeholders of the right length):

```bash
MUSE_MUSIC_DIR=~/Music cargo run
```

Playback uses `rodio`/`cpal`; on Linux that needs `libasound2-dev`. Machines
without a sound card degrade to a virtual playhead instead of failing:

```bash
MUSE_AUDIO=silent cargo run
```

The app does not call these: it links the crate and calls it directly through
`flutter_rust_bridge` (`lib/core/bridge/`). The endpoints remain for other
clients, and the contract is in [docs/backend-api.md](docs/backend-api.md).

### Online (Bilibili)

The search page can search Bilibili as well as the local catalog. A hit is a
video; what plays is its **DASH audio track**, which Rust resolves and downloads
into a cache on first play, then hands to the player as a normal file.

Anonymous access already returns the standard audio tracks. A cookie unlocks the
higher tiers — it is read from the environment, never stored by the app:

```bash
MUSE_BILI_COOKIE="SESSDATA=...; bili_jct=..." flutter run   # or BPI_COOKIE
MUSE_CACHE_DIR=~/Music/.muse-cache flutter run              # override the cache
```

Online tracks never join the local catalog, the playlist or the local search;
they are resolvable by id (`bili_<BV>`) for the duration of the session.
Details are in [docs/rust-bridge.md](docs/rust-bridge.md).

Generate the bindings after changing the Rust API:

```bash
flutter_rust_bridge_codegen generate
flutter test test/frb_bridge_test.dart   # exercises the real cdylib
```

```bash
cd rust/backend
cargo test             # unit + REST / WebSocket / library-scan integration tests
cargo clippy --all-targets
```

## Check

```bash
dart format .
flutter analyze
flutter test
```
