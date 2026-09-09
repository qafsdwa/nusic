# Muse Player

A cross-platform Material Design 3 music player client.

**Current status:** Phase 1 — project architecture and Mock UI only. No real audio playback or backend calls are implemented yet.

## Stack

- Flutter 3.x / Dart
- Material Design 3
- Riverpod state management
- Responsive Desktop-first layout (Android / iOS compatible)
- Future backend: Rust REST API + WebSocket

## Project structure

```text
lib/
├── main.dart
├── app/
│   ├── app.dart       # App root and responsive shell
│   ├── theme.dart     # Light / dark Material 3 themes
│   └── router.dart    # Named routes and route table
├── core/
│   ├── constants/     # Sizes, navigation sections, mock data
│   ├── network/       # Rust API endpoint placeholders
│   └── utils/         # Shared formatters
├── models/            # Song, Album
├── providers/         # Riverpod player provider
├── pages/             # Home, Search, Library, Now Playing, placeholders
└── widgets/           # MiniPlayer, SongTile, AlbumCard, Navigation, CoverArtwork
```

## Run

```bash
flutter pub get
flutter run
```

## Analyzer

```bash
flutter analyze
```
