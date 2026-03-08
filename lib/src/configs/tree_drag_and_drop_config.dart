import 'package:flutter/material.dart';
import 'package:super_tree/src/models/tree_node.dart';

/// The target drop position relative to a node's bounds.
enum NodeDropPosition {
  /// Drop implies inserting the node above the target.
  above,

  /// Drop implies nesting the node inside the target as a child.
  inside,

  /// Drop implies inserting the node below the target.
  below,
}

/// Visual style options specific to drag-and-drop interactions in [SuperTreeView].
class TreeDragAndDropStyle {
  /// Color of the drop indicator line/highlight shown during a drag.
  final Color indicatorColor;

  /// Creates a [TreeDragAndDropStyle] with sensible defaults.
  const TreeDragAndDropStyle({
    this.indicatorColor = Colors.blue,
  });

  /// Returns a copy of this style with the given fields replaced.
  TreeDragAndDropStyle copyWith({
    Color? indicatorColor,
  }) {
    return TreeDragAndDropStyle(
      indicatorColor: indicatorColor ?? this.indicatorColor,
    );
  }
}

/// Configuration for drag-and-drop behavior in [SuperTreeView].
///
/// Group all drag-and-drop settings here and pass the object as
/// [TreeViewConfig.dragAndDrop] to keep the top-level config class lean.
class TreeDragAndDropConfig<T> {
  /// Whether nodes can be dragged and dropped.
  final bool enabled;

  /// Callback to determine if a node can be dropped at a specific position.
  ///
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

  /// Top/bottom edge band ratio used to classify drops as above/below.
  ///
  /// Example: `0.05` means the top 5% and bottom 5% are edge zones,
  /// while the middle 90% is treated as *inside*.
  final double dropEdgeBandFraction;

  /// Edge band ratio to use for nodes that cannot have children.
  ///
  /// Stricter above/below targeting on leaf nodes (e.g. files).
  final double dropEdgeBandFractionForLeaf;

  /// Pixel hysteresis around drop-zone boundaries to reduce flicker while dragging.
  final double dropPositionHysteresisPx;

  /// Whether drag gestures should auto-scroll when the pointer nears viewport edges.
  final bool enableAutoScroll;

  /// Distance from the top/bottom viewport edge that triggers drag auto-scroll.
  final double autoScrollEdgeThresholdPx;

  /// Maximum scroll delta per drag move while in the auto-scroll edge zone.
  final double autoScrollMaxStepPx;

  /// Creates a [TreeDragAndDropConfig] with sensible defaults.
  const TreeDragAndDropConfig({
    this.enabled = true,
    this.canAcceptDrop,
    this.canAcceptDropMany,
    this.dropEdgeBandFraction = 0.05,
    this.dropEdgeBandFractionForLeaf = 0.2,
    this.dropPositionHysteresisPx = 8.0,
    this.enableAutoScroll = true,
    this.autoScrollEdgeThresholdPx = 48.0,
    this.autoScrollMaxStepPx = 20.0,
  });

  /// Returns a copy of this config with the given fields replaced.
  TreeDragAndDropConfig<T> copyWith({
    bool? enabled,
    bool Function(
      TreeNode<T> draggedNode,
      TreeNode<T> targetNode,
      NodeDropPosition position,
    )?
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
    bool? enableAutoScroll,
    double? autoScrollEdgeThresholdPx,
    double? autoScrollMaxStepPx,
  }) {
    return TreeDragAndDropConfig<T>(
      enabled: enabled ?? this.enabled,
      canAcceptDrop: canAcceptDrop ?? this.canAcceptDrop,
      canAcceptDropMany: canAcceptDropMany ?? this.canAcceptDropMany,
      dropEdgeBandFraction: dropEdgeBandFraction ?? this.dropEdgeBandFraction,
      dropEdgeBandFractionForLeaf:
          dropEdgeBandFractionForLeaf ?? this.dropEdgeBandFractionForLeaf,
      dropPositionHysteresisPx:
          dropPositionHysteresisPx ?? this.dropPositionHysteresisPx,
      enableAutoScroll: enableAutoScroll ?? this.enableAutoScroll,
      autoScrollEdgeThresholdPx:
          autoScrollEdgeThresholdPx ?? this.autoScrollEdgeThresholdPx,
      autoScrollMaxStepPx: autoScrollMaxStepPx ?? this.autoScrollMaxStepPx,
    );
  }
}
