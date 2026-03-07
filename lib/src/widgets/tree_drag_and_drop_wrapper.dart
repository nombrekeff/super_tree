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
  final bool Function(
    TreeNode<T> draggedNode,
    TreeNode<T> targetNode,
    NodeDropPosition position,
  )?
  canAcceptDrop;
  final void Function(
    TreeNode<T> draggedNode,
    TreeNode<T> targetNode,
    NodeDropPosition position,
  )
  onDrop;

  const TreeDragAndDropWrapper({
    super.key,
    required this.node,
    required this.enabled,
    required this.child,
    required this.style,
    this.edgeDropBandFraction = 0.05,
    this.edgeDropBandFractionForLeaf = 0.2,
    this.dropPositionHysteresisPx = 4.0,
    this.canAcceptDrop,
    required this.onDrop,
  });

  @override
  State<TreeDragAndDropWrapper<T>> createState() => _TreeDragAndDropWrapperState<T>();
}

class _TreeDragAndDropWrapperState<T> extends State<TreeDragAndDropWrapper<T>> {
  NodeDropPosition? _currentHoverPosition;

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

  NodeDropPosition? _resolveDropPosition(TreeNode<T> draggedNode, Offset globalOffset) {
    final NodeDropPosition rawPosition = _calculateRawDropPosition(globalOffset);
    if (_isValidDrop(draggedNode, rawPosition)) {
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

      if (_isValidDrop(draggedNode, nearestEdge)) {
        return nearestEdge;
      }
    }

    return null;
  }

  bool _isValidDrop(TreeNode<T> draggedNode, NodeDropPosition position) {
    // Cannot drop on oneself
    if (draggedNode.id == widget.node.id) return false;

    // Cannot drop a parent into its own descendant (infinite cycle prevention)
    bool createsCycle = false;
    TreeNode<T>? cursor = widget.node.parent;
    while (cursor != null) {
      if (cursor.id == draggedNode.id) {
        createsCycle = true;
        break;
      }
      cursor = cursor.parent;
    }
    if (createsCycle) return false;

    // Let the data model override if it implements SuperTreeData
    final targetData = widget.node.data;
    if (targetData is SuperTreeData) {
      if (position == NodeDropPosition.inside && !targetData.canHaveChildren) {
        return false;
      }
      if (!targetData.canAcceptDrop(draggedNode.data, position)) {
        return false;
      }
    }

    // Let the logic override if needed
    if (widget.canAcceptDrop != null) {
      return widget.canAcceptDrop!(draggedNode, widget.node, position);
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    // If not enabled, return the raw UI node without attaching gesture recognizers.
    if (!widget.enabled) return widget.child;
    return LayoutBuilder(
      builder: (context, constraints) {
        return DragTarget<TreeNode<T>>(
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
              final draggedNode = candidateData.first!;

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
                  if (validatedPosition == NodeDropPosition.inside &&
                      !targetData.canHaveChildren) {
                    validatedPosition = null;
                  } else if (!targetData.canAcceptDrop(draggedNode.data, validatedPosition)) {
                    validatedPosition = null;
                  }
                }

                if (validatedPosition != null && widget.canAcceptDrop != null) {
                  if (!widget.canAcceptDrop!(draggedNode, widget.node, validatedPosition)) {
                    validatedPosition = null;
                  }
                }
              }
            }

            // Check if draggable at all
            final draggedData = widget.node.data;
            bool canDrag = true;
            if (draggedData is SuperTreeData) {
              canDrag = draggedData.canBeDragged;
            }

            if (!canDrag) {
              return widget.child;
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                return Draggable<TreeNode<T>>(
                  data: widget.node,
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
