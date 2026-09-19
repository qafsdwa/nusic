import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';

/// Read-only search field that opens the Search route when tapped.
///
/// Shared by the desktop title bar and the non-desktop home header so the two
/// entry points stay the same control. Both are deliberately read-only: the
/// Search page owns the query state, and a live field here would mean
/// duplicating that state in the shell.
class SearchLauncherField extends StatelessWidget {
  const SearchLauncherField({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.searchFieldHeight,
      child: TextField(
        onTap: onTap,
        readOnly: true,
        // No explicit fill: this field and the Search page's field must read as
        // the same control, so both take `inputDecorationTheme`.
        decoration: const InputDecoration(
          hintText: '搜索歌曲、专辑、歌手或歌单',
          prefixIcon: Icon(Icons.search),
        ),
      ),
    );
  }
}
