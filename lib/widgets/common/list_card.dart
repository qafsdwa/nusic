import 'package:flutter/material.dart';

/// Rounded card that stacks rows onto a single clipped surface.
///
/// Used wherever a list of tiles should read as one panel rather than as
/// separate cards — the library and playlist track lists, and the artist list.
class ListCard extends StatelessWidget {
  const ListCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}
