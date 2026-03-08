import 'package:flutter/material.dart';

/// Small reusable icon button used by inline tree controls.
class SuperTreeIconButton extends StatelessWidget {
  const SuperTreeIconButton({
    super.key,
    this.buttonKey,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.buttonSize = 18,
    this.iconSize = 14,
  });

  final Key? buttonKey;
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double buttonSize;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final BoxConstraints compactConstraints = BoxConstraints(
      minWidth: buttonSize,
      minHeight: buttonSize,
    );

    return IconButton(
      key: buttonKey,
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      constraints: compactConstraints,
      splashRadius: buttonSize / 2,
      visualDensity: VisualDensity.compact,
      iconSize: iconSize,
      onPressed: onPressed,
      icon: Icon(icon),
    );
  }
}
