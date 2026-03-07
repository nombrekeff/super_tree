import 'package:flutter/material.dart';
import '../../models/tree_node.dart';
import '../../models/prebuilt/file_system_item.dart';
import '../../configs/tree_view_style.dart';
import '../../configs/tree_view_logic.dart';
import '../../configs/file_system_icon_provider.dart';
import '../../controllers/tree_controller.dart';
import '../super_tree_view.dart';
import '../context_menu_overlay.dart';

/// A convenience widget that wraps [SuperTreeView] specifically configured for [FileSystemItem]s.
class FileSystemSuperTree extends StatelessWidget {
  final TreeController<FileSystemItem>? controller;
  final List<TreeNode<FileSystemItem>>? roots;
  final int Function(TreeNode<FileSystemItem> a, TreeNode<FileSystemItem> b)? sortComparator;
  
  final TreeViewStyle style;
  final TreeViewConfig<FileSystemItem> logic;
  
  final FileSystemIconProvider? iconProvider;

  /// Optional builder overrides if the default file system layout is insufficient.
  final Widget Function(BuildContext, TreeNode<FileSystemItem>)? prefixBuilder;
  final Widget Function(BuildContext context, TreeNode<FileSystemItem> node, Widget? renameField)? contentBuilder;
  final Widget Function(BuildContext, TreeNode<FileSystemItem>)? trailingBuilder;
  /// Optional function called when right-clicking (desktop) or long-pressing (mobile) a node.
  final List<ContextMenuItem> Function(BuildContext, TreeNode<FileSystemItem>)? contextMenuBuilder;
  final ScrollController? scrollController;
  final ScrollPhysics? physics;

  const FileSystemSuperTree({
    super.key,
    this.controller,
    this.roots,
    this.sortComparator,
    this.style = const TreeViewStyle(),
    this.logic = const TreeViewConfig(),
    this.iconProvider,
    this.prefixBuilder,
    this.contentBuilder,
    this.trailingBuilder,
    this.contextMenuBuilder,
    this.scrollController,
    this.physics,
  });

  Widget _defaultPrefixBuilder(BuildContext context, TreeNode<FileSystemItem> node) {
    if (node.data.isFolder) {
      return Icon(
        node.isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
        color: Colors.grey,
        size: 18,
      );
    }
    return const SizedBox(width: 18);
  }

  Widget _defaultContentBuilder(BuildContext context, TreeNode<FileSystemItem> node, Widget? renameField) {
    final provider = iconProvider ?? MaterialFileSystemIconProvider();
    return Padding(
      padding: const EdgeInsets.only(left: 6.0),
      child: Row(
        children: [
          provider.getIcon(node),
          const SizedBox(width: 8),
          Expanded(
            child: renameField ?? Text(
              node.data.name,
              maxLines: 1,
              overflow: TextOverflow.clip,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SuperTreeView<FileSystemItem>(
      controller: controller,
      roots: roots,
      sortComparator: sortComparator,
      style: style,
      logic: logic,
      prefixBuilder: prefixBuilder ?? _defaultPrefixBuilder,
      contentBuilder: contentBuilder ?? _defaultContentBuilder,
      trailingBuilder: trailingBuilder,
      contextMenuBuilder: contextMenuBuilder,
      scrollController: scrollController,
      physics: physics,
    );
  }
}
