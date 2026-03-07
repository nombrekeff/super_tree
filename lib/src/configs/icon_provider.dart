import 'package:flutter/widgets.dart';
import '../models/tree_node.dart';

/// A base interface for providing icons to a SuperTree instance based on its Data Class [T].
/// 
/// Implementing this interface allows supplying custom icon logic for custom trees. 
/// Providers have access to the full [TreeNode], giving them information about 
/// the node's state (expanded, selected, hovered) and data properties.
abstract class SuperTreeIconProvider<T> {
  /// Returns a widget representing the icon for the given [node].
  Widget getIcon(TreeNode<T> node);
}
