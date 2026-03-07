import 'package:flutter/material.dart';
import '../models/tree_node.dart';
import '../configs/tree_view_style.dart';
import '../configs/tree_view_logic.dart';
import '../controllers/tree_controller.dart';
import 'tree_drag_and_drop_wrapper.dart';

/// Renders a single node row in the [SuperTreeView].
class SuperTreeNodeWidget<T> extends StatefulWidget {
  final TreeNode<T> node;
  final TreeController<T> controller;
  final TreeViewStyle style;
  final TreeViewLogic<T> logic;

  final Widget Function(BuildContext, TreeNode<T>) prefixBuilder;
  final Widget Function(BuildContext, TreeNode<T>) contentBuilder;
  final Widget Function(BuildContext, TreeNode<T>)? trailingBuilder;

  /// Signature for right-click on desktop or long-press on mobile.
  final void Function(BuildContext, TreeNode<T>, Offset)? onContextMenu;

  const SuperTreeNodeWidget({
    super.key,
    required this.node,
    required this.controller,
    required this.style,
    required this.logic,
    required this.prefixBuilder,
    required this.contentBuilder,
    this.trailingBuilder,
    this.onContextMenu,
  });

  @override
  State<SuperTreeNodeWidget<T>> createState() => _SuperTreeNodeWidgetState<T>();
}

class _SuperTreeNodeWidgetState<T> extends State<SuperTreeNodeWidget<T>> {
  bool _isHovering = false;

  void _handleTap() {
    if (widget.logic.expansionTrigger == ExpansionTrigger.tap) {
      widget.controller.toggleNodeExpansion(widget.node);
    }
    widget.logic.onNodeTap?.call(widget.node.id);
  }

  void _handleDoubleTap() {
    if (widget.logic.expansionTrigger == ExpansionTrigger.doubleTap) {
      widget.controller.toggleNodeExpansion(widget.node);
    }
    widget.logic.onNodeDoubleTap?.call(widget.node.id);
  }

  void _handleIconTap() {
    widget.controller.toggleNodeExpansion(widget.node);
  }

  void _handleSecondaryTapDown(TapDownDetails details) {
    widget.onContextMenu?.call(context, widget.node, details.globalPosition);
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    widget.onContextMenu?.call(context, widget.node, details.globalPosition);
  }

  @override
  Widget build(BuildContext context) {
    final double paddingLeft = widget.style.indentAmount * widget.node.depth;
    
    return TreeDragAndDropWrapper<T>(
      node: widget.node,
      enabled: widget.logic.enableDragAndDrop,
      style: widget.style,
      canAcceptDrop: widget.logic.canAcceptDrop,
      onDrop: (TreeNode<T> draggedNode, TreeNode<T> targetNode, NodeDropPosition position) {
        if (position == NodeDropPosition.inside) {
          widget.controller.moveNode(
            dragged: draggedNode, 
            target: targetNode, 
            insertBefore: false, 
            nestInside: true,
          );
        } else if (position == NodeDropPosition.above) {
          widget.controller.moveNode(
            dragged: draggedNode, 
            target: targetNode, 
            insertBefore: true, 
            nestInside: false,
          );
        } else {
          widget.controller.moveNode(
            dragged: draggedNode, 
            target: targetNode, 
            insertBefore: false, 
            nestInside: false,
          );
        }
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        child: GestureDetector(
          onSecondaryTapDown: _handleSecondaryTapDown,
          onLongPressStart: _handleLongPressStart,
          onTap: _handleTap,
          onDoubleTap: (widget.logic.expansionTrigger == ExpansionTrigger.doubleTap || widget.logic.onNodeDoubleTap != null) ? _handleDoubleTap : null,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: EdgeInsets.only(
              left: widget.style.padding.horizontal / 2 + paddingLeft,
              right: widget.style.padding.horizontal / 2,
              top: widget.style.padding.vertical / 2,
              bottom: widget.style.padding.vertical / 2,
            ),
            color: widget.node.isSelected
                ? widget.style.selectedColor
                : (_isHovering || widget.controller.contextMenuNodeId == widget.node.id)
                    ? widget.style.hoverColor
                    : widget.style.idleColor,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Prefix (e.g. Caret icon)
                GestureDetector(
                  onTap: _handleIconTap,
                  behavior: HitTestBehavior.opaque,
                  child: widget.prefixBuilder(context, widget.node),
                ),
                
                const SizedBox(width: 8),

                // Content 
                Expanded(
                  child: widget.contentBuilder(context, widget.node),
                ),

                // Trailing Actions
                if (widget.trailingBuilder != null)
                  widget.trailingBuilder!(context, widget.node),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
