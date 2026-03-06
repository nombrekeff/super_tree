/// Behaviors that trigger a node's expansion.
enum ExpansionTrigger {
  /// Node expands only when tapping the explicit expand/collapse icon.
  iconTap,
  
  /// Node expands when clicking anywhere on the node row.
  tap,
  
  /// Node expands when double-clicking the node row.
  doubleTap,
}

/// Configuration for the interaction behaviors of the [SuperTreeView].
class TreeViewLogic {
  /// What action triggers a node to expand/collapse.
  final ExpansionTrigger expansionTrigger;

  /// Whether nodes can be dragged and dropped.
  final bool enableDragAndDrop;

  /// Whether multiple nodes can be selected concurrently (e.g. holding Shift/Ctrl).
  final bool enableMultiSelect;

  /// Callback generated when a node is single-tapped.
  final void Function(String id)? onNodeTap;

  /// Callback generated when a node is double-tapped.
  final void Function(String id)? onNodeDoubleTap;

  const TreeViewLogic({
    this.expansionTrigger = ExpansionTrigger.tap,
    this.enableDragAndDrop = true,
    this.enableMultiSelect = false,
    this.onNodeTap,
    this.onNodeDoubleTap,
  });

  TreeViewLogic copyWith({
    ExpansionTrigger? expansionTrigger,
    bool? enableDragAndDrop,
    bool? enableMultiSelect,
    void Function(String id)? onNodeTap,
    void Function(String id)? onNodeDoubleTap,
  }) {
    return TreeViewLogic(
      expansionTrigger: expansionTrigger ?? this.expansionTrigger,
      enableDragAndDrop: enableDragAndDrop ?? this.enableDragAndDrop,
      enableMultiSelect: enableMultiSelect ?? this.enableMultiSelect,
      onNodeTap: onNodeTap ?? this.onNodeTap,
      onNodeDoubleTap: onNodeDoubleTap ?? this.onNodeDoubleTap,
    );
  }
}
