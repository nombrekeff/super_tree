import 'package:flutter/material.dart';
import 'package:example/examples/shared/example_tree_search_bar.dart';
import 'package:example/examples/shared/example_tree_search_logic.dart';
import 'package:example/examples/shared/example_tree_search_shortcuts.dart';
import 'package:super_tree/super_tree.dart';

enum ThemeOption {
  vscode,
  material,
  compact,
}

enum SortOption {
  none,
  alphabetical,
  foldersFirst,
}

class FileSystemExample extends StatefulWidget {
  const FileSystemExample({super.key});

  @override
  State<FileSystemExample> createState() => _FileSystemExampleState();
}

class _FileSystemExampleState extends State<FileSystemExample> {
  ThemeOption _currentTheme = ThemeOption.vscode;

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = _getPreset().toThemeData();

    return Theme(
      data: themeData,
      child: FileSystemTreeScreen(
        currentTheme: _currentTheme,
        onThemeChanged: (theme) {
          setState(() {
            _currentTheme = theme;
          });
        },
      ),
    );
  }

  SuperTreeThemePreset _getPreset() {
    switch (_currentTheme) {
      case ThemeOption.vscode:
        return SuperTreeThemes.vscode();
      case ThemeOption.material:
        return SuperTreeThemes.material();
      case ThemeOption.compact:
        return SuperTreeThemes.compact();
    }
  }
}

class FileSystemTreeScreen extends StatefulWidget {
  final ThemeOption currentTheme;
  final ValueChanged<ThemeOption> onThemeChanged;

  const FileSystemTreeScreen({
    super.key,
    required this.currentTheme,
    required this.onThemeChanged,
  });

  @override
  State<FileSystemTreeScreen> createState() => _FileSystemTreeScreenState();
}

class _FileSystemTreeScreenState extends State<FileSystemTreeScreen> {
  late TreeController<FileSystemItem> _controller;
  late TreeSearchController<FileSystemItem> _searchController;
  late ExampleTreeSearchLogic<FileSystemItem> _searchUi;
  SortOption _currentSort = SortOption.none;

