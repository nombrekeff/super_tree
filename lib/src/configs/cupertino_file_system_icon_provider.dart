import 'package:flutter/cupertino.dart';
import '../models/tree_node.dart';
import '../models/prebuilt/file_system_item.dart';
import 'file_system_icon_provider.dart';

/// A default Cupertino icon provider for file systems.
class CupertinoFileSystemIconProvider extends FileSystemIconProvider {
  final IconData folderIcon;
  final IconData folderExpandedIcon;
  final Color folderColor;
  
  final IconData defaultFileIcon;
  final Color defaultFileColor;

  CupertinoFileSystemIconProvider({
    Map<String, IconData>? customExtensionMap,
    super.customExtensionColors,
    this.folderIcon = CupertinoIcons.folder,
    this.folderExpandedIcon = CupertinoIcons.folder_open,
    this.folderColor = CupertinoColors.systemBlue,
    this.defaultFileIcon = CupertinoIcons.doc,
    this.defaultFileColor = CupertinoColors.systemGrey,
  }) : super(
         customExtensionMap: customExtensionMap == null 
             ? defaultCupertinoExtensionMap 
             : {...defaultCupertinoExtensionMap, ...customExtensionMap},
       );

  static const Map<String, IconData> defaultCupertinoExtensionMap = {
    // Code / Text
    '.dart': CupertinoIcons.chevron_left_slash_chevron_right,
    '.yaml': CupertinoIcons.settings,
    '.yml': CupertinoIcons.settings,
    '.md': CupertinoIcons.doc_text,
    '.json': CupertinoIcons.doc_text,
    '.txt': CupertinoIcons.doc_text,
    '.html': CupertinoIcons.chevron_left_slash_chevron_right,
    '.css': CupertinoIcons.paintbrush,
    '.js': CupertinoIcons.chevron_left_slash_chevron_right,
    '.ts': CupertinoIcons.chevron_left_slash_chevron_right,
    '.xml': CupertinoIcons.chevron_left_slash_chevron_right,
    '.c': CupertinoIcons.chevron_left_slash_chevron_right,
    '.cpp': CupertinoIcons.chevron_left_slash_chevron_right,
    '.h': CupertinoIcons.chevron_left_slash_chevron_right,
    '.py': CupertinoIcons.chevron_left_slash_chevron_right,
    '.java': CupertinoIcons.chevron_left_slash_chevron_right,
    '.sh': CupertinoIcons.chevron_left_slash_chevron_right,
    '.sql': CupertinoIcons.circle_grid_hex,
    // Images
    '.png': CupertinoIcons.photo,
    '.jpg': CupertinoIcons.photo,
    '.jpeg': CupertinoIcons.photo,
    '.gif': CupertinoIcons.photo,
    '.svg': CupertinoIcons.photo,
    '.webp': CupertinoIcons.photo,
    // Audio
    '.mp3': CupertinoIcons.music_note_2,
    '.wav': CupertinoIcons.music_note_2,
    '.ogg': CupertinoIcons.music_note_2,
    // Video
    '.mp4': CupertinoIcons.video_camera,
    '.avi': CupertinoIcons.video_camera,
    '.mov': CupertinoIcons.video_camera,
    '.mkv': CupertinoIcons.video_camera,
    // Documents
    '.pdf': CupertinoIcons.doc_on_doc,
    '.doc': CupertinoIcons.doc_richtext,
    '.docx': CupertinoIcons.doc_richtext,
    '.xls': CupertinoIcons.table,
    '.xlsx': CupertinoIcons.table,
    '.ppt': CupertinoIcons.projective,
    '.pptx': CupertinoIcons.projective,
    '.csv': CupertinoIcons.table,
    // Archives
    '.zip': CupertinoIcons.archivebox,
    '.rar': CupertinoIcons.archivebox,
    '.tar': CupertinoIcons.archivebox,
    '.gz': CupertinoIcons.archivebox,
    '.7z': CupertinoIcons.archivebox,
  };

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
