import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:super_tree/src/configs/tree_rename_selection.dart';
import 'package:super_tree/src/configs/tree_drag_and_drop_config.dart';
import 'package:super_tree/src/models/tree_node.dart';

/// Resolves the mouse cursor for a tree node based on interaction state.
typedef TreeNodeCursorResolver<T> = MouseCursor Function(
  TreeNode<T> node,
  TreeNodeCursorState state,
);

/// Snapshot of node interaction state used for cursor resolution.
class TreeNodeCursorState {
  /// Whether this node can be expanded/collapsed.
  final bool canExpand;

  /// Whether node selection is currently enabled.
  final bool canSelect;

  /// Whether the node is currently selected.
  final bool isSelected;

  /// Whether the node is currently being renamed.
  final bool isRenaming;

  /// Whether this node currently owns an open context menu.
  final bool isContextMenuOpen;

  /// Whether the pointer is hovering the target region.
  final bool isHovering;

  /// Whether cursor is being resolved for the expansion toggle region.
  final bool isExpansionToggle;

  /// Whether drag-and-drop interactions are enabled for nodes.
  final bool isDragAndDropEnabled;

  const TreeNodeCursorState({
    required this.canExpand,
    required this.canSelect,
    required this.isSelected,
    required this.isRenaming,
    required this.isContextMenuOpen,
    required this.isHovering,
    required this.isExpansionToggle,
    required this.isDragAndDropEnabled,
  });
}

/// Default cursor strategy for tree rows and expansion controls.
MouseCursor defaultTreeNodeCursorResolver<T>(
  TreeNode<T> _,
  TreeNodeCursorState state,
) {
  if (state.isRenaming) {
    return SystemMouseCursors.text;
  }

  if (state.isExpansionToggle && state.canExpand) {
    return SystemMouseCursors.click;
  }

  if (state.canSelect || state.canExpand) {
    return SystemMouseCursors.click;
  }

  if (state.isDragAndDropEnabled) {
    return SystemMouseCursors.grab;
  }

  return SystemMouseCursors.basic;
}

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

  /// Strategy used to select text when rename mode starts.
  ///
  /// When `null`, [TreeRenameSelectionStrategies.selectAll] is used.
  final TreeRenameSelectionStrategy<T>? renameSelectionStrategy;

  /// Optional comparator to keep the tree sorted.
  final int Function(TreeNode<T> a, TreeNode<T> b)? defaultSortComparator;

  /// Callback generated when a node is single-tapped.
  final void Function(String id)? onNodeTap;

  /// Callback generated when a node is double-tapped.
  final void Function(String id)? onNodeDoubleTap;

  /// Resolves the mouse cursor for each node region.
  final TreeNodeCursorResolver<T>? nodeCursorResolver;

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
    this.renameSelectionStrategy,
    this.defaultSortComparator,
    this.onNodeTap,
    this.onNodeDoubleTap,
    this.nodeCursorResolver,
    this.dragAndDrop = const TreeDragAndDropConfig(),
    this.debugMode = false,
  });

  TreeViewConfig<T> copyWith({
    ExpansionTrigger? expansionTrigger,
    bool? enableDragAndDrop,
    SelectionMode? selectionMode,
    void Function(String id)? onNodeTap,
    void Function(String id)? onNodeDoubleTap,
    TreeNodeCursorResolver<T>? nodeCursorResolver,
    TreeNamingStrategy? namingStrategy,
    TreeRenameSelectionStrategy<T>? renameSelectionStrategy,
    int Function(TreeNode<T> a, TreeNode<T> b)? defaultSortComparator,
    TreeDragAndDropConfig<T>? dragAndDrop,
    bool? debugMode,
  }) {
    return TreeViewConfig<T>(
      expansionTrigger: expansionTrigger ?? this.expansionTrigger,
      enableDragAndDrop: enableDragAndDrop ?? this.enableDragAndDrop,
      selectionMode: selectionMode ?? this.selectionMode,
      namingStrategy: namingStrategy ?? this.namingStrategy,
      renameSelectionStrategy:
          renameSelectionStrategy ?? this.renameSelectionStrategy,
      defaultSortComparator:
          defaultSortComparator ?? this.defaultSortComparator,
      onNodeTap: onNodeTap ?? this.onNodeTap,
      onNodeDoubleTap: onNodeDoubleTap ?? this.onNodeDoubleTap,
      nodeCursorResolver: nodeCursorResolver ?? this.nodeCursorResolver,
      dragAndDrop: dragAndDrop ?? this.dragAndDrop,
      debugMode: debugMode ?? this.debugMode,
    );
  }
}
