import 'package:flutter/material.dart';
import 'package:super_tree/src/configs/file_system_icon_provider.dart';

/// Theme tokens for reusable file-system tree presentation.
class FileSystemTreeTheme {
  final FileSystemIconProvider iconProvider;
  final EdgeInsetsGeometry labelPadding;

  const FileSystemTreeTheme({
    required this.iconProvider,
    this.labelPadding = const EdgeInsets.only(left: 6.0),
  });

  static FileSystemTreeTheme material({
    FileSystemIconProvider? iconProvider,
    EdgeInsetsGeometry labelPadding = const EdgeInsets.only(left: 6.0),
  }) {
    return FileSystemTreeTheme(
      iconProvider: iconProvider ?? MaterialFileSystemIconProvider(),
      labelPadding: labelPadding,
    );
  }
}
