import 'package:flutter/material.dart';
import 'package:super_tree/src/configs/tree_view_style.dart';
import 'package:super_tree/src/models/super_tree_data.dart';
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

/// Payload carried during drag-and-drop operations.
///
/// [primaryNode] identifies the node where the drag gesture originated,
/// while [nodes] can include a batch selection when multi-node dragging is used.
class TreeDragPayload<T> {
  TreeDragPayload({
    required this.primaryNode,
    required List<TreeNode<T>> nodes,
  }) : nodes = List<TreeNode<T>>.unmodifiable(nodes);

  final TreeNode<T> primaryNode;
  final List<TreeNode<T>> nodes;

  bool get isBatch => nodes.length > 1;
}

/// A wrapper that manages Drag and Drop logic, visual highlights,
/// and exact drop positioning over a tree node.
class TreeDragAndDropWrapper<T> extends StatefulWidget {
  final TreeNode<T> node;
  final bool enabled;
  final Widget child;
  final TreeViewStyle style;
  final double edgeDropBandFraction;
  final double edgeDropBandFractionForLeaf;
  final double dropPositionHysteresisPx;
  final bool enableAutoScroll;
  final double autoScrollEdgeThresholdPx;
  final double autoScrollMaxStepPx;
  final List<TreeNode<T>> dragNodes;
  final bool Function(
    TreeNode<T> draggedNode,
    TreeNode<T> targetNode,
    NodeDropPosition position,
  )?
  canAcceptDrop;
  final bool Function(
    List<TreeNode<T>> draggedNodes,
    TreeNode<T> targetNode,
    NodeDropPosition position,
  )?
  canAcceptDropMany;
  final void Function(
    TreeDragPayload<T> payload,
    TreeNode<T> targetNode,
    NodeDropPosition position,
  )
  onDrop;

  TreeDragAndDropWrapper({
    super.key,
    required this.node,
    required this.enabled,
    required this.child,
    required this.style,
    this.edgeDropBandFraction = 0.05,
    this.edgeDropBandFractionForLeaf = 0.2,
    this.dropPositionHysteresisPx = 4.0,
    this.enableAutoScroll = true,
    this.autoScrollEdgeThresholdPx = 48.0,
    this.autoScrollMaxStepPx = 20.0,
    List<TreeNode<T>>? dragNodes,
    this.canAcceptDrop,
    this.canAcceptDropMany,
    required this.onDrop,
  }) : dragNodes = List<TreeNode<T>>.unmodifiable(
         dragNodes == null || dragNodes.isEmpty ? <TreeNode<T>>[node] : dragNodes,
       );

  @override
  State<TreeDragAndDropWrapper<T>> createState() => _TreeDragAndDropWrapperState<T>();
}

class _TreeDragAndDropWrapperState<T> extends State<TreeDragAndDropWrapper<T>> {
  NodeDropPosition? _currentHoverPosition;

  void _maybeAutoScroll(Offset globalOffset) {
    if (!widget.enableAutoScroll) {
      return;
    }

    final double edgeThreshold = widget.autoScrollEdgeThresholdPx;
    final double maxStep = widget.autoScrollMaxStepPx;
    if (edgeThreshold <= 0 || maxStep <= 0) {
      return;
    }

    final ScrollableState? scrollable = Scrollable.maybeOf(context);
    if (scrollable == null) {
      return;
    }

    final ScrollPosition position = scrollable.position;
    if (!position.hasPixels || !position.hasContentDimensions) {
      return;
    }

    final RenderObject? scrollRenderObject = scrollable.context.findRenderObject();
    if (scrollRenderObject is! RenderBox) {
      return;
    }

    final Offset topLeft = scrollRenderObject.localToGlobal(Offset.zero);
    final double viewportTop = topLeft.dy;
    final double viewportBottom = viewportTop + scrollRenderObject.size.height;
    final double distanceToTop = globalOffset.dy - viewportTop;
    final double distanceToBottom = viewportBottom - globalOffset.dy;

    double delta = 0;
    if (distanceToTop < edgeThreshold) {
      final double ratio = ((edgeThreshold - distanceToTop) / edgeThreshold).clamp(0.0, 1.0);
      delta = -maxStep * ratio;
    } else if (distanceToBottom < edgeThreshold) {
      final double ratio =
          ((edgeThreshold - distanceToBottom) / edgeThreshold).clamp(0.0, 1.0);
      delta = maxStep * ratio;
    }

    if (delta == 0) {
      return;
    }

    final double nextOffset = (position.pixels + delta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if (nextOffset == position.pixels) {
      return;
    }

    position.jumpTo(nextOffset);
  }

  double _clampEdgeFraction(double value) {
    return value.clamp(0.0, 0.49);
  }

  double _edgeBandFractionForTarget() {
    final Object? targetData = widget.node.data;
    if (targetData is SuperTreeData && !targetData.canHaveChildren) {
      return _clampEdgeFraction(widget.edgeDropBandFractionForLeaf);
    }

    return _clampEdgeFraction(widget.edgeDropBandFraction);
  }

  NodeDropPosition _calculateRawDropPosition(Offset globalOffset) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset localPosition = renderBox.globalToLocal(globalOffset);
    final double height = renderBox.size.height;

    final double edgeBand = _edgeBandFractionForTarget();
    final double topBoundary = height * edgeBand;
    final double bottomBoundary = height * (1 - edgeBand);
    final double hysteresisPx = widget.dropPositionHysteresisPx.clamp(0.0, height / 2);

    if (_currentHoverPosition != null) {
      switch (_currentHoverPosition!) {
        case NodeDropPosition.above:
          if (localPosition.dy <= topBoundary + hysteresisPx) {
            return NodeDropPosition.above;
          }
          break;
        case NodeDropPosition.below:
          if (localPosition.dy >= bottomBoundary - hysteresisPx) {
            return NodeDropPosition.below;
          }
          break;
        case NodeDropPosition.inside:
          if (localPosition.dy >= topBoundary - hysteresisPx &&
              localPosition.dy <= bottomBoundary + hysteresisPx) {
            return NodeDropPosition.inside;
          }
          break;
      }
    }

    if (localPosition.dy < topBoundary) {
      return NodeDropPosition.above;
    }
    if (localPosition.dy > bottomBoundary) {
      return NodeDropPosition.below;
    }
    return NodeDropPosition.inside;
  }

