import 'package:flutter/material.dart';
import 'package:super_tree/src/models/prebuilt/file_system_item.dart';
import 'package:super_tree/src/models/tree_node.dart';
import 'icon_provider.dart';

/// Defines an interface for providing icons to a FileSystemSuperTree.
/// By passing the whole [TreeNode], consumers have access to the data, 
/// as well as the node's expansion state, selected state, and depth.
abstract class FileSystemIconProvider extends SuperTreeIconProvider<FileSystemItem> {
  final Map<String, IconData> fileExtensionMap;
  final Map<String, Color> fileExtensionColors;

  FileSystemIconProvider({
    Map<String, IconData>? customExtensionMap,
    Map<String, Color>? customExtensionColors,
  })  : fileExtensionMap = customExtensionMap == null
            ? defaultExtensionMap
            : {...defaultExtensionMap, ...customExtensionMap},
        fileExtensionColors = customExtensionColors == null
            ? defaultExtensionColors
            : {...defaultExtensionColors, ...customExtensionColors};

  static const Map<String, IconData> defaultExtensionMap = {
    // Code / Text
    '.dart': Icons.code,
    '.yaml': Icons.settings,
    '.yml': Icons.settings,
    '.md': Icons.description,
    '.json': Icons.data_object,
    '.txt': Icons.text_snippet,
    '.html': Icons.html,
    '.css': Icons.css,
    '.js': Icons.javascript,
    '.ts': Icons.javascript,
    '.xml': Icons.code,
    '.c': Icons.code,
    '.cpp': Icons.code,
    '.h': Icons.code,
    '.py': Icons.code,
    '.java': Icons.code,
    '.sh': Icons.terminal,
    '.sql': Icons.storage,
    // Images
    '.png': Icons.image,
    '.jpg': Icons.image,
    '.jpeg': Icons.image,
    '.gif': Icons.gif,
    '.svg': Icons.image,
    '.webp': Icons.image,
    // Audio
    '.mp3': Icons.audio_file,
    '.wav': Icons.audio_file,
    '.ogg': Icons.audio_file,
    // Video
    '.mp4': Icons.video_file,
    '.avi': Icons.video_file,
    '.mov': Icons.video_file,
    '.mkv': Icons.video_file,
    // Documents
    '.pdf': Icons.picture_as_pdf,
    '.doc': Icons.description,
    '.docx': Icons.description,
    '.xls': Icons.table_chart,
    '.xlsx': Icons.table_chart,
    '.ppt': Icons.present_to_all,
    '.pptx': Icons.present_to_all,
    '.csv': Icons.table_chart,
    // Archives
    '.zip': Icons.folder_zip,
    '.rar': Icons.folder_zip,
    '.tar': Icons.folder_zip,
    '.gz': Icons.folder_zip,
    '.7z': Icons.folder_zip,
  };

  static const Map<String, Color> defaultExtensionColors = {
    // Code
    '.dart': Colors.blue,
    '.yaml': Colors.red,
    '.yml': Colors.red,
    '.md': Colors.yellow,
    '.json': Colors.green,
    '.html': Colors.orange,
    '.css': Colors.blue,
    '.js': Colors.yellow,
    '.ts': Colors.blue,
    '.py': Colors.yellow,
    '.java': Colors.orange,
    '.sh': Colors.green,
    '.sql': Colors.blue,
    // Media
    '.png': Colors.purple,
    '.jpg': Colors.purple,
    '.jpeg': Colors.purple,
    '.gif': Colors.purple,
    '.svg': Colors.orange,
    '.mp4': Colors.pink,
    '.mp3': Colors.pink,
    // Documents
    '.pdf': Colors.red,
    '.xls': Colors.green,
    '.xlsx': Colors.green,
    '.doc': Colors.blue,
    '.docx': Colors.blue,
    '.ppt': Colors.orange,
    '.pptx': Colors.orange,
    '.csv': Colors.green,
    // Archives
    '.zip': Colors.red,
    '.rar': Colors.red,
    '.tar': Colors.red,
    '.gz': Colors.red,
    '.7z': Colors.red,
  };
}

/// A default material icon provider for file systems.
class MaterialFileSystemIconProvider extends FileSystemIconProvider {
  final IconData folderIcon;
  final IconData folderExpandedIcon;
  final Color folderColor;
  
  final IconData defaultFileIcon;
  final Color defaultFileColor;

  MaterialFileSystemIconProvider({
    super.customExtensionMap,
    super.customExtensionColors,
    this.folderIcon = Icons.folder,
    this.folderExpandedIcon = Icons.folder_open,
    this.folderColor = Colors.amber,
    this.defaultFileIcon = Icons.insert_drive_file,
    this.defaultFileColor = Colors.grey,
  });

  @override
  Widget getIcon(TreeNode<FileSystemItem> node) {
    if (node.data.isFolder) {
      return Icon(
        node.isExpanded ? folderExpandedIcon : folderIcon,
        color: folderColor,
        size: 18,
      );
    }

    final name = node.data.name.toLowerCase();
    String? matchedExtension;
    
    for (final ext in fileExtensionMap.keys) {
      if (name.endsWith(ext)) {
        matchedExtension = ext;
        break;
      }
    }

    if (matchedExtension != null) {
      return Icon(
        fileExtensionMap[matchedExtension],
        color: fileExtensionColors[matchedExtension] ?? defaultFileColor,
        size: 18,
      );
    }

    return Icon(
      defaultFileIcon,
      color: defaultFileColor,
      size: 18,
    );
  }
}
