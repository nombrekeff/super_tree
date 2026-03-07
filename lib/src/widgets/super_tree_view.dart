import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:super_tree/src/configs/tree_view_logic.dart';
import 'package:super_tree/src/configs/tree_view_style.dart';
import 'package:super_tree/src/controllers/tree_controller.dart';
import 'package:super_tree/src/models/tree_node.dart';
import 'package:super_tree/src/widgets/context_menu_overlay.dart';
import 'package:super_tree/src/widgets/super_tree_node_widget.dart';

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

  /// Builds the prefix widget (e.g. file icon).
  final Widget Function(BuildContext, TreeNode<T>) prefixBuilder;

  /// Optional provider to extract a display label from node data.
  /// Used as a fallback if no [contentBuilder] is provided or in default implementations.
  final TreeLabelProvider<T>? labelProvider;

  /// Builds the main content area of the node (e.g. text label, checkbox).
  /// 
  /// The [renameField] is provided when the node is in renaming mode. 
  /// If [renameField] is not null, it should be displayed instead of the normal content.
  final Widget Function(BuildContext context, TreeNode<T> node, Widget? renameField) contentBuilder;

  /// Builds optional trailing widgets (e.g. a 'more options' popup menu icon).
  final Widget Function(BuildContext, TreeNode<T>)? trailingBuilder;

  /// Optional function called when right-clicking (desktop) or long-pressing (mobile) a node.
  /// Returns a list of [ContextMenuItem]s to display in the overlay.
  final List<ContextMenuItem> Function(BuildContext, TreeNode<T>)? contextMenuBuilder;

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
  })  : _separatorBuilder = null;

  /// Convenience constructor to inject dividers between nodes using [ListView.separated].
  factory SuperTreeView.separated({
    Key? key,
    TreeController<T>? controller,
    List<TreeNode<T>>? roots,
    int Function(TreeNode<T> a, TreeNode<T> b)? sortComparator,
    Widget Function(BuildContext, TreeNode<T>)? expansionBuilder,
    required Widget Function(BuildContext, TreeNode<T>) prefixBuilder,
    required Widget Function(BuildContext context, TreeNode<T> node, Widget? renameField) contentBuilder,
    required Widget Function(BuildContext, int) separatorBuilder,
    TreeLabelProvider<T>? labelProvider,
    Widget Function(BuildContext, TreeNode<T>)? trailingBuilder,
    List<ContextMenuItem> Function(BuildContext, TreeNode<T>)? contextMenuBuilder,
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
  })  : _separatorBuilder = separatorBuilder;

  @override
  State<SuperTreeView<T>> createState() => _SuperTreeViewState<T>();
}

