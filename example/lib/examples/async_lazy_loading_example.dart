import 'package:flutter/material.dart';
import 'package:super_tree/super_tree.dart';

class AsyncLazyLoadingExample extends StatefulWidget {
  const AsyncLazyLoadingExample({super.key});

  @override
  State<AsyncLazyLoadingExample> createState() => _AsyncLazyLoadingExampleState();
}

class _AsyncLazyLoadingExampleState extends State<AsyncLazyLoadingExample> {
  late final TreeController<FileSystemItem> _controller;
  late final Widget Function(BuildContext, TreeNode<FileSystemItem>) _iconPrefixBuilder;
  final Set<String> _failedOnceNodeIds = <String>{};

  @override
  void initState() {
    super.initState();
    _controller = TreeController<FileSystemItem>(
      roots: <TreeNode<FileSystemItem>>[
        TreeNode<FileSystemItem>(
          id: 'workspace',
          data: FolderItem('workspace'),
          isExpanded: true,
          canLoadChildren: true,
        ),
      ],
      loadChildren: _loadChildren,
    );
    _iconPrefixBuilder = prefixBuilderFromIconProvider<FileSystemItem>(
      iconProvider: MaterialFileSystemIconProvider(),
      leadingSpacing: 0,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<List<TreeNode<FileSystemItem>>> _loadChildren(
    TreeNode<FileSystemItem> node,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));

    if (node.id == 'packages' && !_failedOnceNodeIds.contains(node.id)) {
      _failedOnceNodeIds.add(node.id);
      throw StateError('Network timeout while loading packages');
    }

    switch (node.id) {
      case 'workspace':
        return <TreeNode<FileSystemItem>>[
          TreeNode<FileSystemItem>(
            id: 'lib',
            data: FolderItem('lib'),
            canLoadChildren: true,
          ),
          TreeNode<FileSystemItem>(
            id: 'packages',
            data: FolderItem('packages'),
            canLoadChildren: true,
          ),
          TreeNode<FileSystemItem>(
            id: 'readme',
            data: FileItem('README.md'),
          ),
        ];
      case 'lib':
        return <TreeNode<FileSystemItem>>[
          TreeNode<FileSystemItem>(
            id: 'src',
            data: FolderItem('src'),
            canLoadChildren: true,
          ),
          TreeNode<FileSystemItem>(
            id: 'main',
            data: FileItem('main.dart'),
          ),
        ];
      case 'src':
        return <TreeNode<FileSystemItem>>[
          TreeNode<FileSystemItem>(
            id: 'widgets',
            data: FolderItem('widgets'),
            canLoadChildren: true,
          ),
          TreeNode<FileSystemItem>(
            id: 'controllers',
            data: FolderItem('controllers'),
            canLoadChildren: true,
          ),
        ];
      case 'widgets':
        return <TreeNode<FileSystemItem>>[
          TreeNode<FileSystemItem>(
            id: 'tree_view',
            data: FileItem('super_tree_view.dart'),
          ),
          TreeNode<FileSystemItem>(
            id: 'node_widget',
            data: FileItem('super_tree_node_widget.dart'),
          ),
        ];
      case 'controllers':
        return <TreeNode<FileSystemItem>>[
          TreeNode<FileSystemItem>(
            id: 'tree_controller',
            data: FileItem('tree_controller.dart'),
          ),
        ];
      case 'packages':
        return <TreeNode<FileSystemItem>>[
          TreeNode<FileSystemItem>(
            id: 'flutter',
            data: FolderItem('flutter'),
            canLoadChildren: true,
          ),
          TreeNode<FileSystemItem>(
            id: 'super_tree_pkg',
            data: FolderItem('super_tree'),
            canLoadChildren: true,
          ),
        ];
      case 'flutter':
        return <TreeNode<FileSystemItem>>[
          TreeNode<FileSystemItem>(
            id: 'material',
            data: FileItem('material.dart'),
          ),
          TreeNode<FileSystemItem>(
            id: 'widgets_file',
            data: FileItem('widgets.dart'),
          ),
        ];
      case 'super_tree_pkg':
        return <TreeNode<FileSystemItem>>[
          TreeNode<FileSystemItem>(
            id: 'pubspec_lock',
            data: FileItem('pubspec.lock'),
          ),
        ];
      default:
        return <TreeNode<FileSystemItem>>[];
    }
  }

  Future<void> _retryLoad(TreeNode<FileSystemItem> node) async {
    _controller.clearNodeLoadError(node.id);
    await _controller.ensureNodeChildrenLoaded(node);
    if (node.hasChildren && !node.isExpanded) {
      _controller.expandNode(node);
    }
  }

  Widget _buildPrefix(BuildContext context, TreeNode<FileSystemItem> node) {
    return _iconPrefixBuilder(context, node);
  }

  Widget _buildExpansion(BuildContext context, TreeNode<FileSystemItem> node) {
    final TreeNodeAsyncState asyncState = _controller.getNodeAsyncState(node.id);
    if (asyncState.isLoading) {
      return const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return const Icon(
      Icons.keyboard_arrow_right,
      color: Colors.grey,
      size: 20,
    );
  }

  Widget _buildContent(
    BuildContext context,
    TreeNode<FileSystemItem> node,
    Widget? renameField,
  ) {
    if (renameField != null) {
      return renameField;
    }

    return Text(node.data.name);
  }

  Widget _buildTrailing(BuildContext context, TreeNode<FileSystemItem> node) {
    final TreeNodeAsyncState asyncState = _controller.getNodeAsyncState(node.id);
    if (!asyncState.hasError) {
      return const SizedBox.shrink();
    }

    return TextButton.icon(
      onPressed: () {
        _retryLoad(node);
      },
      icon: const Icon(Icons.refresh, size: 14),
      label: const Text('Retry'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Async Lazy Loading'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Text(
              'Expand folders to fetch children asynchronously. "packages" fails once to demonstrate retry handling.',
            ),
          ),
          Expanded(
            child: SuperTreeView<FileSystemItem>(
              controller: _controller,
              style: const TreeViewStyle(
                indentAmount: 22,
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              logic: const TreeViewConfig<FileSystemItem>(
                expansionTrigger: ExpansionTrigger.tap,
                namingStrategy: TreeNamingStrategy.none,
              ),
              expansionBuilder: _buildExpansion,
              prefixBuilder: _buildPrefix,
              contentBuilder: _buildContent,
              trailingBuilder: _buildTrailing,
            ),
          ),
        ],
      ),
    );
  }
}
