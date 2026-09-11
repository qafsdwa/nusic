import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Riverpod state for the selected shell destination.
///
/// Kept separate from the player state so the active page can be changed from
/// deep links, search shortcuts, or the future Rust backend without plumbing
/// callbacks through the widget tree.
class NavigationNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) {
    state = index;
  }
}

final navigationProvider = NotifierProvider<NavigationNotifier, int>(
  NavigationNotifier.new,
);
