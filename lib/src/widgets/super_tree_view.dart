import 'package:flutter/material.dart';
import '../models/tree_node.dart';
import '../controllers/tree_controller.dart';
import '../configs/tree_view_style.dart';
import '../configs/tree_view_logic.dart';
import 'super_tree_node_widget.dart';
import 'context_menu_overlay.dart';

/// The entry point for rendering the tree view.
/// This widget observes the [TreeController] and renders nodes in a highly efficient flat List.
class SuperTreeView<T> extends StatefulWidget {
  /// The controller used to manipulate the tree.
  /// If not provided, an internal controller will be created.
  final TreeController<T>? controller;

  /// The root nodes of the tree.
  /// Used to seed the default controller if [controller] is not provided.
  final List<TreeNode<T>>? roots;

  /// Optional comparator to keep the tree sorted.
  /// Used by the default controller if [controller] is not provided.
  final int Function(TreeNode<T> a, TreeNode<T> b)? sortComparator;

  /// Defines visual properties like colors, paddings, and indentations.
  final TreeViewStyle style;

  /// Defines behavior properties like expansion triggers and selectability.
  final TreeViewLogic<T> logic;

  /// Builds the prefix widget (e.g. expandable caret icon or file icon).
  final Widget Function(BuildContext, TreeNode<T>) prefixBuilder;

  /// Builds the main content area of the node (e.g. text label).
  final Widget Function(BuildContext context, TreeNode<T> node, Widget? renameField) contentBuilder;

  /// Builds optional trailing widgets (e.g. a 'more options' popup menu icon).
  final Widget Function(BuildContext, TreeNode<T>)? trailingBuilder;

  /// Optional function called when right-clicking (desktop) or long-pressing (mobile) a node.
  /// Returns a list of [ContextMenuItem]s to display.
  final List<ContextMenuItem> Function(BuildContext, TreeNode<T>)? contextMenuBuilder;

  /// Custom [ScrollController] if external list wrapping is needed.
  final ScrollController? scrollController;

  /// The scroll physics applied to the ListView.
  final ScrollPhysics? physics;

  /// Internal separator builder for the separated constructor.
  final Widget Function(BuildContext, int)? _separatorBuilder;

  const SuperTreeView({
    super.key,
    this.controller,
    this.roots,
    this.sortComparator,
    required this.prefixBuilder,
    required this.contentBuilder,
    this.trailingBuilder,
    this.contextMenuBuilder,
    this.scrollController,
    this.physics,
    this.style = const TreeViewStyle(),
    this.logic = const TreeViewLogic(),
  })  : _separatorBuilder = null;

  /// Convenience constructor to inject dividers between nodes using [ListView.separated].
  factory SuperTreeView.separated({
    Key? key,
    TreeController<T>? controller,
    List<TreeNode<T>>? roots,
    int Function(TreeNode<T> a, TreeNode<T> b)? sortComparator,
    required Widget Function(BuildContext, TreeNode<T>) prefixBuilder,
    required Widget Function(BuildContext context, TreeNode<T> node, Widget? renameField) contentBuilder,
    required Widget Function(BuildContext, int) separatorBuilder,
    Widget Function(BuildContext, TreeNode<T>)? trailingBuilder,
    List<ContextMenuItem> Function(BuildContext, TreeNode<T>)? contextMenuBuilder,
    ScrollController? scrollController,
    ScrollPhysics? physics,
    TreeViewStyle style = const TreeViewStyle(),
    TreeViewLogic<T> logic = const TreeViewLogic(),
  }) {
    return SuperTreeView<T>._separated(
      key: key,
      controller: controller,
      roots: roots,
      sortComparator: sortComparator,
      prefixBuilder: prefixBuilder,
      contentBuilder: contentBuilder,
      separatorBuilder: separatorBuilder,
      trailingBuilder: trailingBuilder,
      contextMenuBuilder: contextMenuBuilder,
      scrollController: scrollController,
      physics: physics,
      style: style,
      logic: logic,
    );
  }

  const SuperTreeView._separated({
    super.key,
    this.controller,
    this.roots,
    this.sortComparator,
    required this.prefixBuilder,
    required this.contentBuilder,
    required Widget Function(BuildContext, int) separatorBuilder,
    this.trailingBuilder,
    this.contextMenuBuilder,
    this.scrollController,
    this.physics,
    this.style = const TreeViewStyle(),
    this.logic = const TreeViewLogic(),
  })  : _separatorBuilder = separatorBuilder;

  @override
  State<SuperTreeView<T>> createState() => _SuperTreeViewState<T>();
}

class _SuperTreeViewState<T> extends State<SuperTreeView<T>> {
  late TreeController<T> _internalController;
  late bool _ownsController;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    _ownsController = widget.controller == null;
    _internalController = widget.controller ??
        TreeController<T>(
          roots: widget.roots,
          sortComparator: widget.sortComparator,
        );
  }

  @override
  void didUpdateWidget(SuperTreeView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      if (_ownsController) {
        _internalController.dispose();
      }
      _initController();
    } else if (_ownsController) {
      if (widget.sortComparator != oldWidget.sortComparator) {
        _internalController.sortComparator = widget.sortComparator;
      }
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      _internalController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _internalController,
      builder: (context, _) {
        final nodes = _internalController.flatVisibleNodes;

        if (widget._separatorBuilder != null) {
          return ListView.separated(
            controller: widget.scrollController,
            physics: widget.physics,
            itemCount: nodes.length,
            separatorBuilder: widget._separatorBuilder!,
            itemBuilder: (context, index) {
              return SuperTreeNodeWidget<T>(
                key: ValueKey(nodes[index].id),
                node: nodes[index],
                controller: _internalController,
                style: widget.style,
                logic: widget.logic,
                prefixBuilder: widget.prefixBuilder,
                contentBuilder: (context, node, renameField) => widget.contentBuilder(context, node, renameField),
                trailingBuilder: widget.trailingBuilder,
                contextMenuBuilder: widget.contextMenuBuilder,
              );
            },
          );
        }

        return ListView.builder(
          controller: widget.scrollController,
          physics: widget.physics,
          itemCount: nodes.length,
          itemBuilder: (context, index) {
            return SuperTreeNodeWidget<T>(
              key: ValueKey(nodes[index].id),
              node: nodes[index],
              controller: _internalController,
              style: widget.style,
              logic: widget.logic,
              prefixBuilder: widget.prefixBuilder,
              contentBuilder: (context, node, renameField) => widget.contentBuilder(context, node, renameField),
              trailingBuilder: widget.trailingBuilder,
              contextMenuBuilder: widget.contextMenuBuilder,
            );
          },
        );
      },
    );
  }
}
