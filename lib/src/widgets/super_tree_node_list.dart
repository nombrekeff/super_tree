import 'package:flutter/material.dart';
import 'package:super_tree/src/controllers/tree_controller.dart';
import 'package:super_tree/src/models/tree_node.dart';

/// Renders the visible node list and keeps it in sync with controller updates.
class SuperTreeNodeList<T> extends StatelessWidget {
  const SuperTreeNodeList({
    super.key,
    required this.controller,
    required this.itemBuilder,
    this.separatorBuilder,
    this.scrollController,
    this.physics,
  });

  final TreeController<T> controller;
  final Widget Function(TreeNode<T> node) itemBuilder;
  final Widget Function(BuildContext, int)? separatorBuilder;
  final ScrollController? scrollController;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, Widget? child) {
        final List<TreeNode<T>> nodes = controller.flatVisibleNodes;

        if (separatorBuilder != null) {
          return ListView.separated(
            controller: scrollController,
            physics: physics,
            itemCount: nodes.length,
            separatorBuilder: separatorBuilder!,
            itemBuilder: (BuildContext context, int index) {
              return itemBuilder(nodes[index]);
            },
          );
        }

        return ListView.builder(
          controller: scrollController,
          physics: physics,
          itemCount: nodes.length,
          itemBuilder: (BuildContext context, int index) {
            return itemBuilder(nodes[index]);
          },
        );
      },
    );
  }
}
