import 'package:flutter/material.dart';

/// A single item representing an action in the [ContextMenuOverlay].
class ContextMenuItem {
  /// The visual representation of the menu item (e.g., Text, Icon).
  final Widget child;

  /// The action to perform when the item is tapped.
  final VoidCallback onTap;

  const ContextMenuItem({required this.child, required this.onTap});
}

/// A utility to display a platform-agnostic, customizable context menu
/// using Flutter's [Overlay] system.
class ContextMenuOverlay {
  static OverlayEntry? _currentEntry;

  static const double _defaultWidth = 200.0;
  static const double _menuViewportHeightFactor = 0.5;
  static const double _menuScreenPadding = 8.0;

  static OverlayEntry _buildEntry({
    required BuildContext context,
    required Offset position,
    required Widget child,
    required double width,
    required double estimatedHeight,
    VoidCallback? onDismissed,
  }) {
    return OverlayEntry(
      builder: (BuildContext overlayContext) {
        final Size screenSize = MediaQuery.of(overlayContext).size;
        double dx = position.dx;
        double dy = position.dy;

        if (dx + width > screenSize.width) {
          dx = screenSize.width - width - _menuScreenPadding;
        }
        if (dx < _menuScreenPadding) {
          dx = _menuScreenPadding;
        }

        if (dy + estimatedHeight > screenSize.height) {
          dy = screenSize.height - estimatedHeight - _menuScreenPadding;
        }
        if (dy < _menuScreenPadding) {
          dy = _menuScreenPadding;
        }

        return Stack(
          children: <Widget>[
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  hide();
                  onDismissed?.call();
                },
                onSecondaryTapDown: (_) {
                  hide();
                  onDismissed?.call();
                },
                child: const SizedBox.expand(),
              ),
            ),
            Positioned(left: dx, top: dy, child: child),
          ],
        );
      },
    );
  }

  /// Displays the context menu at a specific [position] on the screen.
  /// Click-away behavior is built-in.
  static void show({
    required BuildContext context,
    required Offset position,
    required List<ContextMenuItem> items,
    double width = _defaultWidth,
    VoidCallback? onDismissed,
  }) {
    hide(); // Dismiss existing if any

    final OverlayState overlayState = Overlay.of(context);
    final List<Widget> menuChildren = items.map((ContextMenuItem item) {
      return InkWell(
        onTap: () {
          hide();
          onDismissed?.call();
          item.onTap();
        },
        child: Container(
          width: double.infinity,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
          child: item.child,
        ),
      );
    }).toList();

    final Widget menuSurface = Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(6.0),
      color: Theme.of(context).cardColor,
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: width,
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.of(context).size.height * _menuViewportHeightFactor,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6.0),
          border: Border.all(
            color: Theme.of(context).dividerColor.withAlpha(25),
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          shrinkWrap: true,
          children: menuChildren,
        ),
      ),
    );

    _currentEntry = _buildEntry(
      context: context,
      position: position,
      child: menuSurface,
      width: width,
      estimatedHeight: items.length * 40.0 + 8.0,
      onDismissed: onDismissed,
    );

    overlayState.insert(_currentEntry!);
  }

  /// Displays a custom context-menu widget at a specific [position].
  ///
  /// Unlike [show], this does not auto-wrap children in action rows, so callers
  /// can provide any layout (e.g. `Column`, custom sections, toggles).
  static void showWidget({
    required BuildContext context,
    required Offset position,
    required Widget menu,
    double width = _defaultWidth,
    VoidCallback? onDismissed,
  }) {
    hide();

    final OverlayState overlayState = Overlay.of(context);

    final Widget menuSurface = Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(6.0),
      color: Theme.of(context).cardColor,
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: width,
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.of(context).size.height * _menuViewportHeightFactor,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6.0),
          border: Border.all(
            color: Theme.of(context).dividerColor.withAlpha(25),
          ),
        ),
        child: menu,
      ),
    );

    _currentEntry = _buildEntry(
      context: context,
      position: position,
      child: menuSurface,
      width: width,
      estimatedHeight: 240.0,
      onDismissed: onDismissed,
    );

    overlayState.insert(_currentEntry!);
  }

  /// Closes the currently completely open context menu.
  static void hide() {
    _currentEntry?.remove();
    _currentEntry = null;
  }
}
