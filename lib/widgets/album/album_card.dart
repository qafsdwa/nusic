import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/utils/motion.dart';
import '../../models/album.dart';
import '../common/cover_artwork.dart';

/// A square album card used in Library and Browse grids.
class AlbumCard extends StatefulWidget {
  const AlbumCard({
    super.key,
    required this.album,
    this.width = 160,
    this.onTap,
  });

  final Album album;
  final double width;
  final VoidCallback? onTap;

  @override
  State<AlbumCard> createState() => _AlbumCardState();
}

class _AlbumCardState extends State<AlbumCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    // A card with no destination must not pretend to be a button: no hover
    // lift, no ripple, no pointer cursor.
    final bool interactive = widget.onTap != null;

    return SizedBox(
      width: widget.width,
      child: MouseRegion(
        cursor: interactive ? SystemMouseCursors.click : MouseCursor.defer,
        onEnter: interactive ? (_) => setState(() => _hovered = true) : null,
        onExit: interactive ? (_) => setState(() => _hovered = false) : null,
        child: AnimatedScale(
          scale: interactive && _hovered ? 1.02 : 1.0,
          duration: AppMotion.of(context, AppMotion.fast),
          curve: Curves.easeOut,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(AppSizes.shapeLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                CoverArtwork(
                  title: widget.album.title,
                  coverKey: widget.album.cover,
                  size: widget.width,
                  borderRadius: AppSizes.shapeLg,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.album.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.album.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
