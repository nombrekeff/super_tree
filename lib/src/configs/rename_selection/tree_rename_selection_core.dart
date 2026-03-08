import 'package:flutter/services.dart';
import 'package:super_tree/src/models/tree_node.dart';

/// Resolves the initial rename selection for a node label.
typedef TreeRenameSelectionResolver<T> = TextSelection Function(
  TreeNode<T> node,
  String currentText,
);

/// Strategy base class for initial rename text selection behavior.
abstract class TreeRenameSelectionStrategy<T> {
  const TreeRenameSelectionStrategy();

  /// Returns the initial text selection when rename starts for [node].
  TextSelection resolveSelection(TreeNode<T> node, String currentText);
}

/// Shared helpers to resolve and normalize rename selection values.
class TreeRenameSelectionCore {
  const TreeRenameSelectionCore._();

  /// Resolves the active strategy selection and sanitizes it for [currentText].
  static TextSelection resolveAndSanitize<T>({
    required TreeNode<T> node,
    required String currentText,
    required TreeRenameSelectionStrategy<T> strategy,
  }) {
    final TextSelection rawSelection = strategy.resolveSelection(
      node,
      currentText,
    );
    return sanitizeSelection(rawSelection, currentText.length);
  }

  /// Clamps a selection to valid offsets for the current text length.
  static TextSelection sanitizeSelection(
    TextSelection selection,
    int textLength,
  ) {
    final int safeBase = selection.baseOffset.clamp(0, textLength);
    final int safeExtent = selection.extentOffset.clamp(0, textLength);
    return TextSelection(baseOffset: safeBase, extentOffset: safeExtent);
  }
}
