import 'package:flutter/material.dart';
import '../../models/tree_node.dart';
import '../../models/prebuilt/todo_item.dart';
import '../../configs/tree_view_style.dart';
import '../../configs/tree_view_logic.dart';
import '../../controllers/tree_controller.dart';
import '../super_tree_view.dart';
import '../context_menu_overlay.dart';

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
      ],
    );
  }

  Widget _defaultContentBuilder(BuildContext context, TreeNode<TodoItem> node, Widget? renameField) {
    final baseStyle = style.labelStyle ?? style.textStyle;
    return renameField ?? Text(
      node.data.title,
      style: (baseStyle ?? const TextStyle()).copyWith(
        decoration: node.data.isCompleted ? TextDecoration.lineThrough : null,
        color: node.data.isCompleted ? Colors.grey : (baseStyle?.color),
      ),
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
