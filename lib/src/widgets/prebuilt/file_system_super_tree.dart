import 'package:flutter/material.dart';
import 'package:super_tree/src/configs/file_system_icon_provider.dart';
import 'package:super_tree/src/configs/file_system_tree_theme.dart';
import 'package:super_tree/src/configs/icon_provider.dart';
import 'package:super_tree/src/configs/tree_rename_selection.dart';
import 'package:super_tree/src/configs/tree_view_logic.dart';
import 'package:super_tree/src/configs/tree_view_style.dart';
import 'package:super_tree/src/controllers/tree_controller.dart';
import 'package:super_tree/src/models/prebuilt/file_system_item.dart';
import 'package:super_tree/src/models/tree_node.dart';
import 'package:super_tree/src/widgets/context_menu_overlay.dart';
import 'package:super_tree/src/widgets/super_tree_view.dart';
import 'package:super_tree/src/widgets/tree_highlighted_label.dart';

/// A convenience widget that wraps [SuperTreeView] specifically configured for [FileSystemItem]s.
class FileSystemSuperTree extends StatelessWidget {
  final TreeController<FileSystemItem>? controller;
  final List<TreeNode<FileSystemItem>>? roots;
  final int Function(TreeNode<FileSystemItem> a, TreeNode<FileSystemItem> b)?
  sortComparator;

  final TreeViewStyle style;
  final TreeViewConfig<FileSystemItem> logic;

  /// Theme tokens for reusable file-system visuals.
  final FileSystemTreeTheme? fileSystemTheme;

  final FileSystemIconProvider? iconProvider;

  /// Optional builder overrides if the default file system layout is insufficient.
  final Widget Function(BuildContext, TreeNode<FileSystemItem>)? prefixBuilder;
  final Widget Function(
    BuildContext context,
    TreeNode<FileSystemItem> node,
    Widget? renameField,
  )?
  contentBuilder;
  final Widget Function(BuildContext, TreeNode<FileSystemItem>)?
  trailingBuilder;

  /// Optional function called when right-clicking (desktop) or long-pressing (mobile) a node.
  @Deprecated(
    'Use contextMenuWidgetBuilder instead. '
    'This list-based API will be removed in a future release.',
  )
  final List<ContextMenuItem> Function(BuildContext, TreeNode<FileSystemItem>)?
  contextMenuBuilder;

  /// Optional function called when right-clicking (desktop) or long-pressing (mobile) a node.
  final Widget Function(BuildContext, TreeNode<FileSystemItem>)?
  contextMenuWidgetBuilder;

  /// Optional function called when right-clicking (desktop) or long-pressing (mobile) the background.
  @Deprecated(
    'Use rootContextMenuWidgetBuilder instead. '
    'This list-based API will be removed in a future release.',
  )
  final List<ContextMenuItem> Function(BuildContext)? rootContextMenuBuilder;

  /// Optional function called when right-clicking (desktop) or long-pressing (mobile) the background.
  final Widget Function(BuildContext)? rootContextMenuWidgetBuilder;
  final ScrollController? scrollController;
  final ScrollPhysics? physics;

  const FileSystemSuperTree({
    super.key,
    this.controller,
    this.roots,
    this.sortComparator,
    this.style = const TreeViewStyle(),
    this.logic = const TreeViewConfig(),
    this.fileSystemTheme,
    this.iconProvider,
    this.prefixBuilder,
    this.contentBuilder,
    this.trailingBuilder,
    this.contextMenuBuilder,
    this.contextMenuWidgetBuilder,
    this.rootContextMenuBuilder,
    this.rootContextMenuWidgetBuilder,
    this.scrollController,
    this.physics,
  });

  FileSystemTreeTheme _resolveTheme() {
    if (fileSystemTheme != null) {
      return fileSystemTheme!;
    }

    return FileSystemTreeTheme.material(iconProvider: iconProvider);
  }

  TreeViewConfig<FileSystemItem> _resolveLogic() {
    if (logic.renameSelectionStrategy != null) {
      return logic;
    }

    return logic.copyWith(
      renameSelectionStrategy:
          TreeRenameSelectionStrategies.selectFileName<FileSystemItem>(),
    );
  }

  Widget _defaultPrefixBuilder(
    BuildContext context,
    TreeNode<FileSystemItem> node,
  ) {
    final FileSystemTreeTheme resolvedTheme = _resolveTheme();
    final FileSystemIconProvider provider = resolvedTheme.iconProvider;
    final Widget Function(BuildContext, TreeNode<FileSystemItem>) builder =
        prefixBuilderFromIconProvider<FileSystemItem>(iconProvider: provider);
    return builder(context, node);
  }

  Widget _defaultContentBuilder(
    BuildContext context,
    TreeNode<FileSystemItem> node,
    Widget? renameField,
  ) {
    final FileSystemTreeTheme resolvedTheme = _resolveTheme();
    if (renameField != null) {
      return Padding(padding: resolvedTheme.labelPadding, child: renameField);
    }

    final List<int> matchedIndices =
        controller?.getMatchedIndices(node.id) ?? const <int>[];

    return Padding(
      padding: resolvedTheme.labelPadding,
      child: TreeHighlightedLabel(
        text: node.data.name,
        matchedIndices: matchedIndices,
        style: style.labelStyle ?? style.textStyle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TreeViewConfig<FileSystemItem> resolvedLogic = _resolveLogic();

    return SuperTreeView<FileSystemItem>(
      controller: controller,
      roots: roots,
      sortComparator: sortComparator,
      style: style,
      logic: resolvedLogic,
      prefixBuilder: prefixBuilder ?? _defaultPrefixBuilder,
      contentBuilder: contentBuilder ?? _defaultContentBuilder,
      trailingBuilder: trailingBuilder,
      // ignore: deprecated_member_use_from_same_package
      contextMenuBuilder: contextMenuBuilder,
      contextMenuWidgetBuilder: contextMenuWidgetBuilder,
      // ignore: deprecated_member_use_from_same_package
      rootContextMenuBuilder: rootContextMenuBuilder,
      rootContextMenuWidgetBuilder: rootContextMenuWidgetBuilder,
      scrollController: scrollController,
      physics: physics,
    );
  }
}
