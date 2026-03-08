import 'package:flutter/material.dart';
import 'package:example/examples/shared/example_tree_search_bar.dart';
import 'package:example/examples/shared/example_tree_search_logic.dart';
import 'package:example/examples/shared/example_tree_search_shortcuts.dart';
import 'package:example/l10n/app_localizations.dart';
import 'package:super_tree/super_tree.dart';

enum ThemeOption { vscode, material, compact }

enum SortOption { none, alphabetical, foldersFirst }

enum _FileHeaderAction { createRootFolder, createRootFile, expandAll, collapseAll }

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
  late FuzzyTreeFilter<FileSystemItem> _fileSearchFilter;
  SortOption _currentSort = SortOption.none;

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _controller = TreeController<FileSystemItem>(
      onNodeRenamed: (node, newName) {
        setState(() {
          node.data.name = newName;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_l10n.fileRenamedTo(newName))));
      },
      onNodeDeleted: (node) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_l10n.fileItemDeleted)));
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
                      children: [TreeNode(data: FileItem('tree_node.dart'))],
                    ),
                    TreeNode(
                      data: FolderItem('configs'),
                      children: [TreeNode(data: FileItem('tree_view_style.dart'))],
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
                  children: [TreeNode(data: FileItem('main.dart'))],
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
    _fileSearchFilter = FuzzyTreeFilter<FileSystemItem>(
      customMatchers: <TreeFilterCustomMatcher<FileSystemItem>>[
        FuzzyTreeFilter.extensionSuffixMatcher<FileSystemItem>(
          nodePredicate: (TreeNode<FileSystemItem> node) => !node.data.isFolder,
        ),
      ],
    );

    _searchController = TreeSearchController<FileSystemItem>(
      treeController: _controller,
      labelProvider: (FileSystemItem item) => item.name,
      expansionBehavior: TreeSearchExpansionBehavior.expandMatchesAndAncestors,
      searchMatcher: _fileSearchFilter.asSearchMatcher(),
    );
    _searchUi = ExampleTreeSearchLogic<FileSystemItem>(searchController: _searchController);
  }

  @override
  void dispose() {
    _searchUi.dispose();
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
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
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return [
      ContextMenuItem(
        child: Text(l10n.fileRootMenuNewFile),
        onTap: () {
          _controller.createNewRoot(FileItem(''));
        },
      ),
      ContextMenuItem(
        child: Text(l10n.fileRootMenuNewFolder),
        onTap: () {
          _controller.createNewRoot(FolderItem(''));
        },
      ),
      const ContextMenuItem(child: Divider(), onTap: _noOp),
      ContextMenuItem(
        child: Text(l10n.fileRootMenuExpandAll),
        onTap: () => _controller.expandAll(),
      ),
      ContextMenuItem(
        child: Text(l10n.fileRootMenuCollapseAll),
        onTap: () => _controller.collapseAll(),
      ),
    ];
  }

  static void _noOp() {}

  List<ContextMenuItem> _buildContextMenu(BuildContext context, TreeNode<FileSystemItem> node) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return [
      if (node.data.isFolder) ...[
        ContextMenuItem(
          child: Text(l10n.fileRootMenuNewFile),
          onTap: () {
            _controller.createNewChild(node, FileItem(''));
          },
        ),
        ContextMenuItem(
          child: Text(l10n.fileRootMenuNewFolder),
          onTap: () {
            _controller.createNewChild(node, FolderItem(''));
          },
        ),
        const ContextMenuItem(child: Divider(), onTap: _noOp),
      ],
      ContextMenuItem(
        child: Text(l10n.fileNodeMenuRename),
        onTap: () {
          _controller.setRenamingNodeId(node.id);
        },
      ),
      ContextMenuItem(
        child: Text(l10n.fileNodeMenuDelete, style: const TextStyle(color: Colors.red)),
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
          _controller.sortComparator = (a, b) =>
              a.data.name.toLowerCase().compareTo(b.data.name.toLowerCase());
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

  Widget _buildCompactHeaderTitle(AppLocalizations l10n) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Icon(Icons.folder_open, size: 18),
        const SizedBox(width: 8),
        Text(l10n.fileScreenTitle),
      ],
    );
  }

  Widget _buildSortMenu(AppLocalizations l10n) {
    final List<PopupMenuEntry<SortOption>> sortItems = <PopupMenuEntry<SortOption>>[
      PopupMenuItem<SortOption>(value: SortOption.none, child: Text(l10n.fileSortNone)),
      PopupMenuItem<SortOption>(
        value: SortOption.alphabetical,
        child: Text(l10n.fileSortAlphabetical),
      ),
      PopupMenuItem<SortOption>(
        value: SortOption.foldersFirst,
        child: Text(l10n.fileSortFoldersFirst),
      ),
    ];

    return PopupMenuButton<SortOption>(
      tooltip: l10n.fileSortAlphabetical,
      icon: const Icon(Icons.sort),
      initialValue: _currentSort,
      onSelected: _updateSorting,
      itemBuilder: (BuildContext context) => sortItems,
    );
  }

  Widget _buildThemeMenu(AppLocalizations l10n) {
    final List<PopupMenuEntry<ThemeOption>> themeItems = <PopupMenuEntry<ThemeOption>>[
      PopupMenuItem<ThemeOption>(value: ThemeOption.vscode, child: Text(l10n.fileThemeVsCode)),
      PopupMenuItem<ThemeOption>(
        value: ThemeOption.material,
        child: Text(l10n.fileThemeMaterial),
      ),
      PopupMenuItem<ThemeOption>(
        value: ThemeOption.compact,
        child: Text(l10n.fileThemeCompact),
      ),
    ];

    return PopupMenuButton<ThemeOption>(
      tooltip: l10n.fileThemeMaterial,
      icon: const Icon(Icons.palette),
      initialValue: widget.currentTheme,
      onSelected: widget.onThemeChanged,
      itemBuilder: (BuildContext context) => themeItems,
    );
  }

  Widget _buildTreeActionsMenu(AppLocalizations l10n) {
    final List<PopupMenuEntry<_FileHeaderAction>> actionItems =
        <PopupMenuEntry<_FileHeaderAction>>[
          PopupMenuItem<_FileHeaderAction>(
            value: _FileHeaderAction.createRootFolder,
            child: Text(l10n.fileActionNewRootFolder),
          ),
          PopupMenuItem<_FileHeaderAction>(
            value: _FileHeaderAction.createRootFile,
            child: Text(l10n.fileActionNewRootFile),
          ),
          const PopupMenuDivider(),
          PopupMenuItem<_FileHeaderAction>(
            value: _FileHeaderAction.expandAll,
            child: Text(l10n.fileActionExpandAll),
          ),
          PopupMenuItem<_FileHeaderAction>(
            value: _FileHeaderAction.collapseAll,
            child: Text(l10n.fileActionCollapseAll),
          ),
        ];

    return PopupMenuButton<_FileHeaderAction>(
      tooltip: l10n.fileActionExpandAll,
      icon: const Icon(Icons.more_horiz),
      onSelected: (_FileHeaderAction action) {
        switch (action) {
          case _FileHeaderAction.createRootFolder:
            _controller.createNewRoot(FolderItem(''));
            break;
          case _FileHeaderAction.createRootFile:
            _controller.createNewRoot(FileItem(''));
            break;
          case _FileHeaderAction.expandAll:
            _controller.expandAll();
            break;
          case _FileHeaderAction.collapseAll:
            _controller.collapseAll();
            break;
        }
      },
      itemBuilder: (BuildContext context) => actionItems,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Widget searchField = _buildSearchField();
    final Widget title = _buildCompactHeaderTitle(l10n);
    final Widget sortMenu = _buildSortMenu(l10n);
    final Widget themeMenu = _buildThemeMenu(l10n);
    final Widget treeActionsMenu = _buildTreeActionsMenu(l10n);

    return ExampleTreeSearchShortcuts(
      onOpenSearch: _openSearch,
      onCloseSearch: _closeSearch,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 48,
          titleSpacing: 12,
          centerTitle: false,
          title: title,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          foregroundColor: isDark ? Colors.white : Colors.black87,
          scrolledUnderElevation: 0,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _openSearch,
              tooltip: l10n.fileSearchTooltip,
            ),
            sortMenu,
            themeMenu,
            treeActionsMenu,
            const SizedBox(width: 4),
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
                      border: Border(
                        right: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
                      ),
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
                      fileSystemTheme: _getFileSystemTheme(),
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
                            final bool noSearchResults =
                                hasSearch && _controller.flatVisibleNodes.isEmpty;

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
                                    l10n.fileNoResults(_searchController.query),
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 12),
                                  TextButton(
                                    onPressed: _closeSearch,
                                    child: Text(l10n.searchClearSearch),
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
                                    l10n.fileSelectHint,
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
                                    l10n.fileItemsSelected(selectedIds.length),
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
                                    label: Text(l10n.fileDeleteSelected),
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
                                  selectedNode.data.isFolder
                                      ? Icons.folder
                                      : Icons.insert_drive_file,
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
                                  selectedNode.data.isFolder
                                      ? l10n.fileTypeFolder
                                      : l10n.fileTypeFile,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: isDark ? Colors.white54 : Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 40),
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      _controller.setRenamingNodeId(selectedNode.id),
                                  icon: const Icon(Icons.edit),
                                  label: Text(l10n.fileRenameItem),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return ExampleTreeSearchBar(
      controller: _searchUi.textController,
      focusNode: _searchUi.focusNode,
      onChanged: _onSearchChanged,
      onClose: _closeSearch,
      hasQuery: _searchController.hasQuery,
      hintText: l10n.fileSearchHint,
      clearLabel: l10n.searchClear,
      closeTooltip: l10n.searchCloseTooltip,
    );
  }

  Color _getSidebarColor() {
    return _getPreset().sidebarColor ?? Theme.of(context).colorScheme.surface;
  }

  TreeViewStyle _getTreeStyle() {
    return _getPreset().treeStyle;
  }

  FileSystemTreeTheme _getFileSystemTheme() {
    return _getPreset().fileSystemTheme ?? FileSystemTreeTheme.material();
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
