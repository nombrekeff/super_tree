import 'package:flutter/material.dart';
import 'package:super_tree/src/configs/cupertino_file_system_icon_provider.dart';
import 'package:super_tree/src/configs/file_system_icon_provider.dart';
import 'package:super_tree/src/configs/tree_view_style.dart';

/// A reusable bundle of style and icon defaults for a SuperTree experience.
class SuperTreeThemePreset {
  /// Tree row and interaction visuals.
  final TreeViewStyle treeStyle;

  /// Optional file-system icon mapping used by [FileSystemSuperTree].
  final FileSystemIconProvider? fileSystemIconProvider;

  /// Optional suggested sidebar color for host layouts.
  final Color? sidebarColor;

  /// Suggested app brightness for container screens.
  final Brightness brightness;

  /// Suggested scaffold background for host layouts.
  final Color scaffoldBackgroundColor;

  /// Suggested surface color for app bars/cards.
  final Color surfaceColor;

  /// Optional primary color override for the host color scheme.
  final Color? primaryColor;

  const SuperTreeThemePreset({
    required this.treeStyle,
    this.fileSystemIconProvider,
    this.sidebarColor,
    required this.brightness,
    required this.scaffoldBackgroundColor,
    required this.surfaceColor,
    this.primaryColor,
  });

  /// Builds a material [ThemeData] that matches this preset.
  ThemeData toThemeData() {
    final ThemeData baseTheme = brightness == Brightness.dark
        ? ThemeData.dark()
        : ThemeData.light();
    final ColorScheme baseScheme = brightness == Brightness.dark
        ? const ColorScheme.dark()
        : const ColorScheme.light();

    final ColorScheme colorScheme = baseScheme.copyWith(
      surface: surfaceColor,
      primary: primaryColor ?? baseScheme.primary,
    );

    return baseTheme.copyWith(
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      colorScheme: colorScheme,
      cardColor: surfaceColor,
    );
  }
}

/// Prebuilt visual presets for common SuperTree use cases.
class SuperTreeThemes {
  const SuperTreeThemes._();

  /// VS Code-inspired dark preset.
  static SuperTreeThemePreset vscode() {
    return SuperTreeThemePreset(
      treeStyle: const TreeViewStyle(
        indentAmount: 16.0,
        idleColor: Colors.transparent,
        hoverColor: Color(0x1AFFFFFF),
        selectedColor: Color(0x33FFFFFF),
        dropIndicatorColor: Colors.blue,
        padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      ),
      fileSystemIconProvider: MaterialFileSystemIconProvider(
        folderColor: Colors.blueAccent,
        defaultFileColor: Colors.white54,
      ),
      sidebarColor: const Color(0xFF1E1E1E),
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF181818),
      surfaceColor: const Color(0xFF252526),
    );
  }

  /// Material-oriented default preset.
  static SuperTreeThemePreset material() {
    return SuperTreeThemePreset(
      treeStyle: const TreeViewStyle(
        indentAmount: 20.0,
        idleColor: Colors.transparent,
        hoverColor: Color(0x1A000000),
        selectedColor: Color(0x330066CC),
        dropIndicatorColor: Color(0xFF0066CC),
        padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      ),
      fileSystemIconProvider: MaterialFileSystemIconProvider(
        folderColor: Color(0xFF3B82F6),
      ),
      sidebarColor: const Color(0xFFF3F4F6),
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      surfaceColor: const Color(0xFFFFFFFF),
    );
  }

  /// Compact layout preset with tighter density and Cupertino-style icons.
  static SuperTreeThemePreset compact() {
    return SuperTreeThemePreset(
      treeStyle: const TreeViewStyle(
        indentAmount: 14.0,
        idleColor: Colors.transparent,
        hoverColor: Color(0x143B82F6),
        selectedColor: Color(0x293B82F6),
        dropIndicatorColor: Color(0xFF3B82F6),
        padding: EdgeInsets.symmetric(vertical: 2.0, horizontal: 6.0),
      ),
      fileSystemIconProvider: CupertinoFileSystemIconProvider(
        folderColor: Color(0xFF3B82F6),
      ),
      sidebarColor: const Color(0xFF1E293B),
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      surfaceColor: const Color(0xFF1E293B),
      primaryColor: const Color(0xFF3B82F6),
    );
  }
}
