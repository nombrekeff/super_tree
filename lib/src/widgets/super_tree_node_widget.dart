import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:super_tree/src/configs/tree_view_logic.dart';
import 'package:super_tree/src/configs/tree_view_style.dart';
import 'package:super_tree/src/controllers/tree_controller.dart';
import 'package:super_tree/src/models/tree_node.dart';
import 'package:super_tree/src/widgets/context_menu_overlay.dart';
import 'package:super_tree/src/widgets/tree_drag_and_drop_wrapper.dart';

/// Renders a single node row in the [SuperTreeView].
class SuperTreeNodeWidget<T> extends StatefulWidget {
  final TreeNode<T> node;
  final TreeController<T> controller;
  final TreeViewStyle style;
  final TreeViewConfig<T> logic;

  /// Builds the expansion widget (e.g. caret icon).
  /// If null, a default [Icons.keyboard_arrow_right] is used.
  final Widget Function(BuildContext, TreeNode<T>)? expansionBuilder;

  /// Builds the expansion widget while a node is loading children.
  final Widget Function(BuildContext, TreeNode<T>)? loadingExpansionBuilder;

  /// Reserved width/height for the expansion slot.
  final double expansionSlotSize;

  final Widget Function(BuildContext, TreeNode<T>) prefixBuilder;
  final TreeLabelProvider<T>? labelProvider;
  final Widget Function(BuildContext context, TreeNode<T> node, Widget? renameField)
  contentBuilder;
  final Widget Function(BuildContext, TreeNode<T>)? trailingBuilder;

  /// Signature for generating right-click (desktop) or long-press (mobile) context menus.
  final List<ContextMenuItem> Function(BuildContext, TreeNode<T>)? contextMenuBuilder;

  const SuperTreeNodeWidget({
    super.key,
    required this.node,
    required this.controller,
    required this.style,
    required this.logic,
    this.expansionBuilder,
    this.loadingExpansionBuilder,
    this.expansionSlotSize = 20,
    required this.prefixBuilder,
    this.labelProvider,
    required this.contentBuilder,
    this.trailingBuilder,
    this.contextMenuBuilder,
  });

  @override
  State<SuperTreeNodeWidget<T>> createState() => _SuperTreeNodeWidgetState<T>();
}

