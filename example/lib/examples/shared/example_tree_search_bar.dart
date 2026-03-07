import 'package:flutter/material.dart';

/// Reusable search bar used by example screens.
class ExampleTreeSearchBar extends StatelessWidget {
  const ExampleTreeSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClose,
    required this.hasQuery,
    required this.hintText,
    required this.clearLabel,
    required this.closeTooltip,
    this.hideBorder = false,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;
  final bool hasQuery;
  final String hintText;
  final String clearLabel;
  final String closeTooltip;
  final bool hideBorder;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color borderColor = isDark ? Colors.white12 : Colors.black12;

    final Widget trailing = hasQuery
        ? TextButton(
            onPressed: onClose,
            child: Text(clearLabel),
          )
        : IconButton(
            icon: const Icon(Icons.close),
            tooltip: closeTooltip,
            onPressed: onClose,
          );

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface.withAlpha(220) : theme.colorScheme.surface,
        border: hideBorder
            ? null
            : Border(
                bottom: BorderSide(color: borderColor),
              ),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.search),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: hintText,
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
