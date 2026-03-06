import 'package:flutter/material.dart';

/// A single item representing an action in the [ContextMenuOverlay].
class ContextMenuItem {
  /// The visual representation of the menu item (e.g., Text, Icon).
  final Widget child;

  /// The action to perform when the item is tapped.
  final VoidCallback onTap;

  const ContextMenuItem({
    required this.child,
    required this.onTap,
  });
}

/// A utility to display a platform-agnostic, customizable context menu
/// using Flutter's [Overlay] system.
class ContextMenuOverlay {
  static OverlayEntry? _currentEntry;

  /// Displays the context menu at a specific [position] on the screen.
  /// Click-away behavior is built-in.
  static void show({
    required BuildContext context,
    required Offset position,
    required List<ContextMenuItem> items,
    double width = 200.0,
  }) {
    hide(); // Dismiss existing if any

    final OverlayState overlayState = Overlay.of(context);

    _currentEntry = OverlayEntry(
      builder: (BuildContext context) {
        final Size screenSize = MediaQuery.of(context).size;
        
        // Simple bounds checking to prevent menu from rendering off-screen
        double dx = position.dx;
        double dy = position.dy;

        // Estimate height: approx 40px per item + padding
        final double estimatedHeight = items.length * 40.0 + 8.0;

        if (dx + width > screenSize.width) {
          dx = screenSize.width - width - 8.0;
        }
        if (dy + estimatedHeight > screenSize.height) {
          dy = screenSize.height - estimatedHeight - 8.0;
        }

        return Stack(
          children: [
            // Invisible barrier to catch taps outside the context menu
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: hide,
                onSecondaryTapDown: (_) => hide(),
                child: const SizedBox.expand(),
              ),
            ),
            // The Context Menu Surface
            Positioned(
              left: dx,
              top: dy,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(6.0),
                color: Theme.of(context).cardColor,
                clipBehavior: Clip.antiAlias,
                child: Container(
                  width: width,
                  constraints: BoxConstraints(
                    maxHeight: screenSize.height * 0.5, // 50% max height
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
                    children: items.map((item) {
                      return InkWell(
                        onTap: () {
                          hide();
                          item.onTap();
                        },
                        child: Container(
                          width: double.infinity,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(
                            vertical: 10.0,
                            horizontal: 16.0,
                          ),
                          child: item.child,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    overlayState.insert(_currentEntry!);
  }

  /// Closes the currently completely open context menu.
  static void hide() {
    _currentEntry?.remove();
    _currentEntry = null;
  }
}
