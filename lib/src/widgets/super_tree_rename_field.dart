import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Inline text editor used when a tree node enters rename mode.
class SuperTreeRenameField extends StatelessWidget {
  const SuperTreeRenameField({
    super.key,
    required this.controller,
    required this.textFieldFocusNode,
    required this.keyboardFocusNode,
    required this.style,
    required this.selectionColor,
    required this.cursorColor,
    required this.onEscape,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode textFieldFocusNode;
  final FocusNode keyboardFocusNode;
  final TextStyle? style;
  final Color selectionColor;
  final Color cursorColor;
  final VoidCallback onEscape;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextSelectionTheme(
      data: TextSelectionThemeData(
        selectionColor: selectionColor,
        cursorColor: cursorColor,
      ),
      child: KeyboardListener(
        focusNode: keyboardFocusNode,
        onKeyEvent: (KeyEvent event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.escape) {
            onEscape();
          }
        },
        child: TextField(
          controller: controller,
          focusNode: textFieldFocusNode,
          autofocus: true,
          style: style,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.zero,
            border: InputBorder.none,
          ),
          onSubmitted: (_) => onSubmitted(),
          onTapOutside: (_) => onSubmitted(),
        ),
      ),
    );
  }
}
