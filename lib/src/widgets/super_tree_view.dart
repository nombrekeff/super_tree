import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:super_tree/src/configs/tree_view_logic.dart';
import 'package:super_tree/src/configs/tree_view_style.dart';
import 'package:super_tree/src/controllers/tree_controller.dart';
import 'package:super_tree/src/models/tree_node.dart';
import 'package:super_tree/src/widgets/context_menu_overlay.dart';
import 'package:super_tree/src/widgets/super_tree_interaction_surface.dart';
import 'package:super_tree/src/widgets/super_tree_node_list.dart';
import 'package:super_tree/src/widgets/super_tree_node_widget.dart';

class _TreeSelectNextIntent extends Intent {
  const _TreeSelectNextIntent();
}

class _TreeSelectPreviousIntent extends Intent {
  const _TreeSelectPreviousIntent();
}

class _TreeExpandOrTraverseIntent extends Intent {
  const _TreeExpandOrTraverseIntent();
}

class _TreeCollapseOrParentIntent extends Intent {
  const _TreeCollapseOrParentIntent();
}

class _TreeSelectFirstIntent extends Intent {
  const _TreeSelectFirstIntent();
}

class _TreeSelectLastIntent extends Intent {
  const _TreeSelectLastIntent();
}

class _TreePrimaryActionIntent extends Intent {
  const _TreePrimaryActionIntent();
}

class _TreeToggleExpansionIntent extends Intent {
  const _TreeToggleExpansionIntent();
}

class _TreeExtendSelectionNextIntent extends Intent {
  const _TreeExtendSelectionNextIntent();
}

class _TreeExtendSelectionPreviousIntent extends Intent {
  const _TreeExtendSelectionPreviousIntent();
}

/// The entry point for rendering the tree view.
///
/// This widget observes a [TreeController] and renders nodes in a highly efficient
/// flat List using `ListView.builder`.
class SuperTreeView<T> extends StatefulWidget {
  /// The controller used to manipulate the tree.
  /// If not provided, an internal controller will be created using [roots] and [sortComparator].
  final TreeController<T>? controller;

  /// The root nodes of the tree.
  /// Used to seed the default controller if [controller] is not provided.
  final List<TreeNode<T>>? roots;

  /// Optional comparator to keep the tree sorted.
  /// Used by the default controller if [controller] is not provided.
  final int Function(TreeNode<T> a, TreeNode<T> b)? sortComparator;

  /// Defines visual properties like colors, paddings, and indentations.
  final TreeViewStyle style;

  /// Defines behavior properties like expansion triggers and selectability.
  final TreeViewConfig<T> logic;

  /// Builds the expansion widget (e.g. caret icon).
  final Widget Function(BuildContext, TreeNode<T>)? expansionBuilder;

  /// Builds the expansion widget while a node is loading children.
  ///
  /// If null, a compact [CircularProgressIndicator] is used by default.
  final Widget Function(BuildContext, TreeNode<T>)? loadingExpansionBuilder;

  /// Fixed width/height reserved for the expansion slot.
  ///
  /// Keeping this slot stable avoids row-width jitter while switching between
  /// caret and loading indicator states.
  final double expansionSlotSize;

  /// Builds the prefix widget (e.g. file icon).
  final Widget Function(BuildContext, TreeNode<T>) prefixBuilder;

  /// Optional provider to extract a display label from node data.
  /// Used as a fallback if no [contentBuilder] is provided or in default implementations.
  final TreeLabelProvider<T>? labelProvider;

  /// Builds the main content area of the node (e.g. text label, checkbox).
  ///
  /// The [renameField] is provided when the node is in renaming mode.
  /// If [renameField] is not null, it should be displayed instead of the normal content.
  final Widget Function(
    BuildContext context,
    TreeNode<T> node,
    Widget? renameField,
  )
  contentBuilder;

  /// Builds optional trailing widgets (e.g. a 'more options' popup menu icon).
  final Widget Function(BuildContext, TreeNode<T>)? trailingBuilder;

