import 'package:flutter/material.dart';
import '../models/tree_node.dart';
import '../models/super_tree_data.dart';
import '../configs/tree_view_style.dart';

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
    this.canAcceptDrop,
    required this.onDrop,
  });

  @override
  State<TreeDragAndDropWrapper<T>> createState() =>
      _TreeDragAndDropWrapperState<T>();
}

class _TreeDragAndDropWrapperState<T> extends State<TreeDragAndDropWrapper<T>> {
  NodeDropPosition? _currentHoverPosition;

  @override
  Widget build(BuildContext context) {
    // If not enabled, return the raw UI node without attaching gesture recognizers.
    if (!widget.enabled) return widget.child;
    return LayoutBuilder(
      builder: (context, constraints) {
        return DragTarget<TreeNode<T>>(
          onWillAcceptWithDetails: (details) {
            // Cannot drop on oneself
            if (details.data.id == widget.node.id) return false;

            // Cannot drop a parent into its own descendant (infinite cycle prevention)
            bool createsCycle = false;
            TreeNode<T>? cursor = widget.node.parent;
            while (cursor != null) {
              if (cursor.id == details.data.id) {
                createsCycle = true;
                break;
              }
              cursor = cursor.parent;
            }

            if (createsCycle) return false;

            // Let the data model override if it implements SuperTreeData
            final targetData = widget.node.data;
            if (targetData is SuperTreeData && _currentHoverPosition != null) {
              if (_currentHoverPosition == NodeDropPosition.inside && !targetData.canHaveChildren) {
                return false;
              }
              if (!targetData.canAcceptDrop(details.data.data, _currentHoverPosition!)) {
                return false;
              }
            }

            // Let the logic override if needed
            if (widget.canAcceptDrop != null &&
                _currentHoverPosition != null) {
              return widget.canAcceptDrop!(
                details.data,
                widget.node,
                _currentHoverPosition!,
              );
            }

            return true;
          },
          onAcceptWithDetails: (details) {
            if (_currentHoverPosition != null) {
              bool isAccepted = true;
              if (widget.canAcceptDrop != null) {
                isAccepted = widget.canAcceptDrop!(
                  details.data,
                  widget.node,
                  _currentHoverPosition!,
                );
              }
              if (isAccepted) {
                widget.onDrop(details.data, widget.node, _currentHoverPosition!);
              }
            }
            setState(() => _currentHoverPosition = null);
          },
          onLeave: (_) {
            setState(() => _currentHoverPosition = null);
          },
          onMove: (details) {
            // Calculate the relative hovering position dynamically.
            final RenderBox renderBox = context.findRenderObject() as RenderBox;
            final Offset localPosition = renderBox.globalToLocal(
              details.offset,
            );
            final double height = renderBox.size.height;

            NodeDropPosition computedPosition;
            if (localPosition.dy < height * 0.35) {
              computedPosition = NodeDropPosition.above;
            } else if (localPosition.dy > height * 0.65) {
              computedPosition = NodeDropPosition.below;
            } else {
              computedPosition = NodeDropPosition.inside;
            }

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
                  if (validatedPosition == NodeDropPosition.inside && !targetData.canHaveChildren) {
                    validatedPosition = null;
                  } else if (!targetData.canAcceptDrop(draggedNode.data, validatedPosition)) {
                    validatedPosition = null;
                  }
                }

                if (validatedPosition != null && widget.canAcceptDrop != null) {
                  if (!widget.canAcceptDrop!(
                    draggedNode,
                    widget.node,
                    validatedPosition,
                  )) {
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
                  feedback: Material(
                    elevation: 8,
                    color: Colors.transparent,
                    child: Opacity(
                      opacity: 0.8,
                      // Constrain width so it matches the general tree view visually
                      child: SizedBox(
                        width: constraints.maxWidth,
                        child: widget.child,
                      ),
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
        canvas.drawLine(
          Offset(0, size.height),
          Offset(size.width, size.height),
          paint,
        );
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