class _SuperTreeViewState<T> extends State<SuperTreeView<T>> {
  late TreeController<T> _internalController;
  late bool _ownsController;

  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _initController();
  }

  void _initController() {
    _ownsController = widget.controller == null;
    _internalController = widget.controller ??
        TreeController<T>(
          roots: widget.roots,
          sortComparator: widget.sortComparator ?? widget.logic.defaultSortComparator,
        );
    
    if (widget.logic.debugMode) {
      debugPrint('[SuperTreeView] Initialized with ${_ownsController ? "internal" : "external"} controller: ${_internalController.hashCode}');
    }
  }

  @override
  void didUpdateWidget(SuperTreeView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    final controllerChanged = widget.controller != oldWidget.controller;
    
    if (controllerChanged) {
      if (widget.logic.debugMode) {
        debugPrint('[SuperTreeView] Controller changed. Old: ${oldWidget.controller?.hashCode}, New: ${widget.controller?.hashCode}');
      }
      
      if (_ownsController) {
        if (widget.logic.debugMode) {
          debugPrint('[SuperTreeView] Disposing internal controller: ${_internalController.hashCode}');
        }
        _internalController.dispose();
      }
      _initController();
    } else if (_ownsController) {
      if (widget.sortComparator != oldWidget.sortComparator) {
        if (widget.logic.debugMode) {
          debugPrint('[SuperTreeView] Updating internal controller sort comparator');
        }
        _internalController.sortComparator = widget.sortComparator;
      }
    }
  }

  @override
  void dispose() {
    if (widget.logic.debugMode) {
      debugPrint('[SuperTreeView] Disposing widget state. Owns controller: $_ownsController');
    }
    
    if (_ownsController) {
      _internalController.dispose();
    }
    _focusNode.dispose();
    super.dispose();
  }

  // TODO: Refactor this into reusable widget or utility. As there will be more places that will use shortctus.
  //  check if we could do this with flutter shortcuts or something.
  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return false;
    }

    final controller = _internalController;
    final logicalKey = event.logicalKey;

    if (logicalKey == LogicalKeyboardKey.arrowDown) {
      controller.selectNext();
      return true;
    } else if (logicalKey == LogicalKeyboardKey.arrowUp) {
      controller.selectPrevious();
      return true;
    } else if (logicalKey == LogicalKeyboardKey.arrowRight) {
      final selectedId = controller.selectedNodeId;
      if (selectedId != null) {
        final node = controller.findNodeById(selectedId);
        if (node != null) {
          final bool canExpand =
              node.hasChildren || controller.canNodeLoadChildren(node);
          if (canExpand) {
            if (!node.isExpanded) {
              controller.toggleNodeExpansion(node);
            } else {
              controller.selectNext();
            }
          }
        }
      }
      return true;
    } else if (logicalKey == LogicalKeyboardKey.arrowLeft) {
      final selectedId = controller.selectedNodeId;
      if (selectedId != null) {
        final node = controller.findNodeById(selectedId);
        if (node != null) {
          if (node.isExpanded) {
            controller.collapseNode(node);
          } else if (!node.isRoot) {
            controller.setSelectedNodeId(node.parent!.id);
          }
        }
      }
      return true;
    } else if (logicalKey == LogicalKeyboardKey.home) {
      controller.selectFirst();
      return true;
    } else if (logicalKey == LogicalKeyboardKey.end) {
      controller.selectLast();
      return true;
    } else if (logicalKey == LogicalKeyboardKey.enter) {
      final selectedId = controller.selectedNodeId;
      if (selectedId != null) {
        if (widget.logic.namingStrategy != TreeNamingStrategy.none) {
          controller.setRenamingNodeId(selectedId);
        } else {
          final node = controller.findNodeById(selectedId);
          if (node != null) {
            controller.toggleNodeExpansion(node);
          }
        }
      }
      return true;
    } else if (logicalKey == LogicalKeyboardKey.space) {
      final selectedId = controller.selectedNodeId;
      if (selectedId != null) {
        final node = controller.findNodeById(selectedId);
        if (node != null) {
          controller.toggleNodeExpansion(node);
        }
      }
      return true;
    }

    return false;
  }

  bool _shouldSuppressUnhandledPrintableKey(KeyEvent event) {
    if (defaultTargetPlatform != TargetPlatform.macOS || event is! KeyDownEvent) {
      return false;
    }

    final bool hasModifier =
        HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isAltPressed;

    if (hasModifier) {
      return false;
    }

    final String? character = event.character;
    if (character == null || character.isEmpty) {
      return false;
    }

    return true;
  }

  Widget _buildNodeItem(TreeNode<T> node) {
    return SuperTreeNodeWidget<T>(
      key: ValueKey(node.id),
      node: node,
      controller: _internalController,
      style: widget.style,
      logic: widget.logic,
      expansionBuilder: widget.expansionBuilder,
      prefixBuilder: widget.prefixBuilder,
      labelProvider: widget.labelProvider,
      contentBuilder: (context, currentNode, renameField) {
        return widget.contentBuilder(context, currentNode, renameField);
      },
      trailingBuilder: widget.trailingBuilder,
      contextMenuBuilder: widget.contextMenuBuilder,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _focusNode.requestFocus();
      },
      onTap: () {
        _internalController.deselectAll();
      },
      onSecondaryTapDown: (details) => _showRootContextMenu(details.globalPosition),
      onLongPressStart: (details) => _showRootContextMenu(details.globalPosition),
      behavior: HitTestBehavior.opaque,
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (node, event) {
          final bool handled = _handleKeyEvent(event);
          if (handled || _shouldSuppressUnhandledPrintableKey(event)) {
            return KeyEventResult.handled;
          }

          return KeyEventResult.ignored;
        },
        child: ListenableBuilder(
          listenable: _internalController,
          builder: (context, _) {
            final nodes = _internalController.flatVisibleNodes;

            if (widget._separatorBuilder != null) {
              return ListView.separated(
                controller: widget.scrollController,
                physics: widget.physics,
                itemCount: nodes.length,
                separatorBuilder: widget._separatorBuilder!,
                itemBuilder: (context, index) => _buildNodeItem(nodes[index]),
              );
            }

            return ListView.builder(
              controller: widget.scrollController,
              physics: widget.physics,
              itemCount: nodes.length,
              itemBuilder: (context, index) => _buildNodeItem(nodes[index]),
            );
          },
        ),
      ),
    );
  }

  void _showRootContextMenu(Offset position) {
    if (widget.rootContextMenuBuilder == null) return;

    final items = widget.rootContextMenuBuilder!(context);
    if (items.isEmpty) return;

    ContextMenuOverlay.show(
      context: context,
      position: position,
      items: items,
    );
  }
}