  /// Optional function called when right-clicking (desktop) or long-pressing (mobile) a node.
  /// Returns a list of [ContextMenuItem]s to display in the overlay.
  final List<ContextMenuItem> Function(BuildContext, TreeNode<T>)?
  contextMenuBuilder;

  /// Optional function called when right-clicking (desktop) or long-pressing (mobile) the tree background.
  /// Returns a list of [ContextMenuItem]s to display in the overlay for root-level actions.
  final List<ContextMenuItem> Function(BuildContext)? rootContextMenuBuilder;

  /// Custom [ScrollController] for the internal ListView.
  final ScrollController? scrollController;

  /// The scroll physics applied to the internal ListView.
  final ScrollPhysics? physics;

  /// Internal separator builder for the separated constructor.
  final Widget Function(BuildContext, int)? _separatorBuilder;

  /// Standard constructor for [SuperTreeView].
  const SuperTreeView({
    super.key,
    this.controller,
    this.roots,
    this.sortComparator,
    this.expansionBuilder,
    this.loadingExpansionBuilder,
    this.expansionSlotSize = 20,
    required this.prefixBuilder,
    required this.contentBuilder,
    this.labelProvider,
    this.trailingBuilder,
    this.contextMenuBuilder,
    this.rootContextMenuBuilder,
    this.scrollController,
    this.physics,
    this.style = const TreeViewStyle(),
    this.logic = const TreeViewConfig(),
  }) : assert(expansionSlotSize > 0),
       _separatorBuilder = null;

  /// Convenience constructor to inject dividers between nodes using [ListView.separated].
  factory SuperTreeView.separated({
    Key? key,
    TreeController<T>? controller,
    List<TreeNode<T>>? roots,
    int Function(TreeNode<T> a, TreeNode<T> b)? sortComparator,
    Widget Function(BuildContext, TreeNode<T>)? expansionBuilder,
    Widget Function(BuildContext, TreeNode<T>)? loadingExpansionBuilder,
    double expansionSlotSize = 20,
    required Widget Function(BuildContext, TreeNode<T>) prefixBuilder,
    required Widget Function(
      BuildContext context,
      TreeNode<T> node,
      Widget? renameField,
    )
    contentBuilder,
    required Widget Function(BuildContext, int) separatorBuilder,
    TreeLabelProvider<T>? labelProvider,
    Widget Function(BuildContext, TreeNode<T>)? trailingBuilder,
    List<ContextMenuItem> Function(BuildContext, TreeNode<T>)?
    contextMenuBuilder,
    List<ContextMenuItem> Function(BuildContext)? rootContextMenuBuilder,
    ScrollController? scrollController,
    ScrollPhysics? physics,
    TreeViewStyle style = const TreeViewStyle(),
    TreeViewConfig<T> logic = const TreeViewConfig(),
  }) {
    return SuperTreeView<T>._separated(
      key: key,
      controller: controller,
      roots: roots,
      sortComparator: sortComparator,
      expansionBuilder: expansionBuilder,
      loadingExpansionBuilder: loadingExpansionBuilder,
      expansionSlotSize: expansionSlotSize,
      prefixBuilder: prefixBuilder,
      contentBuilder: contentBuilder,
      labelProvider: labelProvider,
      separatorBuilder: separatorBuilder,
      trailingBuilder: trailingBuilder,
      contextMenuBuilder: contextMenuBuilder,
      rootContextMenuBuilder: rootContextMenuBuilder,
      scrollController: scrollController,
      physics: physics,
      style: style,
      logic: logic,
    );
  }