  NodeDropPosition? _resolveDropPosition(TreeDragPayload<T> payload, Offset globalOffset) {
    final NodeDropPosition rawPosition = _calculateRawDropPosition(globalOffset);
    if (_isValidDrop(payload, rawPosition)) {
      return rawPosition;
    }

    // If inside is invalid (for example on files), degrade to nearest edge.
    if (rawPosition == NodeDropPosition.inside) {
      final RenderBox renderBox = context.findRenderObject() as RenderBox;
      final Offset localPosition = renderBox.globalToLocal(globalOffset);
      final double height = renderBox.size.height;
      final NodeDropPosition nearestEdge = localPosition.dy < height / 2
          ? NodeDropPosition.above
          : NodeDropPosition.below;

      if (_isValidDrop(payload, nearestEdge)) {
        return nearestEdge;
      }
    }

    return null;
  }

  bool _isValidDrop(TreeDragPayload<T> payload, NodeDropPosition position) {
    final Set<String> draggedIds = payload.nodes
        .map((TreeNode<T> node) => node.id)
        .toSet();

    // Cannot drop any dragged node onto itself.
    if (draggedIds.contains(widget.node.id)) {
      return false;
    }

    // Cannot drop a parent into any of its descendants.
    for (final TreeNode<T> draggedNode in payload.nodes) {
      TreeNode<T>? cursor = widget.node.parent;
      while (cursor != null) {
        if (cursor.id == draggedNode.id) {
          return false;
        }
        cursor = cursor.parent;
      }
    }

    // Let the data model override if it implements SuperTreeData
    final targetData = widget.node.data;
    if (targetData is SuperTreeData) {
      if (position == NodeDropPosition.inside && !targetData.canHaveChildren) {
        return false;
      }
      if (payload.isBatch) {
        if (!targetData.canAcceptDropMany(
          payload.nodes.map((TreeNode<T> node) => node.data).toList(growable: false),
          position,
        )) {
          return false;
        }
      } else if (!targetData.canAcceptDrop(payload.primaryNode.data, position)) {
        return false;
      }
    }

    // Let optional logic-level guards override defaults.
    if (payload.isBatch) {
      if (widget.canAcceptDropMany != null) {
        return widget.canAcceptDropMany!(payload.nodes, widget.node, position);
      }

      if (widget.canAcceptDrop != null) {
        for (final TreeNode<T> draggedNode in payload.nodes) {
          if (!widget.canAcceptDrop!(draggedNode, widget.node, position)) {
            return false;
          }
        }
      }

      return true;
    }

    if (widget.canAcceptDrop != null) {
      return widget.canAcceptDrop!(payload.primaryNode, widget.node, position);
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    // If not enabled, return the raw UI node without attaching gesture recognizers.
    if (!widget.enabled) return widget.child;
    return LayoutBuilder(
      builder: (context, constraints) {
        return DragTarget<TreeDragPayload<T>>(
          onWillAcceptWithDetails: (details) {
            return _resolveDropPosition(details.data, details.offset) != null;
          },
          onAcceptWithDetails: (details) {
            final NodeDropPosition? position = _resolveDropPosition(
              details.data,
              details.offset,
            );
            if (position != null) {
              widget.onDrop(details.data, widget.node, position);
            }
            setState(() => _currentHoverPosition = null);
          },
          onLeave: (_) {
            setState(() => _currentHoverPosition = null);
          },
          onMove: (details) {
            _maybeAutoScroll(details.offset);
            final NodeDropPosition? computedPosition = _resolveDropPosition(
              details.data,
              details.offset,
            );
            if (_currentHoverPosition != computedPosition) {
              setState(() {
                _currentHoverPosition = computedPosition;
              });
            }
          },
          builder: (context, candidateData, rejectedData) {
            // Dynamic drop validation
            NodeDropPosition? validatedPosition = _currentHoverPosition;
            if (validatedPosition != null && candidateData.isNotEmpty) {
              final TreeDragPayload<T> payload = candidateData.first!;
              final TreeNode<T> draggedNode = payload.primaryNode;

              // Cycle check in builder for visual feedback
              bool createsCycle = false;
              TreeNode<T>? cursor = widget.node.parent;
              while (cursor != null) {
                if (cursor.id == draggedNode.id) {
                  createsCycle = true;
                  break;
                }
                cursor = cursor.parent;
              }

              if (createsCycle) {
                validatedPosition = null;
              } else {
                final targetData = widget.node.data;
                if (targetData is SuperTreeData) {
                  final NodeDropPosition currentPosition = validatedPosition;
                  if (validatedPosition == NodeDropPosition.inside &&
                      !targetData.canHaveChildren) {
                    validatedPosition = null;
                  } else if (payload.isBatch) {
                    if (!targetData.canAcceptDropMany(
                      payload.nodes
                          .map((TreeNode<T> node) => node.data)
                          .toList(growable: false),
                      currentPosition,
                    )) {
                      validatedPosition = null;
                    }
                  } else if (!targetData.canAcceptDrop(draggedNode.data, currentPosition)) {
                    validatedPosition = null;
                  }
                }

                if (validatedPosition != null && widget.canAcceptDrop != null) {
                  final NodeDropPosition currentPosition = validatedPosition;
                  if (payload.isBatch) {
                    if (widget.canAcceptDropMany != null) {
                      if (!widget.canAcceptDropMany!(
                        payload.nodes,
                        widget.node,
                        currentPosition,
                      )) {
                        validatedPosition = null;
                      }
                    } else {
                      for (final TreeNode<T> draggedItem in payload.nodes) {
                        if (!widget.canAcceptDrop!(
                          draggedItem,
                          widget.node,
                          currentPosition,
                        )) {
                          validatedPosition = null;
                          break;
                        }
                      }
                    }
                  } else if (!widget.canAcceptDrop!(
                    draggedNode,
                    widget.node,
                    currentPosition,
                  )) {
                    validatedPosition = null;
                  }
                }
              }
            }

            // Check if draggable at all
            bool canDrag = true;
            for (final TreeNode<T> dragNode in widget.dragNodes) {
              final Object? draggedData = dragNode.data;
              if (draggedData is SuperTreeData && !draggedData.canBeDragged) {
                canDrag = false;
                break;
              }
            }

            if (!canDrag) {
              return widget.child;
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                return Draggable<TreeDragPayload<T>>(
                  data: TreeDragPayload<T>(
                    primaryNode: widget.node,
                    nodes: widget.dragNodes,
                  ),
                  dragAnchorStrategy: pointerDragAnchorStrategy,
                  feedback: Material(
                    elevation: 8,
                    color: Colors.transparent,
                    child: Opacity(
                      opacity: 0.8,
                      // Constrain width so it matches the general tree view visually
                      child: SizedBox(width: constraints.maxWidth, child: widget.child),
                    ),
                  ),
                  childWhenDragging: Opacity(opacity: 0.3, child: widget.child),
                  child: Stack(
                    children: [
                      widget.child,
                      if (validatedPosition != null)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _DropIndictorPainter(
                              position: validatedPosition,
                              color: widget.style.dropIndicatorColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _DropIndictorPainter extends CustomPainter {
  final NodeDropPosition position;
  final Color color;

  _DropIndictorPainter({required this.position, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0;

    switch (position) {
      case NodeDropPosition.above:
        canvas.drawLine(const Offset(0, 0), Offset(size.width, 0), paint);
        break;
      case NodeDropPosition.below:
        canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), paint);
        break;
      case NodeDropPosition.inside:
        paint.style = PaintingStyle.stroke;
        canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _DropIndictorPainter oldDelegate) {
    return oldDelegate.position != position || oldDelegate.color != color;
  }
}
