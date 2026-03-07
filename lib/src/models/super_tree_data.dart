import '../../super_tree.dart';

/// An optional mixin that gives data items intelligent defaulting for the tree view.
/// 
/// Implementing this on your data class [T] allows the [TreeController] and
/// [TreeDragAndDropWrapper] to automatically enforce structural rules without 
/// verbose conditional logic in the widget configuration.
mixin SuperTreeData {
  /// Defines if this node is conceptually a container.
  /// If false, the [TreeController] will prevent adding children to it,
  /// and Drag & Drop will prevent dropping items *inside* it.
  bool get canHaveChildren => true;

  /// Defines if this specific node can be dragged.
  bool get canBeDragged => true;

  /// Granular control over what can be dropped on/around this specific node.
  /// 
  /// By default, it allows everything (unless [canHaveChildren] prevents an inside drop).
  /// [draggedItem] is the data ([T]) of the node being dragged.
  bool canAcceptDrop(dynamic draggedItem, NodeDropPosition position) => true;
}
