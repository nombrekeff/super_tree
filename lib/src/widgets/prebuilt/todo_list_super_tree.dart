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
class TodoListSuperTree extends StatefulWidget {
  final TreeController<TodoItem>? controller;
  final List<TreeNode<TodoItem>>? roots;

  /// Sort comparator. Defaults to uncompleted first, then alphabetical.
  final int Function(TreeNode<TodoItem> a, TreeNode<TodoItem> b)?
  sortComparator;

  final TreeViewStyle style;
  final TreeViewConfig<TodoItem> logic;

  final void Function(TodoItem item)? onTodoChanged;

  /// Optional builder overrides.
  final Widget Function(BuildContext, TreeNode<TodoItem>)? prefixBuilder;
  final Widget Function(
    BuildContext context,
    TreeNode<TodoItem> node,
    Widget? renameField,
  )?
  contentBuilder;
  final Widget Function(BuildContext, TreeNode<TodoItem>)? trailingBuilder;

  /// Optional function called when right-clicking (desktop) or long-pressing (mobile) a node.
  @Deprecated(
    'Use contextMenuWidgetBuilder instead. '
    'This list-based API will be removed in a future release.',
  )
  final List<ContextMenuItem> Function(BuildContext, TreeNode<TodoItem>)?
  contextMenuBuilder;

  /// Optional function called when right-clicking (desktop) or long-pressing (mobile) a node.
  final Widget Function(BuildContext, TreeNode<TodoItem>)?
  contextMenuWidgetBuilder;
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
    this.contextMenuWidgetBuilder,
    this.scrollController,
    this.physics,
  });

  @override
  State<TodoListSuperTree> createState() => _TodoListSuperTreeState();

  static int defaultTodoComparator(TreeNode<TodoItem> a, TreeNode<TodoItem> b) {
    if (a.data.isCompleted && !b.data.isCompleted) return 1;
    if (!a.data.isCompleted && b.data.isCompleted) return -1;
    return a.data.title.toLowerCase().compareTo(b.data.title.toLowerCase());
  }
}

class _TodoListSuperTreeState extends State<TodoListSuperTree> {
  bool? _computeCheckboxState(TreeNode<TodoItem> node) {
    if (node.children.isEmpty) {
      return node.data.isCompleted;
    }

    bool allTrue = true;
    bool allFalse = true;

    for (final TreeNode<TodoItem> child in node.children) {
      final bool? childState = _computeCheckboxState(child);
      if (childState != true) {
        allTrue = false;
      }
      if (childState != false) {
        allFalse = false;
      }
    }

    if (allTrue) {
      return true;
    }

    if (allFalse) {
      return false;
    }

    return null;
  }

  void _setNodeAndDescendantsChecked(TreeNode<TodoItem> node, bool checked) {
    node.data.isCompleted = checked;
    for (final TreeNode<TodoItem> child in node.children) {
      _setNodeAndDescendantsChecked(child, checked);
    }
  }

  void _syncAncestors(TreeNode<TodoItem> node) {
    TreeNode<TodoItem>? currentParent = node.parent;
    while (currentParent != null) {
      final bool? computedState = _computeCheckboxState(currentParent);
      currentParent.data.isCompleted = computedState == true;
      currentParent = currentParent.parent;
    }
  }

  void _handleCheckboxChanged(TreeNode<TodoItem> node, bool? rawValue) {
    final bool? currentState = _computeCheckboxState(node);
    final bool checked;
    if (currentState == null && rawValue == false) {
      checked = true;
    } else {
      checked = rawValue ?? true;
    }

    _setNodeAndDescendantsChecked(node, checked);
    _syncAncestors(node);

    widget.onTodoChanged?.call(node.data);
    widget.controller?.refresh();
    setState(() {});
  }

  Widget _defaultPrefixBuilder(BuildContext context, TreeNode<TodoItem> node) {
    final TreeNodeAsyncState asyncState =
        widget.controller?.getNodeAsyncState(node.id) ??
        const TreeNodeAsyncState(
          state: TreeNodeState.loaded,
          isLoading: false,
          error: null,
        );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: _computeCheckboxState(node),
          tristate: node.children.isNotEmpty,
          onChanged: (bool? value) => _handleCheckboxChanged(node, value),
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

  Widget _defaultContentBuilder(
    BuildContext context,
    TreeNode<TodoItem> node,
    Widget? renameField,
  ) {
    final TextStyle? baseStyle =
        widget.style.labelStyle ?? widget.style.textStyle;
    final Color fallbackLabelColor = Theme.of(context).colorScheme.onSurface;
    final TextStyle finalStyle = (baseStyle ?? const TextStyle()).copyWith(
      decoration: node.data.isCompleted ? TextDecoration.lineThrough : null,
      color: node.data.isCompleted
          ? Colors.grey
          : (baseStyle?.color ?? fallbackLabelColor),
    );

    if (renameField != null) {
      return renameField;
    }

    final List<int> matchedIndices =
        widget.controller?.getMatchedIndices(node.id) ?? const <int>[];

    return TreeHighlightedLabel(
      text: node.data.title,
      matchedIndices: matchedIndices,
      style: finalStyle,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SuperTreeView<TodoItem>(
      controller: widget.controller,
      roots: widget.roots,
      sortComparator:
          widget.sortComparator ?? TodoListSuperTree.defaultTodoComparator,
      style: widget.style,
      logic: widget.logic,
      prefixBuilder: widget.prefixBuilder ?? _defaultPrefixBuilder,
      contentBuilder: (context, node, renameField) =>
          (widget.contentBuilder ?? _defaultContentBuilder)(
            context,
            node,
            renameField,
          ),
      trailingBuilder: widget.trailingBuilder,
      // ignore: deprecated_member_use_from_same_package
      contextMenuBuilder: widget.contextMenuBuilder,
      contextMenuWidgetBuilder: widget.contextMenuWidgetBuilder,
      scrollController: widget.scrollController,
      physics: widget.physics,
    );
  }
}
