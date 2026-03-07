import 'package:flutter/widgets.dart';
import 'package:super_tree/src/models/tree_node.dart';

/// A base interface for providing icons to a SuperTree instance based on its Data Class [T].
/// 
/// Implementing this interface allows supplying custom icon logic for custom trees. 
/// Providers have access to the full [TreeNode], giving them information about 
/// the node's state (expanded, selected, hovered) and data properties.
abstract class SuperTreeIconProvider<T> {
  /// Returns a widget representing the icon for the given [node].
  Widget getIcon(TreeNode<T> node);
}

/// Builds a standardized `prefixBuilder` for [SuperTreeView] from an icon provider.
Widget Function(BuildContext, TreeNode<T>) prefixBuilderFromIconProvider<T>({
  required SuperTreeIconProvider<T> iconProvider,
  double leadingSpacing = 4.0,
}) {
  return (BuildContext context, TreeNode<T> node) {
    final Widget icon = iconProvider.getIcon(node);

    if (leadingSpacing <= 0) {
      return icon;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(width: leadingSpacing),
        icon,
      ],
    );
  };
}
