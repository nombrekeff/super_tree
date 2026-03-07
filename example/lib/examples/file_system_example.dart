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

class FileItem {
  final String name;
  final bool isFolder;
  FileItem(this.name, this.isFolder);
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
  late TreeController<FileItem> _controller;
  SortOption _currentSort = SortOption.none;

  @override
  void initState() {
    super.initState();
    _controller = TreeController<FileItem>(
      roots: [
        TreeNode(
          id: 'super_tree',
          data: FileItem('super_tree', true),
          isExpanded: true,
          children: [
            TreeNode(
              id: 'lib',
              data: FileItem('lib', true),
              isExpanded: true,
              children: [
                TreeNode(
                  id: 'src',
                  data: FileItem('src', true),
                  children: [
                    TreeNode(
                      id: 'models',
                      data: FileItem('models', true),
                      children: [
                        TreeNode(id: 'tree_node.dart', data: FileItem('tree_node.dart', false)),
                      ],
                    ),
                    TreeNode(
                      id: 'configs',
                      data: FileItem('configs', true),
                      children: [
                        TreeNode(id: 'tree_view_style.dart', data: FileItem('tree_view_style.dart', false)),
                      ],
                    ),
                  ],
                ),
                TreeNode(id: 'super_tree.dart', data: FileItem('super_tree.dart', false)),
              ],
            ),
            TreeNode(
              id: 'example',
              data: FileItem('example', true),
              children: [
                TreeNode(
                  id: 'lib',
                  data: FileItem('lib', true),
                  children: [
                    TreeNode(id: 'main.dart', data: FileItem('main.dart', false)),
                  ],
                ),
              ],
            ),
            TreeNode(id: 'pubspec.yaml', data: FileItem('pubspec.yaml', false)),
            TreeNode(id: 'README.md', data: FileItem('README.md', false)),
            TreeNode(id: 'CHANGELOG.md', data: FileItem('CHANGELOG.md', false)),
          ],
        ),
      ],
    );
  }

  void _showContextMenu(BuildContext context, TreeNode<FileItem> node, Offset position) {
    ContextMenuOverlay.show(
      context: context,
      position: position,
      items: [
        ContextMenuItem(
          child: const Text('Rename'),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Renaming ${node.data.name}')));
          },
        ),
        ContextMenuItem(
          child: const Text('Delete', style: TextStyle(color: Colors.red)),
          onTap: () {
            _controller.removeNode(node);
          },
        ),
      ],
    );
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
            child: SuperTreeView<FileItem>(
              controller: _controller,
              style: _getTreeStyle(),
              logic: TreeViewLogic(
                enableDragAndDrop: true,
                expansionTrigger: ExpansionTrigger.tap,
                canAcceptDrop: (draggedNode, targetNode, position) {
                  // Prevent dropping inside a file
                  if (position == NodeDropPosition.inside && !targetNode.data.isFolder) {
                    return false;
                  }
                  return true;
                },
              ),
              onContextMenu: _showContextMenu,
              prefixBuilder: _buildPrefix,
              contentBuilder: _buildContent,
            ),
          ),
          
          Expanded(
            child: Container(
              color: theme.scaffoldBackgroundColor,
              child: Center(
                child: Column(
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

  Widget _buildPrefix(BuildContext context, TreeNode<FileItem> node) {
    switch (widget.currentTheme) {
      case ThemeOption.vscode:
        if (node.data.isFolder) {
          return Icon(
            node.isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
            color: Colors.white54,
            size: 18,
          );
        }
        return const SizedBox(width: 18);
        
      case ThemeOption.finder:
        if (node.data.isFolder) {
          return Icon(
            node.isExpanded ? Icons.expand_more : Icons.chevron_right,
            color: Colors.black54,
            size: 20,
          );
        }
        return const SizedBox(width: 20);

      case ThemeOption.colorful:
        if (node.data.isFolder) {
          return AnimatedRotation(
            turns: node.isExpanded ? 0.25 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(
              Icons.chevron_right,
              color: Colors.white,
              size: 20,
            ),
          );
        }
        return const SizedBox(width: 20);
    }
  }

  Widget _buildContent(BuildContext context, TreeNode<FileItem> node) {
    switch (widget.currentTheme) {
      case ThemeOption.vscode:
        return Padding(
          padding: const EdgeInsets.only(left: 6.0),
          child: Row(
            children: [
              if (node.data.isFolder)
                Icon(
                  node.isExpanded ? Icons.folder_open : Icons.folder,
                  color: Colors.blueAccent,
                  size: 18,
                )
              else
                Icon(
                  _getFileIcon(node.data.name),
                  color: _getFileColor(node.data.name),
                  size: 18,
                ),
              const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    node.data.name,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: TextStyle(
                      color: node.data.isFolder ? Colors.white : Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
        );
        
      case ThemeOption.finder:
        return Padding(
          padding: const EdgeInsets.only(left: 6.0),
          child: Row(
            children: [
              if (node.data.isFolder)
                const Icon(
                  Icons.folder,
                  color: Color(0xFF7CB342),
                  size: 20,
                )
              else
                const Icon(
                  Icons.insert_drive_file_outlined,
                  color: Colors.black45,
                  size: 18,
                ),
              const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    node.data.name,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
        );
        
      case ThemeOption.colorful:
        return Padding(
          padding: const EdgeInsets.only(left: 6.0),
          child: Row(
            children: [
              if (node.data.isFolder)
                Icon(
                  Icons.folder_rounded,
                  color: Colors.amber[400],
                  size: 22,
                )
              else
                Icon(
                  Icons.text_snippet_rounded,
                  color: Colors.blue[300],
                  size: 22,
                ),
              const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    node.data.name,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
            ],
          ),
        );
    }
  }

  IconData _getFileIcon(String name) {
    if (name.endsWith('.dart')) return Icons.code;
    if (name.endsWith('.yaml')) return Icons.settings;
    if (name.endsWith('.md')) return Icons.description;
    return Icons.insert_drive_file;
  }

  Color _getFileColor(String name) {
    if (name.endsWith('.dart')) return Colors.blue[300]!;
    if (name.endsWith('.yaml')) return Colors.red[300]!;
    if (name.endsWith('.md')) return Colors.yellow[300]!;
    return Colors.white54;
  }
}
