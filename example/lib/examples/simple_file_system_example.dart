import 'package:flutter/material.dart';
import 'package:super_tree/super_tree.dart';

class SimpleFileSystemExample extends StatelessWidget {
  const SimpleFileSystemExample({super.key});

  @override
  Widget build(BuildContext context) {
    // A hardcoded tree structure using FileSystemItem.
    // FileSystemSuperTree handles icons and layout automatically.
    final List<TreeNode<FileSystemItem>> folderRoots = [
      TreeNode(
        data: FolderItem('Projects'),
        isExpanded: true,
        children: [
          TreeNode(
            data: FolderItem('SuperTree'),
            isExpanded: true,
            children: [
              TreeNode(data: FolderItem('lib')),
              TreeNode(data: FolderItem('test')),
              TreeNode(data: FileItem('README.md')),
              TreeNode(data: FileItem('pubspec.yaml')),
            ],
          ),
          TreeNode(
            data: FolderItem('FlutterApp'),
            children: [
              TreeNode(data: FileItem('main.dart')),
            ],
          ),
        ],
      ),
      TreeNode(
        data: FolderItem('Documents'),
        children: [
          TreeNode(data: FileItem('Resume.pdf')),
          TreeNode(data: FileItem('Notes.txt')),
        ],
      ),
      TreeNode(data: FileItem('config.json')),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple File System'),
      ),
      body: FileSystemSuperTree(
        roots: folderRoots,
        logic: const TreeViewConfig(
          defaultSortComparator: TreeSort.foldersFirst,
        ),
      ),
    );
  }
}
