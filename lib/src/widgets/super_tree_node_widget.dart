import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/tree_node.dart';
import '../configs/tree_view_style.dart';
import '../configs/tree_view_logic.dart';
import '../controllers/tree_controller.dart';
import 'tree_drag_and_drop_wrapper.dart';
import 'context_menu_overlay.dart';

/// Renders a single node row in the [SuperTreeView].
class SuperTreeNodeWidget<T> extends StatefulWidget {
  final TreeNode<T> node;
  final TreeController<T> controller;
  final TreeViewStyle style;
  final TreeViewLogic<T> logic;

  final Widget Function(BuildContext, TreeNode<T>) prefixBuilder;
  final Widget Function(BuildContext context, TreeNode<T> node, Widget? renameField) contentBuilder;
  final Widget Function(BuildContext, TreeNode<T>)? trailingBuilder;

  /// Signature for generating right-click (desktop) or long-press (mobile) context menus.
  final List<ContextMenuItem> Function(BuildContext, TreeNode<T>)? contextMenuBuilder;

  const SuperTreeNodeWidget({
    super.key,
    required this.node,
    required this.controller,
    required this.style,
    required this.logic,
    required this.prefixBuilder,
    required this.contentBuilder,
    this.trailingBuilder,
    this.contextMenuBuilder,
  });

  @override
  State<SuperTreeNodeWidget<T>> createState() => _SuperTreeNodeWidgetState<T>();
}

class _SuperTreeNodeWidgetState<T> extends State<SuperTreeNodeWidget<T>> with SingleTickerProviderStateMixin {
  bool _isHovering = false;
  late final TextEditingController _renameController;
  late final FocusNode _renameFocusNode;
  late final FocusNode _keyboardListenerFocusNode;
  late final AnimationController _expansionController;
  late final Animation<double> _caretRotation;
  String? _prevRenamingNodeId;

  @override
  void initState() {
    super.initState();
    _renameController = TextEditingController();
    _renameFocusNode = FocusNode();
    _keyboardListenerFocusNode = FocusNode();
    _prevRenamingNodeId = widget.controller.renamingNodeId;

    _expansionController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
      value: widget.node.isExpanded ? 1.0 : 0.0,
    );
    _caretRotation = Tween<double>(begin: 0.0, end: 0.25).animate(
      CurvedAnimation(parent: _expansionController, curve: Curves.easeInOut),
    );
    
    if (_prevRenamingNodeId == widget.node.id) {
      _initializeRenameText();
    }
  }

  @override
  void didUpdateWidget(SuperTreeNodeWidget<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentRenamingId = widget.controller.renamingNodeId;
    
    if (currentRenamingId == widget.node.id && _prevRenamingNodeId != widget.node.id) {
      _initializeRenameText();
    }
    
    if (widget.node.isExpanded != oldWidget.node.isExpanded) {
      if (widget.node.isExpanded) {
        _expansionController.forward();
      } else {
        _expansionController.reverse();
      }
    }

    _prevRenamingNodeId = currentRenamingId;
  }

  void _initializeRenameText() {
    String initialText = widget.node.data.toString();
    try {
      initialText = (widget.node.data as dynamic).name;
    } catch (_) {}
    
    _renameController.text = initialText;
    
    // Select all text in the next frame to ensure it's effective
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.controller.renamingNodeId == widget.node.id) {
        _renameController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _renameController.text.length,
        );
        _renameFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _renameController.dispose();
    _renameFocusNode.dispose();
    _keyboardListenerFocusNode.dispose();
    _expansionController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.logic.namingStrategy == TreeNamingStrategy.click) {
      _startRenaming();
    } else if (widget.logic.expansionTrigger == ExpansionTrigger.tap) {
      widget.controller.toggleNodeExpansion(widget.node);
    }
    widget.logic.onNodeTap?.call(widget.node.id);
  }

  void _handleDoubleTap() {
    if (widget.logic.namingStrategy == TreeNamingStrategy.doubleClick) {
      _startRenaming();
    } else if (widget.logic.expansionTrigger == ExpansionTrigger.doubleTap) {
      widget.controller.toggleNodeExpansion(widget.node);
    }
    widget.logic.onNodeDoubleTap?.call(widget.node.id);
  }

  void _startRenaming() {
    widget.controller.setRenamingNodeId(widget.node.id);
    _initializeRenameText();
  }

  void _submitRename() {
    final newName = _renameController.text.trim();
    if (newName.isNotEmpty) {
      widget.controller.renameNode(widget.node.id, newName);
    } else {
      _cancelRename();
    }
  }

  void _cancelRename() {
    widget.controller.setRenamingNodeId(null);
  }

  void _handleIconTap() {
    widget.controller.toggleNodeExpansion(widget.node);
  }

  void _handleSecondaryTapDown(TapDownDetails details) {
    _showContextMenu(details.globalPosition);
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    _showContextMenu(details.globalPosition);
  }

  void _showContextMenu(Offset position) {
    if (widget.contextMenuBuilder == null) return;

    final items = widget.contextMenuBuilder!(context, widget.node);
    if (items.isEmpty) return;

    widget.controller.setContextMenuNodeId(widget.node.id);

    ContextMenuOverlay.show(
      context: context,
      position: position,
      items: items,
      onDismissed: () {
        if (mounted) {
          widget.controller.setContextMenuNodeId(null);
        }
      },
    );
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
                  child: RotationTransition(
                    turns: _caretRotation,
                    child: widget.prefixBuilder(context, widget.node),
                  ),
                ),
                
                const SizedBox(width: 8),

                // Content 
                Expanded(
                  child: widget.contentBuilder(
                    context,
                    widget.node,
                    widget.controller.renamingNodeId == widget.node.id
                        ? KeyboardListener(
                            focusNode: _keyboardListenerFocusNode,
                            onKeyEvent: (event) {
                              if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
                                _cancelRename();
                              }
                            },
                            child: TextField(
                              controller: _renameController,
                              focusNode: _renameFocusNode,
                              autofocus: true,
                              style: widget.style.textStyle,
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                border: InputBorder.none,
                              ),
                              onSubmitted: (_) => _submitRename(),
                              onTapOutside: (_) => _submitRename(),
                            ),
                          )
                        : null,
                  ),
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
