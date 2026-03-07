import 'package:flutter/material.dart';
import 'package:super_tree/src/configs/file_system_icon_provider.dart';
import 'package:super_tree/src/configs/icon_provider.dart';
import 'package:super_tree/src/configs/tree_view_logic.dart';
import 'package:super_tree/src/configs/tree_view_style.dart';
import 'package:super_tree/src/controllers/tree_controller.dart';
import 'package:super_tree/src/models/prebuilt/file_system_item.dart';
import 'package:super_tree/src/models/tree_node.dart';
import 'package:super_tree/src/widgets/context_menu_overlay.dart';
import 'package:super_tree/src/widgets/super_tree_view.dart';

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
  /// Optional function called when right-clicking (desktop) or long-pressing (mobile) the background.
  final List<ContextMenuItem> Function(BuildContext)? rootContextMenuBuilder;
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
    this.rootContextMenuBuilder,
    this.scrollController,
    this.physics,
  });

  Widget _defaultPrefixBuilder(BuildContext context, TreeNode<FileSystemItem> node) {
    final FileSystemIconProvider provider = iconProvider ?? MaterialFileSystemIconProvider();
    final Widget Function(BuildContext, TreeNode<FileSystemItem>) builder =
        prefixBuilderFromIconProvider<FileSystemItem>(iconProvider: provider);
    return builder(context, node);
  }

  Widget _defaultContentBuilder(BuildContext context, TreeNode<FileSystemItem> node, Widget? renameField) {
    return Padding(
      padding: const EdgeInsets.only(left: 6.0),
      child: renameField ?? Text(
        node.data.name,
        maxLines: 1,
        overflow: TextOverflow.clip,
        style: style.labelStyle ?? style.textStyle,
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
      rootContextMenuBuilder: rootContextMenuBuilder,
      scrollController: scrollController,
      physics: physics,
    );
  }
}
