import 'package:flutter/material.dart';

/// Generated mock cover artwork.
///
/// Phase 1 uses deterministic gradients/initial letters so the UI is complete
/// without external image assets or network calls. When real cover URLs arrive
/// from the Rust backend, this widget can be extended to render an
/// [Image.network]/[Image.asset] while keeping the placeholder fallback.
class CoverArtwork extends StatelessWidget {
  const CoverArtwork({
    super.key,
    required this.title,
    this.coverKey = '',
    this.size = 48,
    this.borderRadius = 8,
  });

  final String title;
  final String coverKey;
  final double size;
  final double borderRadius;

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
    final String seed = '$coverKey|$title';
    final int colorIndex = seed.hashCode.abs() % _palettes.length;
    final List<Color> colors = _palettes[colorIndex];
    final String initial = title.isEmpty
        ? '♪'
        : String.fromCharCode(title.runes.first).toUpperCase();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.36,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
