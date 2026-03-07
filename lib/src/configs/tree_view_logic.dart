import '../models/tree_node.dart';
import '../widgets/tree_drag_and_drop_wrapper.dart';

/// Behaviors that trigger a node's expansion.
enum ExpansionTrigger {
  /// Node expands only when tapping the explicit expand/collapse icon (prefix).
  iconTap,
  
  /// Node expands when clicking anywhere on the node row.
  tap,
  
  /// Node expands when double-clicking the node row.
  doubleTap,
}

/// Strategies for triggering in-tree node renaming.
enum TreeNamingStrategy {
  /// No in-tree renaming allowed.
  none,

  /// Trigger rename on double-click.
  doubleClick,

  /// Trigger rename on single click (useful for todo lists).
  click,

  /// Trigger rename via context menu only.
  contextMenu,

  /// Node is always in an editable state (like a list of text fields).
  always,
}

/// Configuration for the interaction behaviors of the [SuperTreeView].
class TreeViewConfig<T> {
  /// What action triggers a node to expand/collapse.
  final ExpansionTrigger expansionTrigger;

  /// Whether nodes can be dragged and dropped.
  final bool enableDragAndDrop;

  /// Whether multiple nodes can be selected concurrently (e.g. holding Shift/Ctrl).
  final bool enableMultiSelect;

  /// The node ID that is currently being renamed, if any.
  final TreeNamingStrategy namingStrategy;

  /// Optional comparator to keep the tree sorted.
  final int Function(TreeNode<T> a, TreeNode<T> b)? defaultSortComparator;

  /// Callback generated when a node is single-tapped.
  final void Function(String id)? onNodeTap;

  /// Callback to determine if a node can be dropped at a specific position.
  /// If null, all drops not forming cycles are accepted.
  final bool Function(TreeNode<T> draggedNode, TreeNode<T> targetNode, NodeDropPosition position)? canAcceptDrop;

  /// Callback generated when a node is double-tapped.
  final void Function(String id)? onNodeDoubleTap;

  /// Whether to print debug logs for lifecycle and state changes.
  final bool debugMode;

  const TreeViewConfig({
    this.expansionTrigger = ExpansionTrigger.tap,
    this.enableDragAndDrop = true,
    this.enableMultiSelect = false,
    this.namingStrategy = TreeNamingStrategy.none,
    this.defaultSortComparator,
    this.onNodeTap,
    this.onNodeDoubleTap,
    this.canAcceptDrop,
    this.debugMode = false,
  });

  TreeViewConfig<T> copyWith({
    ExpansionTrigger? expansionTrigger,
    bool? enableDragAndDrop,
    bool? enableMultiSelect,
    void Function(String id)? onNodeTap,
    void Function(String id)? onNodeDoubleTap,
    TreeNamingStrategy? namingStrategy,
    int Function(TreeNode<T> a, TreeNode<T> b)? defaultSortComparator,
    bool Function(TreeNode<T> draggedNode, TreeNode<T> targetNode, NodeDropPosition position)? canAcceptDrop,
    bool? debugMode,
  }) {
    return TreeViewConfig<T>(
      expansionTrigger: expansionTrigger ?? this.expansionTrigger,
      enableDragAndDrop: enableDragAndDrop ?? this.enableDragAndDrop,
      enableMultiSelect: enableMultiSelect ?? this.enableMultiSelect,
      namingStrategy: namingStrategy ?? this.namingStrategy,
      defaultSortComparator: defaultSortComparator ?? this.defaultSortComparator,
      onNodeTap: onNodeTap ?? this.onNodeTap,
      onNodeDoubleTap: onNodeDoubleTap ?? this.onNodeDoubleTap,
      canAcceptDrop: canAcceptDrop ?? this.canAcceptDrop,
      debugMode: debugMode ?? this.debugMode,
    );
  }
}
