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
        id: 'Projects',
        data: FolderItem('Projects'),
        isExpanded: true,
        children: [
          TreeNode(
            id: 'SuperTree',
            data: FolderItem('SuperTree'),
            isExpanded: true,
            children: [
              TreeNode(id: 'lib', data: FolderItem('lib')),
              TreeNode(id: 'test', data: FolderItem('test')),
              TreeNode(id: 'README.md', data: FileItem('README.md')),
              TreeNode(id: 'pubspec.yaml', data: FileItem('pubspec.yaml')),
            ],
          ),
          TreeNode(
            id: 'FlutterApp',
            data: FolderItem('FlutterApp'),
            children: [
              TreeNode(id: 'main.dart', data: FileItem('main.dart')),
            ],
          ),
        ],
      ),
      TreeNode(
        id: 'Documents',
        data: FolderItem('Documents'),
        children: [
          TreeNode(id: 'Resume.pdf', data: FileItem('Resume.pdf')),
          TreeNode(id: 'Notes.txt', data: FileItem('Notes.txt')),
        ],
      ),
      TreeNode(id: 'config.json', data: FileItem('config.json')),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple File System'),
      ),
      body: FileSystemSuperTree(
        roots: folderRoots,
        logic: const TreeViewLogic(
          defaultSortComparator: TreeSort.foldersFirst,
        ),
      ),
    );
  }
}
