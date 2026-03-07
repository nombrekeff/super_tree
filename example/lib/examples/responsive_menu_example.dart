import 'package:flutter/material.dart';
import 'package:super_tree/super_tree.dart';

class ResponsiveMenuExample extends StatefulWidget {
  const ResponsiveMenuExample({super.key});

  @override
  State<ResponsiveMenuExample> createState() => _ResponsiveMenuExampleState();
}

class _ResponsiveMenuExampleState extends State<ResponsiveMenuExample> {
  final List<TreeNode<String>> _roots = [
    TreeNode(
      id: 'Workspace',
      data: 'Folder',
      isExpanded: true,
      children: [
        TreeNode(id: 'Project A', data: 'Folder'),
        TreeNode(id: 'Project B', data: 'Folder'),
        TreeNode(id: 'Config.yaml', data: 'File'),
      ],
    ),
    TreeNode(
      id: 'Settings',
      data: 'Folder',
      children: [
        TreeNode(id: 'Profile.json', data: 'File'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Determine if we should show a 3-dot menu or rely on context menus
    final bool isMobile = Theme.of(context).platform == TargetPlatform.iOS || 
                         Theme.of(context).platform == TargetPlatform.android;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Responsive Menus'),
            Text(
              isMobile ? 'Mobile: Long press or 3-dot' : 'Desktop: Right-click',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      body: SuperTreeView<String>(
        roots: _roots,
        logic: const TreeViewLogic(
          expansionTrigger: ExpansionTrigger.tap,
        ),
        prefixBuilder: (context, node) {
          final isFolder = node.data == 'Folder';
          return Icon(
            isFolder ? (node.isExpanded ? Icons.folder_open : Icons.folder) : Icons.insert_drive_file,
            size: 20,
            color: isFolder ? Colors.amber : Colors.blueGrey,
          );
        },
        contentBuilder: (context, node, renameField) {
          return Text(node.id);
        },
        // For mobile, we explicitly add a trailing 3-dot menu for discoverability
        trailingBuilder: isMobile ? (context, node) {
          return IconButton(
            icon: const Icon(Icons.more_vert, size: 20),
            onPressed: () {
              // Manually trigger the context menu overlay from a button
              final RenderBox box = context.findRenderObject() as RenderBox;
              final position = box.localToGlobal(Offset(box.size.width, box.size.height / 2));
              
              ContextMenuOverlay.show(
                context: context,
                position: position,
                items: _buildMenuItems(node),
                onDismissed: () {},
              );
            },
          );
        } : null,
        // Standard context menu builder for right-click/long-press
        contextMenuBuilder: (context, node) {
          return _buildMenuItems(node);
        },
      ),
    );
  }

  List<ContextMenuItem> _buildMenuItems(TreeNode<String> node) {
    return [
      ContextMenuItem(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Renaming ${node.id}')),
          );
        },
        child: const Row(
          children: [
            Icon(Icons.edit, size: 18),
            SizedBox(width: 12),
            Text('Rename'),
          ],
        ),
      ),
      ContextMenuItem(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Deleting ${node.id}')),
          );
        },
        child: const Row(
          children: [
            Icon(Icons.delete, size: 18, color: Colors.red),
            SizedBox(width: 12),
            Text('Delete', style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    ];
  }
}
