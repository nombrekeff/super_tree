import 'package:super_tree/src/configs/tree_drag_and_drop_config.dart';
import 'package:super_tree/src/models/tree_node.dart';

/// Behaviors that trigger a node's expansion.
enum ExpansionTrigger {
  /// Node expands only when tapping the explicit expand/collapse icon (prefix).
  iconTap,

  /// Node expands when clicking anywhere on the node row.
  tap,

  /// Node expands when double-clicking the node row.
  doubleTap,
}

/// Selection modes for the tree nodes.
enum SelectionMode {
  /// No selection allowed.
  none,

  /// Only one node can be selected at a time.
  single,

  /// Multiple nodes can be selected using Ctrl/Cmd or Shift keys.
  multiple,
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
  ///
  /// When `false`, the [dragAndDrop] sub-config is ignored entirely and no
  /// drag gesture recognizers are attached to nodes.
  final bool enableDragAndDrop;

  /// Whether to enable selection and in what mode.
  final SelectionMode selectionMode;

  /// The node ID that is currently being renamed, if any.
  final TreeNamingStrategy namingStrategy;

  /// Optional comparator to keep the tree sorted.
  final int Function(TreeNode<T> a, TreeNode<T> b)? defaultSortComparator;

  /// Callback generated when a node is single-tapped.
  final void Function(String id)? onNodeTap;

  /// Callback generated when a node is double-tapped.
  final void Function(String id)? onNodeDoubleTap;

  /// Drag-and-drop specific configuration.
  ///
  /// Only consulted when [enableDragAndDrop] is `true`. Controls drop
  /// validation callbacks, edge-band sizing, and auto-scroll behaviour.
  final TreeDragAndDropConfig<T> dragAndDrop;

  /// Whether to print debug logs for lifecycle and state changes.
  final bool debugMode;

  const TreeViewConfig({
    this.expansionTrigger = ExpansionTrigger.tap,
    this.enableDragAndDrop = true,
    this.selectionMode = SelectionMode.single,
    this.namingStrategy = TreeNamingStrategy.none,
    this.defaultSortComparator,
    this.onNodeTap,
    this.onNodeDoubleTap,
    this.dragAndDrop = const TreeDragAndDropConfig(),
    this.debugMode = false,
  });

  TreeViewConfig<T> copyWith({
    ExpansionTrigger? expansionTrigger,
    bool? enableDragAndDrop,
    SelectionMode? selectionMode,
    void Function(String id)? onNodeTap,
    void Function(String id)? onNodeDoubleTap,
    TreeNamingStrategy? namingStrategy,
    int Function(TreeNode<T> a, TreeNode<T> b)? defaultSortComparator,
    TreeDragAndDropConfig<T>? dragAndDrop,
    bool? debugMode,
  }) {
    return TreeViewConfig<T>(
      expansionTrigger: expansionTrigger ?? this.expansionTrigger,
      enableDragAndDrop: enableDragAndDrop ?? this.enableDragAndDrop,
      selectionMode: selectionMode ?? this.selectionMode,
      namingStrategy: namingStrategy ?? this.namingStrategy,
      defaultSortComparator:
          defaultSortComparator ?? this.defaultSortComparator,
      onNodeTap: onNodeTap ?? this.onNodeTap,
      onNodeDoubleTap: onNodeDoubleTap ?? this.onNodeDoubleTap,
      dragAndDrop: dragAndDrop ?? this.dragAndDrop,
      debugMode: debugMode ?? this.debugMode,
    );
  }
}
