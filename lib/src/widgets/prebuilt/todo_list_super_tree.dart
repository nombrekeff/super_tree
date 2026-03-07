import 'package:flutter/material.dart';
import 'package:super_tree/src/configs/tree_view_logic.dart';
import 'package:super_tree/src/configs/tree_view_style.dart';
import 'package:super_tree/src/controllers/tree_controller.dart';
import 'package:super_tree/src/models/prebuilt/todo_item.dart';
import 'package:super_tree/src/models/tree_node.dart';
import 'package:super_tree/src/widgets/context_menu_overlay.dart';
import 'package:super_tree/src/widgets/super_tree_view.dart';
import 'package:super_tree/src/widgets/tree_highlighted_label.dart';

/// A convenience widget that wraps [SuperTreeView] specifically configured for [TodoItem]s.
/// It provides a checkbox out-of-the-box and sorts uncompleted items first by default.
class TodoListSuperTree extends StatelessWidget {
  final TreeController<TodoItem>? controller;
  final List<TreeNode<TodoItem>>? roots;
  
  /// Sort comparator. Defaults to uncompleted first, then alphabetical.
  final int Function(TreeNode<TodoItem> a, TreeNode<TodoItem> b)? sortComparator;
  
  final TreeViewStyle style;
  final TreeViewConfig<TodoItem> logic;
  
  final void Function(TodoItem item)? onTodoChanged;

  /// Optional builder overrides.
  final Widget Function(BuildContext, TreeNode<TodoItem>)? prefixBuilder;
  final Widget Function(BuildContext context, TreeNode<TodoItem> node, Widget? renameField)? contentBuilder;
  final Widget Function(BuildContext, TreeNode<TodoItem>)? trailingBuilder;
  
  /// Optional function called when right-clicking (desktop) or long-pressing (mobile) a node.
  final List<ContextMenuItem> Function(BuildContext, TreeNode<TodoItem>)? contextMenuBuilder;
  final ScrollController? scrollController;
  final ScrollPhysics? physics;

  const TodoListSuperTree({
    super.key,
    this.controller,
    this.roots,
    this.sortComparator,
    this.style = const TreeViewStyle(),
    this.logic = const TreeViewConfig(),
    this.onTodoChanged,
    this.prefixBuilder,
    this.contentBuilder,
    this.trailingBuilder,
    this.contextMenuBuilder,
    this.scrollController,
    this.physics,
  });

  static int defaultTodoComparator(TreeNode<TodoItem> a, TreeNode<TodoItem> b) {
    if (a.data.isCompleted && !b.data.isCompleted) return 1;
    if (!a.data.isCompleted && b.data.isCompleted) return -1;
    return a.data.title.toLowerCase().compareTo(b.data.title.toLowerCase());
  }

  Widget _defaultPrefixBuilder(BuildContext context, TreeNode<TodoItem> node) {
    final TreeNodeAsyncState asyncState =
        controller?.getNodeAsyncState(node.id) ??
        const TreeNodeAsyncState(isLoading: false, error: null);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: node.data.isCompleted,
          onChanged: (val) {
            node.data.isCompleted = val ?? false;
            onTodoChanged?.call(node.data);
            
            // We need to notify the tree that it might need re-sorting or re-rendering
            // If the user passed their own controller, we rely on them to call notifyListeners() 
            // from onTodoChanged, but we could ideally trigger a state update.
            // For now, checkboxes handle their own visual update when managed by a StatefulWidget parent.
          },
        ),
        if (asyncState.isLoading)
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else if (asyncState.hasError)
          Icon(
            Icons.error_outline,
            size: 14,
            color: Theme.of(context).colorScheme.error,
          ),
      ],
    );
  }

  Widget _defaultContentBuilder(BuildContext context, TreeNode<TodoItem> node, Widget? renameField) {
    final baseStyle = style.labelStyle ?? style.textStyle;
    final TextStyle finalStyle = (baseStyle ?? const TextStyle()).copyWith(
      decoration: node.data.isCompleted ? TextDecoration.lineThrough : null,
      color: node.data.isCompleted ? Colors.grey : (baseStyle?.color),
    );

    if (renameField != null) {
      return renameField;
    }

    final List<int> matchedIndices =
        controller?.getMatchedIndices(node.id) ?? const <int>[];

    return TreeHighlightedLabel(
      text: node.data.title,
      matchedIndices: matchedIndices,
      style: finalStyle,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SuperTreeView<TodoItem>(
      controller: controller,
      roots: roots,
      sortComparator: sortComparator ?? defaultTodoComparator,
      style: style,
      logic: logic,
      prefixBuilder: prefixBuilder ?? _defaultPrefixBuilder,
      contentBuilder: (context, node, renameField) => (contentBuilder ?? _defaultContentBuilder)(context, node, renameField),
      trailingBuilder: trailingBuilder,
      contextMenuBuilder: contextMenuBuilder,
      scrollController: scrollController,
      physics: physics,
    );
  }
}
