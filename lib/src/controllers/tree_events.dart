import 'package:super_tree/src/models/tree_node.dart';

/// Base sealed class for all events emitted by [TreeController].
///
/// Subscribe via [TreeController.events] to react to specific structural
/// changes without catching every general [ChangeNotifier] notification:
///
/// ```dart
/// controller.events.listen((event) {
///   switch (event) {
///     case TreeNodeMovedEvent():
///     case TreeNodeAddedEvent():
///     case TreeNodeRemovedEvent():
///     case TreeNodeRenamedEvent():
///       saveToDisk(controller.roots);
///   }
/// });
/// ```
sealed class TreeEvent<T> {}

/// Emitted when one or more nodes are added to the tree via
/// [TreeController.addRoot] or [TreeController.addChild].
final class TreeNodeAddedEvent<T> extends TreeEvent<T> {
  const TreeNodeAddedEvent({required this.node, this.parent});

  /// The node that was added.
  final TreeNode<T> node;

  /// The parent node the node was added to, or `null` if it was added as a root.
  final TreeNode<T>? parent;
}

/// Emitted when a node is removed from the tree via [TreeController.removeNode].
final class TreeNodeRemovedEvent<T> extends TreeEvent<T> {
  const TreeNodeRemovedEvent({required this.node});

  /// The node that was removed.
  final TreeNode<T> node;
}

/// Emitted when one or more nodes are moved within the tree via
/// [TreeController.moveNode] or [TreeController.moveNodes].
final class TreeNodeMovedEvent<T> extends TreeEvent<T> {
  const TreeNodeMovedEvent({required this.nodes});

  /// The nodes that were moved (in the order they were moved).
  final List<TreeNode<T>> nodes;
}

/// Emitted when a node is renamed via [TreeController.renameNode].
final class TreeNodeRenamedEvent<T> extends TreeEvent<T> {
  const TreeNodeRenamedEvent({required this.node, required this.newName});

  /// The node that was renamed.
  final TreeNode<T> node;

  /// The new name that was applied to the node.
  final String newName;
}
