import 'package:example/examples/async_lazy_loading_example.dart';
import 'package:example/examples/checkbox_example.dart';
import 'package:example/examples/complex_node_example.dart';
import 'package:example/examples/file_system_example.dart';
import 'package:example/examples/integrity_guardrails_example.dart';
import 'package:example/examples/simple_file_system_example.dart';
import 'package:example/examples/todo_list_example.dart';
import 'package:example/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:super_tree/super_tree.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await loadAppFonts();
  });

  testWidgets('generates file explorer preview with search', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(_buildPreviewShell(const FileSystemExample()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.search).first);
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Scaffold).first,
      matchesGoldenFile('../../assets/screenshots/file-system-search-macos.png'),
    );
  });

  testWidgets('generates expanded file explorer tree only preview', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(512, 1116));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    final TreeController<FileSystemItem> controller = _buildFileSystemPreviewController();
    addTearDown(controller.dispose);

    controller.expandAll();

    await tester.pumpWidget(_buildPreviewShell(_buildTreeOnlyPreview(controller)));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(FileSystemSuperTree).first,
      matchesGoldenFile('../../assets/screenshots/demo_tree.png'),
    );
  });

  testWidgets('generates todo tree preview', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(_buildPreviewShell(const TodoListExample()));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Scaffold).first,
      matchesGoldenFile('../../assets/screenshots/todo-tree-macos.png'),
    );
  });

  testWidgets('generates checkbox state preview', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(_buildPreviewShell(const CheckboxExample()));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Scaffold).first,
      matchesGoldenFile('../../assets/screenshots/checkbox-state-macos.png'),
    );
  });

  testWidgets('generates complex node ui preview', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(_buildPreviewShell(const ComplexNodeExample()));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Scaffold).first,
      matchesGoldenFile('../../assets/screenshots/complex-node-ui-macos.png'),
    );
  });

  testWidgets('generates minimal file system preview', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(_buildPreviewShell(const SimpleFileSystemExample()));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Scaffold).first,
      matchesGoldenFile('../../assets/screenshots/minimal-file-system-macos.png'),
    );
  });

  testWidgets('generates async lazy loading preview', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(_buildPreviewShell(const AsyncLazyLoadingExample()));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Scaffold).first,
      matchesGoldenFile('../../assets/screenshots/async-lazy-loading-macos.png'),
    );
  });

  testWidgets('generates integrity guardrails preview', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(_buildPreviewShell(const IntegrityGuardrailsExample()));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Scaffold).first,
      matchesGoldenFile('../../assets/screenshots/integrity-guardrails-macos.png'),
    );
  });
}

Widget _buildPreviewShell(Widget child) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      useMaterial3: true,
    ),
    darkTheme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
      useMaterial3: true,
    ),
    themeMode: ThemeMode.dark,
    home: child,
  );
}

Widget _buildTreeOnlyPreview(TreeController<FileSystemItem> controller) {
  final SuperTreeThemePreset preset = SuperTreeThemes.vscode();
  final TreeViewStyle previewStyle = preset.treeStyle.copyWith(
    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
    indentAmount: 34.0,
    textStyle: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.w500),
    labelStyle: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.w500),
  );
  final FileSystemTreeTheme previewTheme = FileSystemTreeTheme.material(
    iconProvider: _LargePreviewFileSystemIconProvider(),
    labelPadding: const EdgeInsets.only(left: 10.0),
  );

  return Scaffold(
    backgroundColor: preset.scaffoldBackgroundColor,
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 24.0),
          child: Container(
            decoration: BoxDecoration(
              color: preset.surfaceColor,
              borderRadius: BorderRadius.circular(8.0),
            ),
            padding: const EdgeInsets.only(top: 16.0, left: 16),
            child: FileSystemSuperTree(
              controller: controller,
              style: previewStyle,
              fileSystemTheme: previewTheme,
              logic: const TreeViewConfig(
                expansionTrigger: ExpansionTrigger.tap,
                selectionMode: SelectionMode.multiple,
                namingStrategy: TreeNamingStrategy.contextMenu,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _LargePreviewFileSystemIconProvider extends FileSystemIconProvider {
  _LargePreviewFileSystemIconProvider();

  @override
  Widget getIcon(TreeNode<FileSystemItem> node) {
    if (node.data.isFolder) {
      return Icon(
        node.isExpanded ? Icons.folder_open : Icons.folder,
        color: Colors.amber,
        size: 24,
      );
    }

    final String name = node.data.name.toLowerCase();
    String? matchedExtension;

    for (final String ext in fileExtensionMap.keys) {
      if (name.endsWith(ext)) {
        matchedExtension = ext;
        break;
      }
    }

    if (matchedExtension != null) {
      return Icon(
        fileExtensionMap[matchedExtension],
        color: fileExtensionColors[matchedExtension] ?? Colors.grey,
        size: 24,
      );
    }

    return const Icon(Icons.insert_drive_file, color: Colors.grey, size: 24);
  }
}

TreeController<FileSystemItem> _buildFileSystemPreviewController() {
  return TreeController<FileSystemItem>(
    roots: <TreeNode<FileSystemItem>>[
      TreeNode<FileSystemItem>(
        data: FolderItem('super_tree'),
        isExpanded: true,
        children: <TreeNode<FileSystemItem>>[
          TreeNode<FileSystemItem>(
            data: FolderItem('assets'),
            children: <TreeNode<FileSystemItem>>[
              TreeNode<FileSystemItem>(data: FileItem('logo.png')),
              TreeNode<FileSystemItem>(data: FileItem('intro.mp4')),
              TreeNode<FileSystemItem>(data: FileItem('theme.mp3')),
              TreeNode<FileSystemItem>(data: FileItem('archive.zip')),
              TreeNode<FileSystemItem>(data: FileItem('data.csv')),
              TreeNode<FileSystemItem>(data: FileItem('presentation.pptx')),
            ],
          ),
          TreeNode<FileSystemItem>(
            data: FolderItem('lib'),
            isExpanded: true,
            children: <TreeNode<FileSystemItem>>[
              TreeNode<FileSystemItem>(
                data: FolderItem('src'),
                isExpanded: true,
                children: <TreeNode<FileSystemItem>>[
                  TreeNode<FileSystemItem>(
                    data: FolderItem('models'),
                    children: <TreeNode<FileSystemItem>>[
                      TreeNode<FileSystemItem>(data: FileItem('tree_node.dart')),
                    ],
                  ),
                  TreeNode<FileSystemItem>(
                    data: FolderItem('configs'),
                    children: <TreeNode<FileSystemItem>>[
                      TreeNode<FileSystemItem>(data: FileItem('tree_view_style.dart')),
                    ],
                  ),
                ],
              ),
              TreeNode<FileSystemItem>(data: FileItem('super_tree.dart')),
            ],
          ),
          TreeNode<FileSystemItem>(
            data: FolderItem('example'),
            children: <TreeNode<FileSystemItem>>[
              TreeNode<FileSystemItem>(
                data: FolderItem('lib'),
                children: <TreeNode<FileSystemItem>>[
                  TreeNode<FileSystemItem>(data: FileItem('main.dart')),
                ],
              ),
            ],
          ),
          TreeNode<FileSystemItem>(data: FileItem('pubspec.yaml')),
          TreeNode<FileSystemItem>(data: FileItem('README.md')),
          TreeNode<FileSystemItem>(data: FileItem('CHANGELOG.md')),
        ],
      ),
    ],
  );
}
