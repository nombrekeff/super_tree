import 'package:flutter/services.dart';
import 'package:super_tree/src/configs/rename_selection/tree_rename_selection_core.dart';
import 'package:super_tree/src/models/tree_node.dart';

class _TreeSelectAllRenameSelectionStrategy<T>
    extends TreeRenameSelectionStrategy<T> {
  const _TreeSelectAllRenameSelectionStrategy();

  @override
  TextSelection resolveSelection(TreeNode<T> node, String currentText) {
    return TextSelection(baseOffset: 0, extentOffset: currentText.length);
  }
}

class _TreeSelectFileNameRenameSelectionStrategy<T>
    extends TreeRenameSelectionStrategy<T> {
  const _TreeSelectFileNameRenameSelectionStrategy();

  @override
  TextSelection resolveSelection(TreeNode<T> node, String currentText) {
    final int lastDotIndex = currentText.lastIndexOf('.');
    final bool hasUsableExtensionSeparator =
        lastDotIndex > 0 && lastDotIndex < currentText.length - 1;

    if (!hasUsableExtensionSeparator) {
      return TextSelection(baseOffset: 0, extentOffset: currentText.length);
    }

    return TextSelection(baseOffset: 0, extentOffset: lastDotIndex);
  }
}

class _TreeCaretAtEndRenameSelectionStrategy<T>
    extends TreeRenameSelectionStrategy<T> {
  const _TreeCaretAtEndRenameSelectionStrategy();

  @override
  TextSelection resolveSelection(TreeNode<T> node, String currentText) {
    return TextSelection.collapsed(offset: currentText.length);
  }
}

class _TreeCustomRenameSelectionStrategy<T>
    extends TreeRenameSelectionStrategy<T> {
  final TreeRenameSelectionResolver<T> resolver;

  const _TreeCustomRenameSelectionStrategy(this.resolver);

  @override
  TextSelection resolveSelection(TreeNode<T> node, String currentText) {
    return resolver(node, currentText);
  }
}

/// Prebuilt rename selection strategies.
class TreeRenameSelectionStrategies {
  const TreeRenameSelectionStrategies._();

  /// Selects the full node label.
  static TreeRenameSelectionStrategy<T> selectAll<T>() {
    return _TreeSelectAllRenameSelectionStrategy<T>();
  }

  /// Selects the file-name stem before the final extension separator.
  static TreeRenameSelectionStrategy<T> selectFileName<T>() {
    return _TreeSelectFileNameRenameSelectionStrategy<T>();
  }

  /// Places the caret at the end without selecting text.
  static TreeRenameSelectionStrategy<T> caretAtEnd<T>() {
    return _TreeCaretAtEndRenameSelectionStrategy<T>();
  }

  /// Uses a custom callback strategy.
  static TreeRenameSelectionStrategy<T> custom<T>(
    TreeRenameSelectionResolver<T> resolver,
  ) {
    return _TreeCustomRenameSelectionStrategy<T>(resolver);
  }
}
