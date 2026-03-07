import 'package:flutter/material.dart';
import 'package:super_tree/super_tree.dart';

enum ThemeOption {
  vscode,
  finder,
  colorful,
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
    ThemeData themeData;
    switch (_currentTheme) {
      case ThemeOption.vscode:
        themeData = ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF181818),
          colorScheme: const ColorScheme.dark(
            surface: Color(0xFF252526),
          ),
          cardColor: const Color(0xFF252526),
        );
        break;
      case ThemeOption.finder:
        themeData = ThemeData.light().copyWith(
          scaffoldBackgroundColor: Colors.white,
          colorScheme: const ColorScheme.light(
            surface: Color(0xFFFFFFFF),
          ),
          cardColor: Colors.white,
        );
        break;
      case ThemeOption.colorful:
        themeData = ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF0F172A),
          colorScheme: const ColorScheme.dark(
            surface: Color(0xFF1E293B),
            primary: Color(0xFF3B82F6),
          ),
          cardColor: const Color(0xFF1E293B),
        );
        break;
    }

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
  SortOption _currentSort = SortOption.none;
  TreeNode<FileSystemItem>? _selectedNode;

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
        if (_selectedNode == node) {
          setState(() {
            _selectedNode = null;
          });
        }
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
  }

  List<ContextMenuItem> _buildContextMenu(BuildContext context, TreeNode<FileSystemItem> node) {
    return [
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('File System Tree'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 1,
        actions: [
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
                DropdownMenuItem(value: ThemeOption.finder, child: Text('Mac Finder')),
                DropdownMenuItem(value: ThemeOption.colorful, child: Text('Colorful Custom')),
              ],
              onChanged: (val) {
                if (val != null) {
                  widget.onThemeChanged(val);
                }
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.unfold_more),
            onPressed: _controller.expandAll,
            tooltip: 'Expand All',
          ),
          IconButton(
            icon: const Icon(Icons.unfold_less),
            onPressed: _controller.collapseAll,
            tooltip: 'Collapse All',
          ),
        ],
      ),
      body: Row(
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
                  namingStrategy: TreeNamingStrategy.contextMenu,
                  onNodeTap: (id) {
                    setState(() {
                      _selectedNode = _controller.findNodeById(id);
                      // Update selection state in the tree nodes too
                      for (var node in _controller.flatVisibleNodes) {
                        node.isSelected = node.id == id;
                      }
                    });
                  },
                ),
                iconProvider: _getIconProvider(),
                contextMenuBuilder: _buildContextMenu,
              ),
            ),
          
          Expanded(
            child: Container(
              color: theme.scaffoldBackgroundColor,
              child: Center(
                child: _selectedNode == null
                    ? Column(
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
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _selectedNode!.data.isFolder ? Icons.folder : Icons.insert_drive_file,
                            size: 80,
                            color: theme.colorScheme.primary.withOpacity(0.5),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            _selectedNode!.data.name,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: isDark ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedNode!.data.isFolder ? 'Folder' : 'File',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 40),
                          ElevatedButton.icon(
                            onPressed: () => _controller.setRenamingNodeId(_selectedNode!.id),
                            icon: const Icon(Icons.edit),
                            label: const Text('Rename Item'),
                          ),
                        ],
                      ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Color _getSidebarColor() {
    switch (widget.currentTheme) {
      case ThemeOption.vscode:
        return const Color(0xFF1E1E1E);
      case ThemeOption.finder:
        return const Color(0xFFF3F4F6); // subtle gray
      case ThemeOption.colorful:
        return const Color(0xFF1E293B); // dark slate
    }
  }

  TreeViewStyle _getTreeStyle() {
    switch (widget.currentTheme) {
      case ThemeOption.vscode:
        return const TreeViewStyle(
          indentAmount: 16.0,
          idleColor: Colors.transparent,
          hoverColor: Color(0x1AFFFFFF),
          selectedColor: Color(0x33FFFFFF),
          dropIndicatorColor: Colors.blue,
          padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        );
      case ThemeOption.finder:
        return const TreeViewStyle(
          indentAmount: 20.0,
          idleColor: Colors.transparent,
          hoverColor: Color(0x1A000000),
          selectedColor: Color(0xFF0066CC),
          dropIndicatorColor: Color(0xFF0066CC),
          padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        );
      case ThemeOption.colorful:
        return const TreeViewStyle(
          indentAmount: 24.0,
          idleColor: Colors.transparent,
          hoverColor: Color(0x333B82F6),
          selectedColor: Color(0x663B82F6),
          dropIndicatorColor: Color(0xFF3B82F6),
          padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        );
    }
  }

  FileSystemIconProvider _getIconProvider() {
    switch (widget.currentTheme) {
      case ThemeOption.vscode:
        return MaterialFileSystemIconProvider(
          folderColor: Colors.blueAccent,
          defaultFileColor: Colors.white54,
        );
      case ThemeOption.finder:
        return CupertinoFileSystemIconProvider(
          folderColor: const Color(0xFF3B82F6),
        );
      case ThemeOption.colorful:
        return MaterialFileSystemIconProvider(
          folderIcon: Icons.folder_rounded,
          folderExpandedIcon: Icons.folder_open_rounded,
          folderColor: Colors.amber[400]!,
          defaultFileIcon: Icons.text_snippet_rounded,
          defaultFileColor: Colors.blue[300]!,
        );
    }
  }
}

