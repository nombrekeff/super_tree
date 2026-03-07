import '../super_tree_data.dart';

/// A base ergonomic class for representing file system structures in a tree view.
abstract class FileSystemItem with SuperTreeData {
  String name;

  FileSystemItem(this.name);

  bool get isFolder;
}

/// A prebuilt data item representing a folder.
/// Folders can have children and can receive drops.
class FolderItem extends FileSystemItem {
  FolderItem(super.name);

  @override
  bool get isFolder => true;

  @override
  bool get canHaveChildren => true;
}

/// A prebuilt data item representing a file.
/// Files cannot have children and cannot receive items dropped *inside* them.
class FileItem extends FileSystemItem {
  FileItem(super.name);

  @override
  bool get isFolder => false;

  @override
  bool get canHaveChildren => false;
}
