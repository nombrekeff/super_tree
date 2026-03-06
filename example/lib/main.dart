import 'package:flutter/material.dart';
import 'package:super_tree/super_tree.dart';

void main() {
  runApp(const MyApp());
}

class FileItem {
  final String name;
  final bool isFolder;
  FileItem(this.name, this.isFolder);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Super Tree Explorer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF181818),
        cardColor: const Color(0xFF252526),
      ),
      home: const TreeExampleScreen(),
    );
  }
}

class TreeExampleScreen extends StatefulWidget {
  const TreeExampleScreen({super.key});

  @override
  State<TreeExampleScreen> createState() => _TreeExampleScreenState();
}

class _TreeExampleScreenState extends State<TreeExampleScreen> {
  late TreeController<FileItem> _controller;

  @override
  void initState() {
    super.initState();
    _controller = TreeController<FileItem>(
      roots: [
        TreeNode(
          id: 'src',
          data: FileItem('src', true),
          isExpanded: true,
          children: [
            TreeNode(id: 'models', data: FileItem('models', true), children: [
              TreeNode(id: 'tree_node.dart', data: FileItem('tree_node.dart', false)),
            ]),
            TreeNode(id: 'controllers', data: FileItem('controllers', true), children: [
              TreeNode(id: 'tree_controller.dart', data: FileItem('tree_controller.dart', false)),
            ]),
          ],
        ),
        TreeNode(
          id: 'pubspec.yaml',
          data: FileItem('pubspec.yaml', false),
        ),
        TreeNode(
          id: 'README.md',
          data: FileItem('README.md', false),
        ),
      ]
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Tree Widget - File Explorer Demo'),
        backgroundColor: const Color(0xFF252526),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.expand),
            onPressed: _controller.expandAll,
            tooltip: 'Expand All',
          ),
          IconButton(
            icon: const Icon(Icons.compress),
            onPressed: _controller.collapseAll,
            tooltip: 'Collapse All',
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 300,
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: Colors.white12)),
              color: Color(0xFF1E1E1E), // standard side panel color
            ),
            child: SuperTreeView<FileItem>(
              controller: _controller,
              style: const TreeViewStyle(
                indentAmount: 16.0,
                idleColor: Colors.transparent,
                hoverColor: Color(0x1FFFFFFF),
              ),
              logic: const TreeViewLogic(
                enableDragAndDrop: true,
                expansionTrigger: ExpansionTrigger.tap,
              ),
              onContextMenu: _showContextMenu,
              prefixBuilder: (context, node) {
                if (node.data.isFolder) {
                  return Icon(
                    node.isExpanded ? Icons.folder_open : Icons.folder,
                    color: Colors.blueAccent,
                    size: 20,
                  );
                }
                return const SizedBox(width: 20); // Alignment spacing for files without caret
              },
              contentBuilder: (context, node) {
                return Padding(
                  padding: const EdgeInsets.only(left: 6.0),
                  child: Text(
                    node.data.name,
                    style: TextStyle(
                      color: node.data.isFolder ? Colors.white : Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                );
              },
            ),
          ),
          
          const Expanded(
            child: Center(
              child: Text(
                'Select a file to view',
                style: TextStyle(color: Colors.white54, fontSize: 18),
              ),
            ),
          )
        ],
      ),
    );
  }
}
