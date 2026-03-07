import 'package:flutter/material.dart';
import '../models/tree_node.dart';
import '../controllers/tree_controller.dart';
import '../configs/tree_view_style.dart';
import '../configs/tree_view_logic.dart';
import 'super_tree_node_widget.dart';

/// The entry point for rendering the tree view.
/// This widget observes the [TreeController] and renders nodes in a highly efficient flat List.
class SuperTreeView<T> extends StatelessWidget {
  /// The controller used to manipulate the tree.
  final TreeController<T> controller;

  /// Defines visual properties like colors, paddings, and indentations.
  final TreeViewStyle style;

  /// Defines behavior properties like expansion triggers and selectability.
  final TreeViewLogic<T> logic;

  /// Builds the prefix widget (e.g. expandable caret icon or file icon).
  final Widget Function(BuildContext, TreeNode<T>) prefixBuilder;

  /// Builds the main content area of the node (e.g. text label).
  final Widget Function(BuildContext, TreeNode<T>) contentBuilder;

  /// Builds optional trailing widgets (e.g. a 'more options' popup menu icon).
  final Widget Function(BuildContext, TreeNode<T>)? trailingBuilder;

  /// Optional function called when right-clicking (desktop) or long-pressing (mobile) a node.
  final void Function(BuildContext, TreeNode<T>, Offset)? onContextMenu;

  /// Custom [ScrollController] if external list wrapping is needed.
  final ScrollController? scrollController;

  /// The scroll physics applied to the ListView.
  final ScrollPhysics? physics;

  const SuperTreeView({
    Key? key,
    required this.controller,
    required this.prefixBuilder,
    required this.contentBuilder,
    this.trailingBuilder,
    this.onContextMenu,
    this.scrollController,
    this.physics,
    this.style = const TreeViewStyle(),
    this.logic = const TreeViewLogic(),
  }) : super(key: key);

  /// Convenience constructor to inject dividers between nodes using [ListView.separated].
  factory SuperTreeView.separated({
    Key? key,
    required TreeController<T> controller,
    required Widget Function(BuildContext, TreeNode<T>) prefixBuilder,
    required Widget Function(BuildContext, TreeNode<T>) contentBuilder,
    required Widget Function(BuildContext, int) separatorBuilder,
    Widget Function(BuildContext, TreeNode<T>)? trailingBuilder,
    void Function(BuildContext, TreeNode<T>, Offset)? onContextMenu,
    ScrollController? scrollController,
    ScrollPhysics? physics,
    TreeViewStyle style = const TreeViewStyle(),
    TreeViewLogic<T> logic = const TreeViewLogic(),
  }) {
    return _SuperTreeViewSeparated<T>(
      key: key,
      controller: controller,
      prefixBuilder: prefixBuilder,
      contentBuilder: contentBuilder,
      separatorBuilder: separatorBuilder,
      trailingBuilder: trailingBuilder,
      onContextMenu: onContextMenu,
      scrollController: scrollController,
      physics: physics,
      style: style,
      logic: logic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final nodes = controller.flatVisibleNodes;
        return ListView.builder(
          controller: scrollController,
          physics: physics,
          itemCount: nodes.length,
          itemBuilder: (context, index) {
            return SuperTreeNodeWidget<T>(
              key: ValueKey(nodes[index].id),
              node: nodes[index],
              controller: controller,
              style: style,
              logic: logic,
              prefixBuilder: prefixBuilder,
              contentBuilder: contentBuilder,
              trailingBuilder: trailingBuilder,
              onContextMenu: onContextMenu,
            );
          },
        );
      },
    );
  }
}

class _SuperTreeViewSeparated<T> extends SuperTreeView<T> {
  final Widget Function(BuildContext, int) separatorBuilder;

  const _SuperTreeViewSeparated({
    Key? key,
    required TreeController<T> controller,
    required Widget Function(BuildContext, TreeNode<T>) prefixBuilder,
    required Widget Function(BuildContext, TreeNode<T>) contentBuilder,
    required this.separatorBuilder,
    Widget Function(BuildContext, TreeNode<T>)? trailingBuilder,
    void Function(BuildContext, TreeNode<T>, Offset)? onContextMenu,
    ScrollController? scrollController,
    ScrollPhysics? physics,
    required TreeViewStyle style,
    required TreeViewLogic<T> logic,
  }) : super(
          key: key,
          controller: controller,
          prefixBuilder: prefixBuilder,
          contentBuilder: contentBuilder,
          trailingBuilder: trailingBuilder,
          onContextMenu: onContextMenu,
          scrollController: scrollController,
          physics: physics,
          style: style,
          logic: logic,
        );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final nodes = controller.flatVisibleNodes;
        return ListView.separated(
          controller: scrollController,
          physics: physics,
          itemCount: nodes.length,
          separatorBuilder: separatorBuilder,
          itemBuilder: (context, index) {
            return SuperTreeNodeWidget<T>(
              key: ValueKey(nodes[index].id),
              node: nodes[index],
              controller: controller,
              style: style,
              logic: logic,
              prefixBuilder: prefixBuilder,
              contentBuilder: contentBuilder,
              trailingBuilder: trailingBuilder,
              onContextMenu: onContextMenu,
            );
          },
        );
      },
    );
  }
}
