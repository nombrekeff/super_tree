import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:super_tree/src/configs/tree_view_logic.dart';
import 'package:super_tree/src/configs/tree_view_style.dart';
import 'package:super_tree/src/controllers/tree_controller.dart';
import 'package:super_tree/src/models/tree_node.dart';
import 'package:super_tree/src/widgets/context_menu_overlay.dart';
import 'package:super_tree/src/widgets/super_tree_node_semantics.dart';
import 'package:super_tree/src/widgets/super_tree_rename_field.dart';
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
  }) : assert(expansionSlotSize > 0);

  @override
  State<SuperTreeNodeWidget<T>> createState() => _SuperTreeNodeWidgetState<T>();
}

class _SuperTreeNodeWidgetState<T> extends State<SuperTreeNodeWidget<T>>
    with SingleTickerProviderStateMixin {
  static const double _defaultCaretSize = 20;
  static const double _defaultLoadingSize = 14;
  static const double _defaultLoadingStrokeWidth = 2;

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
      size: _defaultCaretSize,
    );
  }

  Widget _buildDefaultLoadingExpansionIcon() {
    return const SizedBox(
      width: _defaultLoadingSize,
      height: _defaultLoadingSize,
      child: CircularProgressIndicator(strokeWidth: _defaultLoadingStrokeWidth),
    );
  }

  Widget _buildExpansionIcon(BuildContext context) {
    final TreeNodeAsyncState asyncState = widget.controller.getNodeAsyncState(
      widget.node.id,
    );
    if (asyncState.isLoading) {
      return widget.loadingExpansionBuilder?.call(context, widget.node) ??
          _buildDefaultLoadingExpansionIcon();
    }

    final Widget icon =
        widget.expansionBuilder?.call(context, widget.node) ??
        _buildDefaultExpansionIcon();
    return RotationTransition(turns: _caretRotation, child: icon);
  }

  Widget _buildExpansionSlot(BuildContext context) {
    final Widget slotChild = _buildExpansionIcon(context);
    return SizedBox(
      width: widget.expansionSlotSize,
      height: widget.expansionSlotSize,
      child: Center(child: slotChild),
    );
  }

  Widget _buildRenameField(BuildContext context) {
    final Color selectionColor = Theme.of(context).colorScheme.primary.withAlpha(
      77,
    );
    final Color cursorColor = Theme.of(context).colorScheme.primary;
    final TextStyle? renameStyle =
        widget.style.labelStyle ??
        widget.style.textStyle ??
        Theme.of(context).textTheme.bodyMedium;

    return SuperTreeRenameField(
      controller: _renameController,
      textFieldFocusNode: _renameFocusNode,
      keyboardFocusNode: _keyboardListenerFocusNode,
      style: renameStyle,
      selectionColor: selectionColor,
      cursorColor: cursorColor,
      onEscape: _cancelRename,
      onSubmitted: _submitRename,
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

  List<TreeNode<T>> _resolveDragNodes(bool isSelected) {
    final bool canUseMultiSelection =
        widget.logic.selectionMode == SelectionMode.multiple;
    if (!canUseMultiSelection || !isSelected) {
      return <TreeNode<T>>[widget.node];
    }

    final List<TreeNode<T>> selectedNodes = widget.controller
        .getSelectedNodesInVisibleOrder(topLevelOnly: true);
    if (selectedNodes.length <= 1) {
      return <TreeNode<T>>[widget.node];
    }

    final bool containsCurrentNode = selectedNodes.any(
      (TreeNode<T> node) => node.id == widget.node.id,
    );
    if (!containsCurrentNode) {
      return <TreeNode<T>>[widget.node];
    }

    return selectedNodes;
  }

  void _handleDrop(
    TreeDragPayload<T> payload,
    TreeNode<T> targetNode,
    NodeDropPosition position,
  ) {
    final List<TreeNode<T>> draggedNodes = payload.nodes;
    final bool insertBefore = position == NodeDropPosition.above;
    final bool nestInside = position == NodeDropPosition.inside;

    if (draggedNodes.length > 1) {
      widget.controller.moveNodes(
        draggedNodes: draggedNodes,
        target: targetNode,
        insertBefore: insertBefore,
        nestInside: nestInside,
      );
      return;
    }

    widget.controller.moveNode(
      dragged: payload.primaryNode,
      target: targetNode,
      insertBefore: insertBefore,
      nestInside: nestInside,
    );
  }

  @override
  Widget build(BuildContext context) {
    final double paddingLeft = widget.style.indentAmount * widget.node.depth;
    final bool canExpand =
        widget.node.hasChildren || widget.controller.canNodeLoadChildren(widget.node);
    final bool isSelected = widget.controller.selectedNodeIds.contains(widget.node.id);
    final TreeIntegrityIssue? integrityIssue = widget.controller.getIntegrityIssueForNode(
      widget.node.id,
    );
    final List<TreeNode<T>> dragNodes = _resolveDragNodes(isSelected);

    return TreeDragAndDropWrapper<T>(
      node: widget.node,
      enabled: widget.logic.enableDragAndDrop,
      dragNodes: dragNodes,
      style: widget.style,
      edgeDropBandFraction: widget.logic.dropEdgeBandFraction,
      edgeDropBandFractionForLeaf: widget.logic.dropEdgeBandFractionForLeaf,
      dropPositionHysteresisPx: widget.logic.dropPositionHysteresisPx,
      enableAutoScroll: widget.logic.enableDragAutoScroll,
      autoScrollEdgeThresholdPx: widget.logic.dragAutoScrollEdgeThresholdPx,
      autoScrollMaxStepPx: widget.logic.dragAutoScrollMaxStepPx,
      canAcceptDrop: widget.logic.canAcceptDrop,
      canAcceptDropMany: widget.logic.canAcceptDropMany,
      onDrop: _handleDrop,
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
          child: SuperTreeNodeSemantics<T>(
            node: widget.node,
            canExpand: canExpand,
            isSelected: isSelected,
            labelProvider: widget.labelProvider,
            child: Container(
              padding: EdgeInsets.only(
                left: widget.style.padding.horizontal / 2 + paddingLeft,
                right: widget.style.padding.horizontal / 2,
                top: widget.style.padding.vertical / 2,
                bottom: widget.style.padding.vertical / 2,
              ),
              decoration: BoxDecoration(
                color: isSelected
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
                          ? _buildRenameField(context)
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
      ),
    );
  }
}
