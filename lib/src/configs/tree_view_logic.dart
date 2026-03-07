import 'package:super_tree/src/models/tree_node.dart';
import 'package:super_tree/src/widgets/tree_drag_and_drop_wrapper.dart';

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
  final bool enableDragAndDrop;

  /// Whether to enable selection and in what mode.
  final SelectionMode selectionMode;

  /// The node ID that is currently being renamed, if any.
  final TreeNamingStrategy namingStrategy;

  /// Optional comparator to keep the tree sorted.
  final int Function(TreeNode<T> a, TreeNode<T> b)? defaultSortComparator;

  /// Callback generated when a node is single-tapped.
  final void Function(String id)? onNodeTap;

  /// Callback to determine if a node can be dropped at a specific position.
  /// If null, all drops not forming cycles are accepted.
  final bool Function(
    TreeNode<T> draggedNode,
    TreeNode<T> targetNode,
    NodeDropPosition position,
  )?
  canAcceptDrop;

  /// Callback to determine if a set of nodes can be dropped at a specific position.
  ///
  /// If null, batch drops fall back to [canAcceptDrop] validation per node.
  final bool Function(
    List<TreeNode<T>> draggedNodes,
    TreeNode<T> targetNode,
    NodeDropPosition position,
  )?
  canAcceptDropMany;

  /// Callback generated when a node is double-tapped.
  final void Function(String id)? onNodeDoubleTap;

  /// Top/bottom edge band ratio used to classify drops as above/below.
  ///
  /// Example: `0.05` means top 5% and bottom 5% are edge zones,
  /// while the middle 90% is treated as inside.
  final double dropEdgeBandFraction;

  /// Edge band ratio to use for nodes that cannot have children.
  ///
  /// This allows stricter above/below targeting on file-like nodes.
  final double dropEdgeBandFractionForLeaf;

  /// Pixel hysteresis around drop-zone boundaries to reduce flicker while dragging.
  final double dropPositionHysteresisPx;

  /// Whether drag gestures should auto-scroll when pointer nears viewport edges.
  final bool enableDragAutoScroll;

  /// Distance from top/bottom viewport edge that triggers drag auto-scroll.
  final double dragAutoScrollEdgeThresholdPx;

  /// Maximum scroll delta per drag move while in auto-scroll edge zone.
  final double dragAutoScrollMaxStepPx;

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
    this.canAcceptDrop,
    this.canAcceptDropMany,
    this.dropEdgeBandFraction = 0.05,
    this.dropEdgeBandFractionForLeaf = 0.2,
    this.dropPositionHysteresisPx = 8.0,
    this.enableDragAutoScroll = true,
    this.dragAutoScrollEdgeThresholdPx = 48.0,
    this.dragAutoScrollMaxStepPx = 20.0,
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
    bool Function(TreeNode<T> draggedNode, TreeNode<T> targetNode, NodeDropPosition position)?
    canAcceptDrop,
    bool Function(
      List<TreeNode<T>> draggedNodes,
      TreeNode<T> targetNode,
      NodeDropPosition position,
    )?
    canAcceptDropMany,
    double? dropEdgeBandFraction,
    double? dropEdgeBandFractionForLeaf,
    double? dropPositionHysteresisPx,
    bool? enableDragAutoScroll,
    double? dragAutoScrollEdgeThresholdPx,
    double? dragAutoScrollMaxStepPx,
    bool? debugMode,
  }) {
    return TreeViewConfig<T>(
      expansionTrigger: expansionTrigger ?? this.expansionTrigger,
      enableDragAndDrop: enableDragAndDrop ?? this.enableDragAndDrop,
      selectionMode: selectionMode ?? this.selectionMode,
      namingStrategy: namingStrategy ?? this.namingStrategy,
      defaultSortComparator: defaultSortComparator ?? this.defaultSortComparator,
      onNodeTap: onNodeTap ?? this.onNodeTap,
      onNodeDoubleTap: onNodeDoubleTap ?? this.onNodeDoubleTap,
      canAcceptDrop: canAcceptDrop ?? this.canAcceptDrop,
      canAcceptDropMany: canAcceptDropMany ?? this.canAcceptDropMany,
      dropEdgeBandFraction: dropEdgeBandFraction ?? this.dropEdgeBandFraction,
      dropEdgeBandFractionForLeaf:
          dropEdgeBandFractionForLeaf ?? this.dropEdgeBandFractionForLeaf,
      dropPositionHysteresisPx: dropPositionHysteresisPx ?? this.dropPositionHysteresisPx,
      enableDragAutoScroll: enableDragAutoScroll ?? this.enableDragAutoScroll,
      dragAutoScrollEdgeThresholdPx:
          dragAutoScrollEdgeThresholdPx ?? this.dragAutoScrollEdgeThresholdPx,
      dragAutoScrollMaxStepPx:
          dragAutoScrollMaxStepPx ?? this.dragAutoScrollMaxStepPx,
      debugMode: debugMode ?? this.debugMode,
    );
  }
}