class _SuperTreeNodeWidgetState<T> extends State<SuperTreeNodeWidget<T>>
    with SingleTickerProviderStateMixin {
  bool _isHovering = false;
  late final TextEditingController _renameController;
  late final FocusNode _renameFocusNode;
  late final FocusNode _keyboardListenerFocusNode;
  late final AnimationController _expansionController;
  late final Animation<double> _caretRotation;
  bool _isExpanded = false;
  String? _prevRenamingNodeId;

  @override
  void initState() {
    super.initState();
    _renameController = TextEditingController();
    _renameFocusNode = FocusNode();
    _keyboardListenerFocusNode = FocusNode();
    _prevRenamingNodeId = widget.controller.renamingNodeId;

    _isExpanded = widget.node.isExpanded;
    _expansionController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
      value: _isExpanded ? 1.0 : 0.0,
    );
    _caretRotation = Tween<double>(
      begin: 0.0,
      end: 0.25,
    ).animate(CurvedAnimation(parent: _expansionController, curve: Curves.easeInOut));

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

    if (widget.node.isExpanded != _isExpanded) {
      _isExpanded = widget.node.isExpanded;
      if (_isExpanded) {
        _expansionController.forward();
      } else {
        _expansionController.reverse();
      }
    }

    _prevRenamingNodeId = currentRenamingId;
  }

  void _initializeRenameText() {
    String initialText = '';

    if (widget.labelProvider != null) {
      initialText = widget.labelProvider!(widget.node.data);
    } else {
      initialText = widget.node.data.toString();
      try {
        initialText = (widget.node.data as dynamic).name;
      } catch (_) {}
    }

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
    final bool isMultiSelect = widget.logic.selectionMode == SelectionMode.multiple;
    final bool isControlPressed =
        HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed;
    final bool isShiftPressed = HardwareKeyboard.instance.isShiftPressed;

    if (isMultiSelect && isShiftPressed) {
      widget.controller.selectRange(widget.node.id);
    } else if (isMultiSelect && isControlPressed) {
      widget.controller.toggleSelection(widget.node.id);
    } else if (widget.logic.selectionMode != SelectionMode.none) {
      widget.controller.setSelectedNodeId(widget.node.id);
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
    final wasNew = widget.node.isNew;
    widget.controller.setRenamingNodeId(null);
    if (wasNew) {
      widget.controller.removeNode(widget.node);
    }
  }

  void _handleIconTap() {
    widget.controller.toggleNodeExpansion(widget.node);
  }

  Widget _buildDefaultExpansionIcon() {
    return const Icon(
      Icons.keyboard_arrow_right,
      color: Colors.grey,
      size: 20,
    );
  }

  Widget _buildDefaultLoadingExpansionIcon() {
    return const SizedBox(
      width: 14,
      height: 14,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }

  Widget _buildExpansionSlot(BuildContext context) {
    final TreeNodeAsyncState asyncState = widget.controller.getNodeAsyncState(
      widget.node.id,
    );
    final Widget slotChild;

    if (asyncState.isLoading) {
      slotChild =
          widget.loadingExpansionBuilder?.call(context, widget.node) ??
          _buildDefaultLoadingExpansionIcon();
    } else {
      final Widget icon =
          widget.expansionBuilder?.call(context, widget.node) ??
          _buildDefaultExpansionIcon();
      slotChild = RotationTransition(turns: _caretRotation, child: icon);
    }

    return SizedBox(
      width: widget.expansionSlotSize,
      height: widget.expansionSlotSize,
      child: Center(child: slotChild),
    );
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
    final bool canExpand =
        widget.node.hasChildren || widget.controller.canNodeLoadChildren(widget.node);
    final TreeIntegrityIssue? integrityIssue = widget.controller.getIntegrityIssueForNode(
      widget.node.id,
    );

    return TreeDragAndDropWrapper<T>(
      node: widget.node,
      enabled: widget.logic.enableDragAndDrop,
      style: widget.style,
      edgeDropBandFraction: widget.logic.dropEdgeBandFraction,
      edgeDropBandFractionForLeaf: widget.logic.dropEdgeBandFractionForLeaf,
      dropPositionHysteresisPx: widget.logic.dropPositionHysteresisPx,
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
          onDoubleTap:
              (widget.logic.expansionTrigger == ExpansionTrigger.doubleTap ||
                  widget.logic.onNodeDoubleTap != null)
              ? _handleDoubleTap
              : null,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: EdgeInsets.only(
              left: widget.style.padding.horizontal / 2 + paddingLeft,
              right: widget.style.padding.horizontal / 2,
              top: widget.style.padding.vertical / 2,
              bottom: widget.style.padding.vertical / 2,
            ),
            decoration: BoxDecoration(
              color: widget.controller.selectedNodeIds.contains(widget.node.id)
                  ? widget.style.selectedColor
                  : (_isHovering || widget.controller.contextMenuNodeId == widget.node.id)
                  ? widget.style.hoverColor
                  : widget.style.idleColor,
              border: Border.all(
                color: widget.controller.renamingNodeId == widget.node.id
                    ? Theme.of(context).colorScheme.primary.withAlpha(204)
                    : Colors.transparent,
                width: 2.0,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (canExpand)
                  GestureDetector(
                    onTap: _handleIconTap,
                    behavior: HitTestBehavior.opaque,
                    child: KeyedSubtree(
                      key: Key('expansion_caret_${widget.node.id}'),
                      child: _buildExpansionSlot(context),
                    ),
                  )
                else
                  SizedBox(width: widget.expansionSlotSize),

                // Prefix (e.g. File/Folder icon)
                widget.prefixBuilder(context, widget.node),

                const SizedBox(width: 8),

                // Content
                Expanded(
                  child: widget.contentBuilder(
                    context,
                    widget.node,
                    widget.controller.renamingNodeId == widget.node.id
                        ? TextSelectionTheme(
                            data: TextSelectionThemeData(
                              selectionColor: Theme.of(
                                context,
                              ).colorScheme.primary.withAlpha(77),
                              cursorColor: Theme.of(context).colorScheme.primary,
                            ),
                            child: KeyboardListener(
                              focusNode: _keyboardListenerFocusNode,
                              onKeyEvent: (event) {
                                if (event is KeyDownEvent &&
                                    event.logicalKey == LogicalKeyboardKey.escape) {
                                  _cancelRename();
                                }
                              },
                              child: TextField(
                                controller: _renameController,
                                focusNode: _renameFocusNode,
                                autofocus: true,
                                style:
                                    widget.style.labelStyle ??
                                    widget.style.textStyle ??
                                    Theme.of(context).textTheme.bodyMedium,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  border: InputBorder.none,
                                ),
                                onSubmitted: (_) => _submitRename(),
                                onTapOutside: (_) => _submitRename(),
                              ),
                            ),
                          )
                        : null,
                  ),
                ),

                if (integrityIssue != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Tooltip(
                      message: integrityIssue.message,
                      child: Icon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.error,
                        size: 16,
                      ),
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
