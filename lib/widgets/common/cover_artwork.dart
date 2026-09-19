import 'package:flutter/material.dart';

import 'generated_artwork.dart';

/// How a [CoverArtwork] renders its cover.
enum CoverArtworkStyle {
  /// Generated illustrative scene. The default: it is what the app's design
  /// uses everywhere, so a list of songs reads as a wall of artwork rather than
  /// a column of coloured squares.
  scene,

  /// Generated gradient with the title's first character. Reserved for places
  /// where the artwork is too small for a scene to resolve — anything under
  /// roughly 32dp.
  monogram,
}

/// Generated mock cover artwork.
///
/// Phase 1 uses deterministic gradients and scenes so the UI is complete
/// without external image assets or network calls. When real cover URLs arrive
/// from the Rust backend, this widget can be extended to render an
/// [Image.network]/[Image.asset] while keeping the generated fallback.
class CoverArtwork extends StatelessWidget {
  const CoverArtwork({
    super.key,
    required this.title,
    this.coverKey = '',
    this.size = 48,
    this.borderRadius = 8,
    this.style = CoverArtworkStyle.scene,
  });

  final String title;
  final String coverKey;
  final double size;
  final double borderRadius;
  final CoverArtworkStyle style;

  /// Smallest size at which a scene still reads as a picture rather than as
  /// noise. Below it [CoverArtworkStyle.scene] silently degrades to a monogram.
  static const double _sceneMinSize = 32;

  @override
  Widget build(BuildContext context) {
    final bool useScene =
        style == CoverArtworkStyle.scene && size >= _sceneMinSize;
    final String seed = '$coverKey|$title';

    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: useScene
            ? GeneratedArtwork(seedKey: seed)
            : _Monogram(title: title, seed: seed, size: size),
      ),
    );
  }
}

/// Gradient tile with the title's first character.
class _Monogram extends StatelessWidget {
  const _Monogram({
    required this.title,
    required this.seed,
    required this.size,
  });

  final String title;
  final String seed;
  final double size;

  static const List<List<Color>> _palettes = <List<Color>>[
    <Color>[Color(0xFF667EEA), Color(0xFF764BA2)],
    <Color>[Color(0xFFF093FB), Color(0xFFF5576C)],
    <Color>[Color(0xFF4FACFE), Color(0xFF00F2FE)],
    <Color>[Color(0xFF43E97B), Color(0xFF38F9D7)],
    <Color>[Color(0xFFFA709A), Color(0xFFFEE140)],
    <Color>[Color(0xFF30CFD0), Color(0xFF330867)],
  ];

  @override
  Widget build(BuildContext context) {
    final List<Color> colors =
        _palettes[stableArtworkHash(seed) % _palettes.length];
    final String initial = title.isEmpty
        ? '♪'
        : String.fromCharCode(title.runes.first).toUpperCase();

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.36,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
