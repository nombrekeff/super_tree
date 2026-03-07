import '../models/tree_node.dart';
import '../models/super_tree_data.dart';

/// Pre-made sorting comparators for the Super Tree.
class TreeSort {
  /// Sorts nodes alphabetically by their [TreeNode.id] or a custom display name if available.
  /// This is the simplest sorting strategy.
  static int alphabetical<T>(TreeNode<T> a, TreeNode<T> b) {
    return a.id.toLowerCase().compareTo(b.id.toLowerCase());
  }

  /// Sorts nodes in reverse alphabetical order.
  static int reverseAlphabetical<T>(TreeNode<T> a, TreeNode<T> b) {
    return b.id.toLowerCase().compareTo(a.id.toLowerCase());
  }

  /// Sorts folders (nodes that can have children) first, then files.
  /// Within each group, it sorts alphabetically.
  static int foldersFirst<T>(TreeNode<T> a, TreeNode<T> b) {
    final aData = a.data;
    final bData = b.data;

    bool aIsFolder = (aData is SuperTreeData) ? aData.canHaveChildren : a.hasChildren;
    bool bIsFolder = (bData is SuperTreeData) ? bData.canHaveChildren : b.hasChildren;

    if (aIsFolder && !bIsFolder) return -1;
    if (!aIsFolder && bIsFolder) return 1;

    return alphabetical(a, b);
  }

  /// Combines multiple sorting comparators.
  /// The first comparator that returns a non-zero value wins.
  static int Function(TreeNode<T> a, TreeNode<T> b) composite<T>(
    List<int Function(TreeNode<T> a, TreeNode<T> b)> comparators,
  ) {
    return (a, b) {
      for (final comparator in comparators) {
        final result = comparator(a, b);
        if (result != 0) return result;
      }
      return 0;
    };
  }
}
