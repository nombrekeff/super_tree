import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_tree/super_tree.dart';

void main() {
  group('SuperTreeView Widget Tests', () {
    late List<TreeNode<String>> roots;

    setUp(() {
      roots = [
        TreeNode(
          id: 'root_1',
          data: 'Root 1',
          isExpanded: true,
          children: [
            TreeNode(id: 'child_1_1', data: 'Child 1.1'),
            TreeNode(id: 'child_1_2', data: 'Child 1.2'),
          ],
        ),
        TreeNode(id: 'root_2', data: 'Root 2'),
      ];
    });

    Widget createTestableWidget(Widget child) {
      return MaterialApp(
        home: Scaffold(
          body: child,
        ),
      );
    }

    testWidgets('Renders all visible nodes', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          SuperTreeView<String>(
            roots: roots,
            prefixBuilder: (context, node) => const Icon(Icons.chevron_right),
            contentBuilder: (context, node, renameField) => Text(node.data),
          ),
        ),
      );

      // root_1, child_1_1, child_1_2, root_2 should be visible
      expect(find.text('Root 1'), findsOneWidget);
      expect(find.text('Child 1.1'), findsOneWidget);
      expect(find.text('Child 1.2'), findsOneWidget);
      expect(find.text('Root 2'), findsOneWidget);
    });

    testWidgets('Expansion/Collapse via icon tap', (WidgetTester tester) async {
      final nodeToExpand = TreeNode<String>(
        id: 'test_root',
        data: 'Test Root',
        children: [TreeNode(id: 'test_child', data: 'Test Child')],
      );
      final controller = TreeController<String>(roots: [nodeToExpand]);

      await tester.pumpWidget(
        createTestableWidget(
          SuperTreeView<String>(
            controller: controller,
            prefixBuilder: (context, node) => const Icon(Icons.person),
            contentBuilder: (context, node, renameField) => Text(node.data),
            logic: const TreeViewConfig(
              expansionTrigger: ExpansionTrigger.iconTap,
            ),
          ),
        ),
      );

      expect(find.text('Test Child'), findsNothing);

      // Tap the expansion icon
      await tester.tap(find.byKey(Key('expansion_caret_${nodeToExpand.id}')));
      await tester.pumpAndSettle();

      expect(find.text('Test Child'), findsOneWidget);

      // Tap again to collapse
      await tester.tap(find.byKey(Key('expansion_caret_${nodeToExpand.id}')));
      await tester.pumpAndSettle();

      expect(find.text('Test Child'), findsNothing);
    });

    testWidgets('Expansion/Collapse via full row tap', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          SuperTreeView<String>(
            roots: [
              TreeNode(
                id: 'root_1',
                data: 'Root 1',
                children: [TreeNode(id: 'child_1', data: 'Child 1')],
              ),
            ],
            prefixBuilder: (context, node) => const Icon(Icons.chevron_right),
            contentBuilder: (context, node, renameField) => Text(node.data),
            logic: const TreeViewConfig(
              expansionTrigger: ExpansionTrigger.tap,
            ),
          ),
        ),
      );

      expect(find.text('Child 1'), findsNothing);

      // Tap the root_1 row
      await tester.tap(find.text('Root 1'));
      await tester.pumpAndSettle();

      expect(find.text('Child 1'), findsOneWidget);
    });

    testWidgets('Rename interaction via click', (WidgetTester tester) async {
      String? renamedId;
      String? renamedValue;

      final controller = TreeController<String>(
        roots: [TreeNode(id: 'node_1', data: 'Initial Name')],
        onNodeRenamed: (node, newName) {
          renamedId = node.id;
          renamedValue = newName;
          // In a real app, you'd update your data model here
          (node.data as dynamic); // Mock data update if needed
        },
      );

      await tester.pumpWidget(
        createTestableWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return SuperTreeView<String>(
                controller: controller,
                prefixBuilder: (context, node) => const Icon(Icons.chevron_right),
                contentBuilder: (context, node, renameField) {
                  if (renameField != null) return renameField;
                  // Handle data update manually for test simplicity if not using a real model
                  return Text(renamedId == node.id ? renamedValue! : node.data);
                },
                logic: const TreeViewConfig(
                  namingStrategy: TreeNamingStrategy.click,
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('Initial Name'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);

      // Tap to trigger rename
      await tester.tap(find.text('Initial Name'));
      await tester.pump(); 

      expect(find.byType(TextField), findsOneWidget);

      // Enter new name
      await tester.enterText(find.byType(TextField), 'New Name');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);
      expect(find.text('New Name'), findsOneWidget);
      expect(renamedId, 'node_1');
      expect(renamedValue, 'New Name');
    });

    testWidgets('Context menu triggers on secondary tap (Desktop)', (WidgetTester tester) async {
      bool menuBuilt = false;
      await tester.pumpWidget(
        createTestableWidget(
          SuperTreeView<String>(
            roots: [TreeNode(id: 'node_1', data: 'Node 1')],
            prefixBuilder: (context, node) => const Icon(Icons.chevron_right),
            contentBuilder: (context, node, renameField) => Text(node.data),
            contextMenuBuilder: (context, node) {
              menuBuilt = true;
              return [
                ContextMenuItem(
                  child: const Text('Action'),
                  onTap: () {},
                ),
              ];
            },
          ),
        ),
      );

      // Right click on Node 1
      await tester.tap(find.text('Node 1'), buttons: kSecondaryButton);
      await tester.pumpAndSettle();

      expect(menuBuilt, isTrue);
      expect(find.text('Action'), findsOneWidget);
    });

    testWidgets('Drag and drop interaction', (WidgetTester tester) async {
      TreeNode<String>? dragged;
      TreeNode<String>? target;

      final controller = TreeController<String>(
        roots: [
          TreeNode(id: 'node_alpha', data: 'Alpha'),
          TreeNode(id: 'node_beta', data: 'Beta'),
        ],
      );

      await tester.pumpWidget(
        createTestableWidget(
          SuperTreeView<String>(
            controller: controller,
            prefixBuilder: (context, node) => const Icon(Icons.chevron_right),
            contentBuilder: (context, node, renameField) => Text(node.data),
            logic: TreeViewConfig(
              enableDragAndDrop: true,
              canAcceptDrop: (d, t, p) {
                dragged = d;
                target = t;
                return true;
              },
            ),
          ),
        ),
      );

      // Drag Alpha onto Beta
      // We drag from Alpha's center to Beta's center
      final alphaCenter = tester.getCenter(find.text('Alpha'));
      final betaCenter = tester.getCenter(find.text('Beta'));
      
      await tester.dragFrom(alphaCenter, betaCenter - alphaCenter);
      await tester.pumpAndSettle();

      expect(dragged?.id, 'node_alpha');
      expect(target?.id, 'node_beta');
    });

    testWidgets('Keyboard interactions work after tapping tree content', (WidgetTester tester) async {
      final TreeController<String> controller = TreeController<String>(
        roots: <TreeNode<String>>[
          TreeNode(id: 'root_1', data: 'Root 1'),
          TreeNode(id: 'root_2', data: 'Root 2'),
        ],
      );

      addTearDown(() {
        controller.dispose();
      });

      await tester.pumpWidget(
        createTestableWidget(
          SuperTreeView<String>(
            controller: controller,
            prefixBuilder: (BuildContext context, TreeNode<String> node) {
              return const Icon(Icons.chevron_right);
            },
            contentBuilder: (BuildContext context, TreeNode<String> node, Widget? renameField) {
              return Text(node.data);
            },
          ),
        ),
      );

      await tester.tap(find.text('Root 1'));
      await tester.pumpAndSettle();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA);
      await tester.pump();

      expect(controller.selectedNodeId, 'root_1');

      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();

      expect(controller.selectedNodeId, 'root_2');
    });

    testWidgets('FileSystemSuperTree uses icon provider in default prefix builder', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          FileSystemSuperTree(
            roots: <TreeNode<FileSystemItem>>[
              TreeNode<FileSystemItem>(
                data: FolderItem('lib'),
                isExpanded: true,
                children: <TreeNode<FileSystemItem>>[
                  TreeNode<FileSystemItem>(data: FileItem('README.md')),
                ],
              ),
            ],
          ),
        ),
      );

      expect(find.byIcon(Icons.folder_open), findsOneWidget);
      expect(find.byIcon(Icons.description), findsOneWidget);
      expect(find.text('lib'), findsOneWidget);
      expect(find.text('README.md'), findsOneWidget);
    });

    testWidgets('FileSystemSuperTree keeps custom prefixBuilder override precedence', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          FileSystemSuperTree(
            roots: <TreeNode<FileSystemItem>>[
              TreeNode<FileSystemItem>(data: FolderItem('src')),
            ],
            prefixBuilder: (BuildContext context, TreeNode<FileSystemItem> node) {
              return const Icon(Icons.star);
            },
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.text('src'), findsOneWidget);
    });

    testWidgets('SuperTreeThemes presets expose usable style and icon providers', (WidgetTester tester) async {
      final SuperTreeThemePreset vscodePreset = SuperTreeThemes.vscode();
      final SuperTreeThemePreset materialPreset = SuperTreeThemes.material();
      final SuperTreeThemePreset compactPreset = SuperTreeThemes.compact();

      expect(vscodePreset.fileSystemIconProvider, isNotNull);
      expect(materialPreset.fileSystemIconProvider, isNotNull);
      expect(compactPreset.fileSystemIconProvider, isNotNull);
      expect(vscodePreset.treeStyle.indentAmount, 16.0);
      expect(materialPreset.treeStyle.indentAmount, 20.0);
      expect(compactPreset.treeStyle.indentAmount, 14.0);
    });

    testWidgets('TreeHighlightedLabel renders RichText when there are matched indices', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          const TreeHighlightedLabel(
            text: 'README.md',
            matchedIndices: <int>[0, 1, 2, 3],
          ),
        ),
      );

      expect(find.byType(RichText), findsOneWidget);
      expect(find.text('README.md'), findsNothing);
    });
  });
}
