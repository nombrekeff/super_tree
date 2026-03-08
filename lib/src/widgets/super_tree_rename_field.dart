import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:super_tree/src/widgets/super_tree_icon_button.dart';

/// Inline text editor used when a tree node enters rename mode.
class SuperTreeRenameField extends StatelessWidget {
  static const double _submitIconButtonSize = 18;
  static const double _renameActionSpacing = 2;

  const SuperTreeRenameField({
    super.key,
    required this.controller,
    required this.textFieldFocusNode,
    required this.keyboardFocusNode,
    required this.style,
    required this.selectionColor,
    required this.cursorColor,
    required this.onEscape,
    required this.onCanceled,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode textFieldFocusNode;
  final FocusNode keyboardFocusNode;
  final TextStyle? style;
  final Color selectionColor;
  final Color cursorColor;
  final VoidCallback onEscape;
  final VoidCallback onCanceled;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextSelectionTheme(
      data: TextSelectionThemeData(selectionColor: selectionColor, cursorColor: cursorColor),
      child: KeyboardListener(
        focusNode: keyboardFocusNode,
        onKeyEvent: (KeyEvent event) {
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
            onEscape();
          }
        },
        child: TextFieldTapRegion(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: textFieldFocusNode,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  style: style,
                  maxLines: 1,
                  decoration: const InputDecoration(
                    isCollapsed: true,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                  onEditingComplete: () {},
                  onSubmitted: (_) => onSubmitted(),
                  onTapOutside: (_) => onCanceled(),
                ),
              ),
              const SizedBox(width: 4),
              SuperTreeIconButton(
                key: const Key('super_tree_rename_submit_button'),
                buttonKey: const Key('super_tree_rename_submit_button_inner'),
                icon: Icons.check,
                onPressed: onSubmitted,
                tooltip: 'Submit',
                buttonSize: _submitIconButtonSize,
              ),
              const SizedBox(width: _renameActionSpacing),
              SuperTreeIconButton(
                key: const Key('super_tree_rename_cancel_button'),
                buttonKey: const Key('super_tree_rename_cancel_button_inner'),
                icon: Icons.close,
                onPressed: onCanceled,
                tooltip: 'Cancel',
                buttonSize: _submitIconButtonSize,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
