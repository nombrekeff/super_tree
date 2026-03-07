import 'package:flutter/material.dart';

/// Shared interaction shell for the tree view: focus, shortcuts and pointer gestures.
class SuperTreeInteractionSurface extends StatelessWidget {
  const SuperTreeInteractionSurface({
    super.key,
    required this.focusNode,
    required this.shortcuts,
    required this.actions,
    required this.onRequestFocus,
    required this.onBackgroundTap,
    required this.onOpenContextMenu,
    required this.child,
  });

  final FocusNode focusNode;
  final Map<ShortcutActivator, Intent> shortcuts;
  final Map<Type, Action<Intent>> actions;
  final VoidCallback onRequestFocus;
  final VoidCallback onBackgroundTap;
  final ValueChanged<Offset> onOpenContextMenu;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onRequestFocus(),
      onTap: onBackgroundTap,
      onSecondaryTapDown: (TapDownDetails details) {
        onOpenContextMenu(details.globalPosition);
      },
      onLongPressStart: (LongPressStartDetails details) {
        onOpenContextMenu(details.globalPosition);
      },
      behavior: HitTestBehavior.opaque,
      child: FocusableActionDetector(
        focusNode: focusNode,
        autofocus: true,
        shortcuts: shortcuts,
        actions: actions,
        child: child,
      ),
    );
  }
}