  @override
  void initState() {
    super.initState();
    _controller = TreeController<FileSystemItem>(
      onNodeRenamed: (node, newName) {
        setState(() {
          node.data.name = newName;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Renamed to $newName')),
        );
      },
      onNodeDeleted: (node) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item deleted')),
        );
      },
      roots: [
        TreeNode(
          data: FolderItem('super_tree'),
          isExpanded: true,
          children: [
            TreeNode(
              data: FolderItem('assets'),
              children: [
                TreeNode(data: FileItem('logo.png')),
                TreeNode(data: FileItem('intro.mp4')),
                TreeNode(data: FileItem('theme.mp3')),
                TreeNode(data: FileItem('archive.zip')),
                TreeNode(data: FileItem('data.csv')),
                TreeNode(data: FileItem('presentation.pptx')),
              ],
            ),
            TreeNode(
              data: FolderItem('lib'),
              isExpanded: true,
              children: [
                TreeNode(
                  data: FolderItem('src'),
                  isExpanded: true,
                  children: [
                    TreeNode(
                      data: FolderItem('models'),
                      children: [
                        TreeNode(data: FileItem('tree_node.dart')),
                      ],
                    ),
                    TreeNode(
                      data: FolderItem('configs'),
                      children: [
                        TreeNode(data: FileItem('tree_view_style.dart')),
                      ],
                    ),
                  ],
                ),
                TreeNode(data: FileItem('super_tree.dart')),
              ],
            ),
            TreeNode(
              data: FolderItem('example'),
              children: [
                TreeNode(
                  data: FolderItem('lib'),
                  children: [
                    TreeNode(data: FileItem('main.dart')),
                  ],
                ),
              ],
            ),
            TreeNode(data: FileItem('pubspec.yaml')),
            TreeNode(data: FileItem('README.md')),
            TreeNode(data: FileItem('CHANGELOG.md')),
          ],
        ),
      ],
    );
    _searchController = TreeSearchController<FileSystemItem>(
      treeController: _controller,
      labelProvider: (FileSystemItem item) => item.name,
      expansionBehavior: TreeSearchExpansionBehavior.expandMatchesAndAncestors,
      searchMatcher: _fileSearchMatcher,
    );
    _searchUi = ExampleTreeSearchLogic<FileSystemItem>(
      searchController: _searchController,
    );
  }

  @override
  void dispose() {
    _searchUi.dispose();
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  TreeFuzzyMatchResult? _fileSearchMatcher(
    String query,
    TreeNode<FileSystemItem> node,
    String candidate,
  ) {
    final String normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return const TreeFuzzyMatchResult(score: 0, matchedIndices: <int>[]);
    }

    // If user types an extension query (e.g. ".dart"), prefer suffix matches.
    if (normalized.startsWith('.') && !node.data.isFolder) {
      final String lowerCandidate = candidate.toLowerCase();
      if (lowerCandidate.endsWith(normalized)) {
        final int start = lowerCandidate.length - normalized.length;
        return TreeFuzzyMatchResult(
          score: 0,
          matchedIndices: List<int>.generate(normalized.length, (int i) => start + i),
        );
      }
    }

    return defaultTreeFuzzyMatcher(normalized, candidate);
  }

  void _openSearch() {
    _searchUi.open(refresh: _refreshSearchUi);
  }

  void _closeSearch() {
    _searchUi.close(refresh: _refreshSearchUi);
  }

  void _onSearchChanged(String value) {
    _searchUi.handleChanged(value);
  }

  void _refreshSearchUi() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  List<ContextMenuItem> _buildRootContextMenu(BuildContext context) {
    return [
      ContextMenuItem(
        child: const Text('New File'),
        onTap: () {
          _controller.createNewRoot(FileItem(''));
        },
      ),
      ContextMenuItem(
        child: const Text('New Folder'),
        onTap: () {
          _controller.createNewRoot(FolderItem(''));
        },
      ),
      const ContextMenuItem(
        child: Divider(),
        onTap: _noOp,
      ),
      ContextMenuItem(
        child: const Text('Expand All'),
        onTap: () => _controller.expandAll(),
      ),
      ContextMenuItem(
        child: const Text('Collapse All'),
        onTap: () => _controller.collapseAll(),
      ),
    ];
  }

  static void _noOp() {}

  List<ContextMenuItem> _buildContextMenu(BuildContext context, TreeNode<FileSystemItem> node) {
    return [
      if (node.data.isFolder) ...[
        ContextMenuItem(
          child: const Text('New File'),
          onTap: () {
            _controller.createNewChild(node, FileItem(''));
          },
        ),
        ContextMenuItem(
          child: const Text('New Folder'),
          onTap: () {
            _controller.createNewChild(node, FolderItem(''));
          },
        ),
        const ContextMenuItem(
          child: Divider(),
          onTap: _noOp,
        ),
      ],
      ContextMenuItem(
        child: const Text('Rename'),
        onTap: () {
          _controller.setRenamingNodeId(node.id);
        },
      ),
      ContextMenuItem(
        child: const Text('Delete', style: TextStyle(color: Colors.red)),
        onTap: () {
          _controller.removeNode(node);
        },
      ),
    ];
  }

  void _updateSorting(SortOption option) {
    setState(() {
      _currentSort = option;
      switch (option) {
        case SortOption.none:
          _controller.sortComparator = null;
          break;
        case SortOption.alphabetical:
          _controller.sortComparator = (a, b) => a.data.name.toLowerCase().compareTo(b.data.name.toLowerCase());
          break;
        case SortOption.foldersFirst:
          _controller.sortComparator = (a, b) {
            if (a.data.isFolder && !b.data.isFolder) return -1;
            if (!a.data.isFolder && b.data.isFolder) return 1;
            return a.data.name.toLowerCase().compareTo(b.data.name.toLowerCase());
          };
          break;
      }
    });
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return IconButton(
      icon: Icon(icon),
      onPressed: onPressed,
      tooltip: tooltip,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Widget searchField = _buildSearchField();

    return ExampleTreeSearchShortcuts(
      onOpenSearch: _openSearch,
      onCloseSearch: _closeSearch,
      child: Scaffold(
      appBar: AppBar(
        title: const Text('File System Tree'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _openSearch,
            tooltip: 'Search (Cmd/Ctrl+F)',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DropdownButton<SortOption>(
              value: _currentSort,
              dropdownColor: theme.colorScheme.surface,
              underline: const SizedBox(),
              icon: Icon(Icons.sort, color: isDark ? Colors.white70 : Colors.black54),
              items: const [
                DropdownMenuItem(value: SortOption.none, child: Text('No Sort')),
                DropdownMenuItem(value: SortOption.alphabetical, child: Text('Alphabetical')),
                DropdownMenuItem(value: SortOption.foldersFirst, child: Text('Folders First')),
              ],
              onChanged: (val) {
                if (val != null) _updateSorting(val);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DropdownButton<ThemeOption>(
              value: widget.currentTheme,
              dropdownColor: theme.colorScheme.surface,
              underline: const SizedBox(),
              icon: Icon(Icons.palette, color: isDark ? Colors.white70 : Colors.black54),
              items: const [
                DropdownMenuItem(value: ThemeOption.vscode, child: Text('VS Code Dark')),
                DropdownMenuItem(value: ThemeOption.material, child: Text('Material')),
                DropdownMenuItem(value: ThemeOption.compact, child: Text('Compact')),
              ],
              onChanged: (val) {
                if (val != null) {
                  widget.onThemeChanged(val);
                }
              },
            ),
          ),
          _buildActionButton(
            icon: Icons.create_new_folder,
            onPressed: () => _controller.createNewRoot(FolderItem('')),
            tooltip: 'New Root Folder',
          ),
          _buildActionButton(
            icon: Icons.note_add,
            onPressed: () => _controller.createNewRoot(FileItem('')),
            tooltip: 'New Root File',
          ),
          _buildActionButton(
            icon: Icons.unfold_more,
            onPressed: () => _controller.expandAll(),
            tooltip: 'Expand All',
          ),
          IconButton(
            icon: const Icon(Icons.unfold_less),
            onPressed: _controller.collapseAll,
            tooltip: 'Collapse All',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_searchUi.isSearchVisible) searchField,
          Expanded(
            child: Row(
        children: [
          Container(
            width: 320,
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: isDark ? Colors.white12 : Colors.black12)),
              color: _getSidebarColor(),
            ),
              child: FileSystemSuperTree(
                controller: _controller,
                style: _getTreeStyle(),
                logic: TreeViewConfig(
                  enableDragAndDrop: true,
                  expansionTrigger: ExpansionTrigger.tap,
                  selectionMode: SelectionMode.multiple,
                  namingStrategy: TreeNamingStrategy.contextMenu,
                  onNodeTap: (id) {
                    setState(() {
                      // We keep track of the last selected node for the detail view if only one is selected
                      // or just to show the "focused" one.
                    });
                  },
                ),
                iconProvider: _getIconProvider(),
                contextMenuBuilder: _buildContextMenu,
                rootContextMenuBuilder: _buildRootContextMenu,
              ),
            ),
          
          Expanded(
            child: Container(
              color: theme.scaffoldBackgroundColor,
              child: Center(
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, _) {
                  final selectedIds = _controller.selectedNodeIds;
                  final bool hasSearch = _searchController.hasQuery;
                  final bool noSearchResults = hasSearch && _controller.flatVisibleNodes.isEmpty;

                  if (noSearchResults) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 72,
                          color: isDark ? Colors.white24 : Colors.black26,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No results for "${_searchController.query}"',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _closeSearch,
                          child: const Text('Clear search'),
                        ),
                      ],
                    );
                  }
                  
                  if (selectedIds.isEmpty) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.account_tree,
                          size: 64,
                          color: isDark ? Colors.white24 : Colors.black26,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Select a file to view\nDrag and Drop nodes to move them',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.black54,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    );
                  }

                  if (selectedIds.length > 1) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.copy_all,
                          size: 80,
                          color: theme.colorScheme.primary.withAlpha(128),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          '${selectedIds.length} items selected',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: isDark ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 40),
                        ElevatedButton.icon(
                          onPressed: () {
                            for (var id in selectedIds) {
                              _controller.removeNode(_controller.findNodeById(id)!);
                            }
                          },
                          icon: const Icon(Icons.delete_sweep),
                          label: const Text('Delete Selected Items'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.withAlpha(204),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    );
                  }

                  final selectedNode = _controller.findNodeById(selectedIds.first)!;
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        selectedNode.data.isFolder ? Icons.folder : Icons.insert_drive_file,
                        size: 80,
                        color: theme.colorScheme.primary.withAlpha(128),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        selectedNode.data.name,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        selectedNode.data.isFolder ? 'Folder' : 'File',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 40),
                      ElevatedButton.icon(
                        onPressed: () => _controller.setRenamingNodeId(selectedNode.id),
                        icon: const Icon(Icons.edit),
                        label: const Text('Rename Item'),
                      ),
                    ],
                  );
                },
              ),
              ),
            ),
          )
        ],
      ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildSearchField() {
    return ExampleTreeSearchBar(
      controller: _searchUi.textController,
      focusNode: _searchUi.focusNode,
      onChanged: _onSearchChanged,
      onClose: _closeSearch,
      hasQuery: _searchController.hasQuery,
      hintText: 'Search files and folders',
    );
  }

  Color _getSidebarColor() {
    return _getPreset().sidebarColor ?? Theme.of(context).colorScheme.surface;
  }

  TreeViewStyle _getTreeStyle() {
    return _getPreset().treeStyle;
  }

  FileSystemIconProvider _getIconProvider() {
    final FileSystemIconProvider? provider = _getPreset().fileSystemIconProvider;
    if (provider != null) {
      return provider;
    }

    return MaterialFileSystemIconProvider();
  }

  SuperTreeThemePreset _getPreset() {
    switch (widget.currentTheme) {
      case ThemeOption.vscode:
        return SuperTreeThemes.vscode();
      case ThemeOption.material:
        return SuperTreeThemes.material();
      case ThemeOption.compact:
        return SuperTreeThemes.compact();
    }
  }
}