  /// Private constructor for [SuperTreeView.separated].
  const SuperTreeView._separated({
    super.key,
    this.controller,
    this.roots,
    this.sortComparator,
    this.expansionBuilder,
    this.loadingExpansionBuilder,
    this.expansionSlotSize = 20,
    required this.prefixBuilder,
    required this.contentBuilder,
    required Widget Function(BuildContext, int) separatorBuilder,
    this.labelProvider,
    this.trailingBuilder,
    this.contextMenuBuilder,
    this.rootContextMenuBuilder,
    this.scrollController,
    this.physics,
    this.style = const TreeViewStyle(),
    this.logic = const TreeViewConfig(),
  }) : assert(expansionSlotSize > 0),
       _separatorBuilder = separatorBuilder;

  @override
  State<SuperTreeView<T>> createState() => _SuperTreeViewState<T>();
}

class _SuperTreeViewState<T> extends State<SuperTreeView<T>> {
  late TreeController<T> _internalController;
  late bool _ownsController;

  late final FocusNode _focusNode;
  late final VoidCallback _focusManagerListener;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusManagerListener = _handleFocusManagerChange;
    FocusManager.instance.addListener(_focusManagerListener);
    _initController();
  }

  void _handleFocusManagerChange() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  bool _isEditableTextFocused() {
    final BuildContext? focusContext = FocusManager.instance.primaryFocus?.context;
    if (focusContext == null) {
      return false;
    }

    final Widget focusedWidget = focusContext.widget;
    if (focusedWidget is EditableText) {
      return true;
    }

    return focusContext.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  void _initController() {
    _ownsController = widget.controller == null;
    _internalController =
        widget.controller ??
        TreeController<T>(
          roots: widget.roots,
          sortComparator:
              widget.sortComparator ?? widget.logic.defaultSortComparator,
        );

    if (widget.logic.debugMode) {
      debugPrint(
        '[SuperTreeView] Initialized with ${_ownsController ? "internal" : "external"} controller: ${_internalController.hashCode}',
      );
    }
  }

  @override
  void didUpdateWidget(SuperTreeView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    final controllerChanged = widget.controller != oldWidget.controller;

    if (controllerChanged) {
      if (widget.logic.debugMode) {
        debugPrint(
          '[SuperTreeView] Controller changed. Old: ${oldWidget.controller?.hashCode}, New: ${widget.controller?.hashCode}',
        );
      }

      if (_ownsController) {
        if (widget.logic.debugMode) {
          debugPrint(
            '[SuperTreeView] Disposing internal controller: ${_internalController.hashCode}',
          );
        }
        _internalController.dispose();
      }
      _initController();
    } else if (_ownsController) {
      if (widget.sortComparator != oldWidget.sortComparator) {
        if (widget.logic.debugMode) {
          debugPrint(
            '[SuperTreeView] Updating internal controller sort comparator',
          );
        }
        _internalController.sortComparator = widget.sortComparator;
      }
    }
  }

  @override
  void dispose() {
    if (widget.logic.debugMode) {
      debugPrint(
        '[SuperTreeView] Disposing widget state. Owns controller: $_ownsController',
      );
    }

    FocusManager.instance.removeListener(_focusManagerListener);
    if (_ownsController) {
      _internalController.dispose();
    }
    _focusNode.dispose();
    super.dispose();
  }

  Map<ShortcutActivator, Intent> _buildShortcuts() {
    if (_internalController.renamingNodeId != null || _isEditableTextFocused()) {
      return const <ShortcutActivator, Intent>{};
    }

    return <ShortcutActivator, Intent>{
      const SingleActivator(LogicalKeyboardKey.arrowDown):
          const _TreeSelectNextIntent(),
      const SingleActivator(LogicalKeyboardKey.arrowDown, shift: true):
          const _TreeExtendSelectionNextIntent(),
      const SingleActivator(LogicalKeyboardKey.arrowUp):
          const _TreeSelectPreviousIntent(),
      const SingleActivator(LogicalKeyboardKey.arrowUp, shift: true):
          const _TreeExtendSelectionPreviousIntent(),
      const SingleActivator(LogicalKeyboardKey.arrowRight):
          const _TreeExpandOrTraverseIntent(),
      const SingleActivator(LogicalKeyboardKey.arrowLeft):
          const _TreeCollapseOrParentIntent(),
      const SingleActivator(LogicalKeyboardKey.home):
          const _TreeSelectFirstIntent(),
      const SingleActivator(LogicalKeyboardKey.end):
          const _TreeSelectLastIntent(),
      const SingleActivator(LogicalKeyboardKey.enter):
          const _TreePrimaryActionIntent(),
      const SingleActivator(LogicalKeyboardKey.space):
          const _TreeToggleExpansionIntent(),
    };
  }

  Map<Type, Action<Intent>> _buildActions() {
    return <Type, Action<Intent>>{
      _TreeSelectNextIntent: CallbackAction<_TreeSelectNextIntent>(
        onInvoke: (_TreeSelectNextIntent intent) => _onSelectNext(),
      ),
      _TreeSelectPreviousIntent: CallbackAction<_TreeSelectPreviousIntent>(
        onInvoke: (_TreeSelectPreviousIntent intent) => _onSelectPrevious(),
      ),
      _TreeExpandOrTraverseIntent: CallbackAction<_TreeExpandOrTraverseIntent>(
        onInvoke: (_TreeExpandOrTraverseIntent intent) => _onExpandOrTraverse(),
      ),
      _TreeCollapseOrParentIntent: CallbackAction<_TreeCollapseOrParentIntent>(
        onInvoke: (_TreeCollapseOrParentIntent intent) => _onCollapseOrParent(),
      ),
      _TreeSelectFirstIntent: CallbackAction<_TreeSelectFirstIntent>(
        onInvoke: (_TreeSelectFirstIntent intent) => _onSelectFirst(),
      ),
      _TreeSelectLastIntent: CallbackAction<_TreeSelectLastIntent>(
        onInvoke: (_TreeSelectLastIntent intent) => _onSelectLast(),
      ),
      _TreePrimaryActionIntent: CallbackAction<_TreePrimaryActionIntent>(
        onInvoke: (_TreePrimaryActionIntent intent) => _onPrimaryAction(),
      ),
      _TreeToggleExpansionIntent: CallbackAction<_TreeToggleExpansionIntent>(
        onInvoke: (_TreeToggleExpansionIntent intent) => _onToggleExpansion(),
      ),
      _TreeExtendSelectionNextIntent:
          CallbackAction<_TreeExtendSelectionNextIntent>(
            onInvoke: (_TreeExtendSelectionNextIntent intent) =>
                _onExtendSelectionNext(),
          ),
      _TreeExtendSelectionPreviousIntent:
          CallbackAction<_TreeExtendSelectionPreviousIntent>(
            onInvoke: (_TreeExtendSelectionPreviousIntent intent) =>
                _onExtendSelectionPrevious(),
          ),
    };
  }

  Object? _onSelectNext() {
    _internalController.selectNext();
    return null;
  }

  Object? _onSelectPrevious() {
    _internalController.selectPrevious();
    return null;
  }

  Object? _onExpandOrTraverse() {
    final String? selectedId = _internalController.selectedNodeId;
    if (selectedId == null) {
      return null;
    }

    final TreeNode<T>? node = _internalController.findNodeById(selectedId);
    if (node == null) {
      return null;
    }

    final bool canExpand =
        node.hasChildren || _internalController.canNodeLoadChildren(node);
    if (!canExpand) {
      return null;
    }

    if (!node.isExpanded) {
      _internalController.toggleNodeExpansion(node);
    } else {
      _internalController.selectNext();
    }

    return null;
  }

  Object? _onCollapseOrParent() {
    final String? selectedId = _internalController.selectedNodeId;
    if (selectedId == null) {
      return null;
    }

    final TreeNode<T>? node = _internalController.findNodeById(selectedId);
    if (node == null) {
      return null;
    }

    if (node.isExpanded) {
      _internalController.collapseNode(node);
      return null;
    }

    if (!node.isRoot && node.parent != null) {
      _internalController.setSelectedNodeId(node.parent!.id);
    }

    return null;
  }

  Object? _onSelectFirst() {
    _internalController.selectFirst();
    return null;
  }

  Object? _onSelectLast() {
    _internalController.selectLast();
    return null;
  }

  Object? _onPrimaryAction() {
    final String? selectedId = _internalController.selectedNodeId;
    if (selectedId == null) {
      return null;
    }

    if (widget.logic.namingStrategy != TreeNamingStrategy.none) {
      _internalController.setRenamingNodeId(selectedId);
      return null;
    }

    final TreeNode<T>? node = _internalController.findNodeById(selectedId);
    if (node != null) {
      _internalController.toggleNodeExpansion(node);
    }

    return null;
  }

  Object? _onToggleExpansion() {
    final String? selectedId = _internalController.selectedNodeId;
    if (selectedId == null) {
      return null;
    }

    final TreeNode<T>? node = _internalController.findNodeById(selectedId);
    if (node != null) {
      _internalController.toggleNodeExpansion(node);
    }

    return null;
  }

  Object? _onExtendSelectionNext() {
    final List<TreeNode<T>> nodes = _internalController.flatVisibleNodes;
    if (nodes.isEmpty) {
      return null;
    }

    final String? selectedId = _internalController.selectedNodeId;
    if (selectedId == null) {
      _internalController.setSelectedNodeId(nodes.first.id);
      return null;
    }

    final int currentIndex = nodes.indexWhere(
      (TreeNode<T> n) => n.id == selectedId,
    );
    if (currentIndex == -1 || currentIndex >= nodes.length - 1) {
      return null;
    }

    _internalController.selectRange(nodes[currentIndex + 1].id);
    return null;
  }

  Object? _onExtendSelectionPrevious() {
    final List<TreeNode<T>> nodes = _internalController.flatVisibleNodes;
    if (nodes.isEmpty) {
      return null;
    }

    final String? selectedId = _internalController.selectedNodeId;
    if (selectedId == null) {
      _internalController.setSelectedNodeId(nodes.last.id);
      return null;
    }

    final int currentIndex = nodes.indexWhere(
      (TreeNode<T> n) => n.id == selectedId,
    );
    if (currentIndex <= 0) {
      return null;
    }

    _internalController.selectRange(nodes[currentIndex - 1].id);
    return null;
  }

  Widget _buildNodeItem(TreeNode<T> node) {
    return SuperTreeNodeWidget<T>(
      key: ValueKey(node.id),
      node: node,
      controller: _internalController,
      style: widget.style,
      logic: widget.logic,
      expansionBuilder: widget.expansionBuilder,
      loadingExpansionBuilder: widget.loadingExpansionBuilder,
      expansionSlotSize: widget.expansionSlotSize,
      prefixBuilder: widget.prefixBuilder,
      labelProvider: widget.labelProvider,
      contentBuilder: widget.contentBuilder,
      trailingBuilder: widget.trailingBuilder,
      contextMenuBuilder: widget.contextMenuBuilder,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SuperTreeInteractionSurface(
      focusNode: _focusNode,
      shortcuts: _buildShortcuts(),
      actions: _buildActions(),
      onRequestFocus: _focusNode.requestFocus,
      onBackgroundTap: _internalController.deselectAll,
      onOpenContextMenu: _showRootContextMenu,
      child: SuperTreeNodeList<T>(
        controller: _internalController,
        itemBuilder: _buildNodeItem,
        separatorBuilder: widget._separatorBuilder,
        scrollController: widget.scrollController,
        physics: widget.physics,
      ),
    );
  }

  void _showRootContextMenu(Offset position) {
    if (widget.rootContextMenuBuilder == null) return;

    final items = widget.rootContextMenuBuilder!(context);
    if (items.isEmpty) return;

    ContextMenuOverlay.show(context: context, position: position, items: items);
  }
}
