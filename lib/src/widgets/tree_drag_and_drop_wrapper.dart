import 'package:flutter/material.dart';
import '../models/tree_node.dart';
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
  final void Function(TreeNode<T> draggedNode, TreeNode<T> targetNode, NodeDropPosition position) onDrop;

  const TreeDragAndDropWrapper({
    Key? key,
    required this.node,
    required this.enabled,
    required this.child,
    required this.style,
    required this.onDrop,
  }) : super(key: key);

  @override
  State<TreeDragAndDropWrapper<T>> createState() => _TreeDragAndDropWrapperState<T>();
}

class _TreeDragAndDropWrapperState<T> extends State<TreeDragAndDropWrapper<T>> {
  NodeDropPosition? _currentHoverPosition;

  @override
  Widget build(BuildContext context) {
    // If not enabled, return the raw UI node without attaching gesture recognizers.
    if (!widget.enabled) return widget.child;

    return DragTarget<TreeNode<T>>(
      onWillAcceptWithDetails: (details) {
        // Cannot drop on oneself
        if (details.data.id == widget.node.id) return false;
        
        // Cannot drop a parent into its own child (infinite cycle prevention)
        bool createsCycle = false;
        TreeNode<T>? parentCursor = widget.node.parent;
        while (parentCursor != null) {
          if (parentCursor.id == details.data.id) {
            createsCycle = true;
            break;
          }
          parentCursor = parentCursor.parent;
        }
        return !createsCycle;
      },
      onAcceptWithDetails: (details) {
        if (_currentHoverPosition != null) {
          widget.onDrop(details.data, widget.node, _currentHoverPosition!);
        }
        setState(() => _currentHoverPosition = null);
      },
      onLeave: (_) {
        setState(() => _currentHoverPosition = null);
      },
      onMove: (details) {
        // Calculate the relative hovering position dynamically.
        final RenderBox renderBox = context.findRenderObject() as RenderBox;
        final Offset localPosition = renderBox.globalToLocal(details.offset);
        final double height = renderBox.size.height;
        
        NodeDropPosition computedPosition;
        if (localPosition.dy < height * 0.25) {
          computedPosition = NodeDropPosition.above;
        } else if (localPosition.dy > height * 0.75) {
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
        return Draggable<TreeNode<T>>(
          data: widget.node,
          feedback: Material(
            elevation: 8,
            color: Colors.transparent,
            child: Opacity(
              opacity: 0.8,
              // Constrain width so it matches the general tree view visually
              child: SizedBox(
                width: 300, 
                child: widget.child,
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: widget.child,
          ),
          child: Stack(
            children: [
              widget.child,
              if (_currentHoverPosition != null)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _DropIndictorPainter(
                      position: _currentHoverPosition!,
                      color: widget.style.dropIndicatorColor,
                    ),
                  ),
                ),
            ],
          ),
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
