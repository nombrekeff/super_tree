import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
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
      return MaterialApp(home: Scaffold(body: child));
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
            logic: const TreeViewConfig(expansionTrigger: ExpansionTrigger.iconTap),
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
            logic: const TreeViewConfig(expansionTrigger: ExpansionTrigger.tap),
          ),
        ),
      );

      expect(find.text('Child 1'), findsNothing);

      // Tap the root_1 row
      await tester.tap(find.text('Root 1'));
      await tester.pumpAndSettle();

      expect(find.text('Child 1'), findsOneWidget);
    });

    testWidgets('Default node cursors reflect row and caret affordances', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestableWidget(
          SuperTreeView<String>(
            roots: <TreeNode<String>>[
              TreeNode<String>(
                id: 'expandable',
                data: 'Expandable',
                children: <TreeNode<String>>[TreeNode<String>(id: 'child', data: 'Child')],
              ),
              TreeNode<String>(id: 'leaf', data: 'Leaf'),
            ],
            prefixBuilder: (BuildContext context, TreeNode<String> node) {
              return const Icon(Icons.chevron_right);
            },
            contentBuilder: (BuildContext context, TreeNode<String> node, Widget? renameField) {
              return Text(node.data);
            },
          ),
        ),
      );

      final MouseRegion expandableRow = tester.widget<MouseRegion>(
        find.byKey(const Key('node_row_region_expandable')),
      );
      final MouseRegion caretRegion = tester.widget<MouseRegion>(
        find.byKey(const Key('node_caret_region_expandable')),
      );
      final MouseRegion leafRow = tester.widget<MouseRegion>(
        find.byKey(const Key('node_row_region_leaf')),
      );

      expect(expandableRow.cursor, SystemMouseCursors.click);
      expect(caretRegion.cursor, SystemMouseCursors.click);
      expect(leafRow.cursor, SystemMouseCursors.click);
    });

    testWidgets('Node cursor resolver supports custom per-state cursor behavior', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestableWidget(
          SuperTreeView<String>(
            roots: <TreeNode<String>>[
              TreeNode<String>(
                id: 'custom_expandable',
                data: 'Custom Expandable',
                children: <TreeNode<String>>[
                  TreeNode<String>(id: 'custom_child', data: 'Custom Child'),
                ],
              ),
              TreeNode<String>(id: 'custom_leaf', data: 'Custom Leaf'),
            ],
            logic: TreeViewConfig<String>(
              nodeCursorResolver: (
                TreeNode<String> _,
                TreeNodeCursorState state,
              ) {
                if (state.isExpansionToggle) {
                  return SystemMouseCursors.precise;
                }
                if (!state.canExpand) {
                  return SystemMouseCursors.forbidden;
                }
                return SystemMouseCursors.alias;
              },
            ),
            prefixBuilder: (BuildContext context, TreeNode<String> node) {
              return const Icon(Icons.chevron_right);
            },
            contentBuilder: (BuildContext context, TreeNode<String> node, Widget? renameField) {
              return Text(node.data);
            },
          ),
        ),
      );

      final MouseRegion rowRegion = tester.widget<MouseRegion>(
        find.byKey(const Key('node_row_region_custom_expandable')),
      );
      final MouseRegion caretRegion = tester.widget<MouseRegion>(
        find.byKey(const Key('node_caret_region_custom_expandable')),
      );
      final MouseRegion leafRegion = tester.widget<MouseRegion>(
        find.byKey(const Key('node_row_region_custom_leaf')),
      );

      expect(rowRegion.cursor, SystemMouseCursors.alias);
      expect(caretRegion.cursor, SystemMouseCursors.precise);
      expect(leafRegion.cursor, SystemMouseCursors.forbidden);
    });

    testWidgets('Default cursor falls back to basic when selection and drag are disabled', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestableWidget(
          SuperTreeView<String>(
            roots: <TreeNode<String>>[TreeNode<String>(id: 'disabled_leaf', data: 'Disabled Leaf')],
            logic: const TreeViewConfig<String>(
              selectionMode: SelectionMode.none,
              enableDragAndDrop: false,
            ),
            prefixBuilder: (BuildContext context, TreeNode<String> node) {
              return const Icon(Icons.chevron_right);
            },
            contentBuilder: (BuildContext context, TreeNode<String> node, Widget? renameField) {
              return Text(node.data);
            },
          ),
        ),
      );

      final MouseRegion disabledLeafRegion = tester.widget<MouseRegion>(
        find.byKey(const Key('node_row_region_disabled_leaf')),
      );
      expect(disabledLeafRegion.cursor, SystemMouseCursors.basic);
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
                logic: const TreeViewConfig(namingStrategy: TreeNamingStrategy.click),
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

    testWidgets('Rename cancels when tapping outside the field', (
      WidgetTester tester,
    ) async {
      String? renamedValue;

      final TreeController<String> controller = TreeController<String>(
        roots: <TreeNode<String>>[TreeNode<String>(id: 'node_1', data: 'Initial Name')],
        onNodeRenamed: (TreeNode<String> node, String newName) {
          renamedValue = newName;
        },
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
              return renameField ?? Text(node.data);
            },
            logic: const TreeViewConfig<String>(namingStrategy: TreeNamingStrategy.click),
          ),
        ),
      );

      await tester.tap(find.text('Initial Name'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Changed Outside');
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);
      expect(find.text('Initial Name'), findsOneWidget);
      expect(renamedValue, isNull);
      expect(controller.renamingNodeId, isNull);
    });

    testWidgets('Rename submits via check icon button', (
      WidgetTester tester,
    ) async {
      String? renamedValue;

      final TreeController<String> controller = TreeController<String>(
        roots: <TreeNode<String>>[TreeNode<String>(id: 'node_1', data: 'Initial Name')],
        onNodeRenamed: (TreeNode<String> node, String newName) {
          renamedValue = newName;
        },
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
              return renameField ?? Text(renamedValue ?? node.data);
            },
            logic: const TreeViewConfig<String>(namingStrategy: TreeNamingStrategy.click),
          ),
        ),
      );

      await tester.tap(find.text('Initial Name'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Renamed By Check');
      await tester.tap(find.byKey(const Key('super_tree_rename_submit_button_inner')));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);
      expect(find.text('Renamed By Check'), findsOneWidget);
      expect(renamedValue, 'Renamed By Check');
      expect(controller.renamingNodeId, isNull);
    });

    testWidgets('Rename cancels via cancel icon button', (
      WidgetTester tester,
    ) async {
      String? renamedValue;

      final TreeController<String> controller = TreeController<String>(
        roots: <TreeNode<String>>[TreeNode<String>(id: 'node_1', data: 'Initial Name')],
        onNodeRenamed: (TreeNode<String> node, String newName) {
          renamedValue = newName;
        },
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
              return renameField ?? Text(node.data);
            },
            logic: const TreeViewConfig<String>(namingStrategy: TreeNamingStrategy.click),
          ),
        ),
      );

      await tester.tap(find.text('Initial Name'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Canceled Name');
      await tester.tap(find.byKey(const Key('super_tree_rename_cancel_button_inner')));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);
      expect(find.text('Initial Name'), findsOneWidget);
      expect(renamedValue, isNull);
      expect(controller.renamingNodeId, isNull);
    });

    testWidgets('New node naming cancels on outside tap and removes node', (
      WidgetTester tester,
    ) async {
      final TreeController<String> controller = TreeController<String>(
        roots: <TreeNode<String>>[],
      );

      addTearDown(() {
        controller.dispose();
      });

      controller.createNewRoot('');

      await tester.pumpWidget(
        createTestableWidget(
          SuperTreeView<String>(
            controller: controller,
            prefixBuilder: (BuildContext context, TreeNode<String> node) {
              return const Icon(Icons.chevron_right);
            },
            contentBuilder: (BuildContext context, TreeNode<String> node, Widget? renameField) {
              return renameField ?? Text(node.data);
            },
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      expect(controller.roots.length, 1);

      await tester.enterText(find.byType(TextField), 'Unsaved Node');
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);
      expect(controller.renamingNodeId, isNull);
      expect(controller.roots, isEmpty);
      expect(find.text('Unsaved Node'), findsNothing);
    });

    testWidgets('New node naming submits via check icon and keeps node', (
      WidgetTester tester,
    ) async {
      String? renamedValue;
      final TreeController<String> controller = TreeController<String>(
        roots: <TreeNode<String>>[],
        onNodeRenamed: (TreeNode<String> node, String newName) {
          renamedValue = newName;
        },
      );

      addTearDown(() {
        controller.dispose();
      });

      controller.createNewRoot('');

      await tester.pumpWidget(
        createTestableWidget(
          SuperTreeView<String>(
            controller: controller,
            prefixBuilder: (BuildContext context, TreeNode<String> node) {
              return const Icon(Icons.chevron_right);
            },
            contentBuilder: (BuildContext context, TreeNode<String> node, Widget? renameField) {
              return renameField ?? Text(renamedValue ?? node.data);
            },
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Saved Node');
      await tester.tap(find.byKey(const Key('super_tree_rename_submit_button_inner')));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);
      expect(controller.renamingNodeId, isNull);
      expect(controller.roots.length, 1);
      expect(controller.roots.first.isNew, isFalse);
      expect(renamedValue, 'Saved Node');
      expect(find.text('Saved Node'), findsOneWidget);
    });

    testWidgets('Context menu triggers on secondary tap (Desktop)', (
      WidgetTester tester,
    ) async {
      bool menuBuilt = false;
      await tester.pumpWidget(
        createTestableWidget(
          SuperTreeView<String>(
            roots: [TreeNode(id: 'node_1', data: 'Node 1')],
            prefixBuilder: (context, node) => const Icon(Icons.chevron_right),
            contentBuilder: (context, node, renameField) => Text(node.data),
            contextMenuBuilder: (context, node) {
              menuBuilt = true;
              return [ContextMenuItem(child: const Text('Action'), onTap: () {})];
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
              dragAndDrop: TreeDragAndDropConfig(
                canAcceptDrop: (d, t, p) {
                  dragged = d;
                  target = t;
                  return true;
                },
              ),
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

    testWidgets('Drag and drop honors configurable edge drop bands', (
      WidgetTester tester,
    ) async {
      NodeDropPosition? observedPosition;

      final TreeController<String> controller = TreeController<String>(
        roots: [
          TreeNode(id: 'node_alpha', data: 'Alpha'),
          TreeNode(id: 'node_beta', data: 'Beta'),
        ],
      );

      await tester.pumpWidget(
        createTestableWidget(
          SuperTreeView<String>(
            controller: controller,
            style: const TreeViewStyle(padding: EdgeInsets.zero),
            prefixBuilder: (context, node) => const SizedBox.shrink(),
            contentBuilder: (context, node, renameField) => Text(node.data),
            logic: TreeViewConfig<String>(
              dragAndDrop: TreeDragAndDropConfig<String>(
                dropEdgeBandFraction: 0.3,
                dropPositionHysteresisPx: 0,
                canAcceptDrop: (draggedNode, targetNode, position) {
                  if (targetNode.id == 'node_beta') {
                    observedPosition = position;
                  }
                  return true;
                },
              ),
            ),
          ),
        ),
      );

      final Offset alphaCenter = tester.getCenter(find.text('Alpha'));
      final Finder betaDragTarget = find.ancestor(
        of: find.text('Beta'),
        matching: find.byWidgetPredicate(
          (Widget widget) => widget is DragTarget<TreeDragPayload<String>>,
        ),
      );
      final Rect betaRect = tester.getRect(betaDragTarget);
      final Offset betaTwentyPercent = Offset(
        betaRect.center.dx,
        betaRect.top + (betaRect.height * 0.2),
      );

      await tester.dragFrom(alphaCenter, betaTwentyPercent - alphaCenter);
      await tester.pumpAndSettle();

      expect(observedPosition, NodeDropPosition.above);
    });

    testWidgets('Drag and drop falls back to edge when inside is not allowed', (
      WidgetTester tester,
    ) async {
      final TreeController<FileSystemItem> controller = TreeController<FileSystemItem>(
        roots: <TreeNode<FileSystemItem>>[
          TreeNode<FileSystemItem>(id: 'file', data: FileItem('README.md')),
          TreeNode<FileSystemItem>(id: 'folder', data: FolderItem('folder')),
        ],
      );

      await tester.pumpWidget(
        createTestableWidget(
          SuperTreeView<FileSystemItem>(
            controller: controller,
            style: const TreeViewStyle(padding: EdgeInsets.zero),
            prefixBuilder: (BuildContext context, TreeNode<FileSystemItem> node) {
              return const SizedBox.shrink();
            },
            contentBuilder:
                (BuildContext context, TreeNode<FileSystemItem> node, Widget? renameField) {
                  return Text(node.data.name);
                },
            logic: TreeViewConfig<FileSystemItem>(
              dragAndDrop: TreeDragAndDropConfig<FileSystemItem>(
                canAcceptDrop:
                    (
                      TreeNode<FileSystemItem> draggedNode,
                      TreeNode<FileSystemItem> targetNode,
                      NodeDropPosition position,
                    ) => true,
              ),
            ),
          ),
        ),
      );

      final Finder folderDragTarget = find.ancestor(
        of: find.text('folder'),
        matching: find.byWidgetPredicate(
          (Widget widget) =>
              widget is DragTarget<TreeDragPayload<FileSystemItem>>,
        ),
      );
      final Rect folderRect = tester.getRect(folderDragTarget);
      final Offset folderCenter = folderRect.center;
      final Finder fileDragTarget = find.ancestor(
        of: find.text('README.md'),
        matching: find.byWidgetPredicate(
          (Widget widget) =>
              widget is DragTarget<TreeDragPayload<FileSystemItem>>,
        ),
      );
      final Rect fileRect = tester.getRect(fileDragTarget);
      final Offset fileMiddle = Offset(fileRect.center.dx, fileRect.center.dy);

      await tester.dragFrom(folderCenter, fileMiddle - folderCenter);
      await tester.pumpAndSettle();

      expect(controller.roots.length, 2);
      expect(controller.roots.first.id, 'file');
      expect(controller.roots.last.id, 'folder');
      expect(controller.roots.first.children, isEmpty);
    });

    testWidgets('Drag near bottom edge auto-scrolls viewport', (
      WidgetTester tester,
    ) async {
      final ScrollController scrollController = ScrollController();

      addTearDown(() {
        scrollController.dispose();
      });

      final TreeController<String> controller = TreeController<String>(
        roots: List<TreeNode<String>>.generate(
          30,
          (int index) => TreeNode<String>(id: 'node_$index', data: 'Node $index'),
        ),
      );

      addTearDown(() {
        controller.dispose();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 220,
              child: SuperTreeView<String>(
                controller: controller,
                scrollController: scrollController,
                prefixBuilder: (BuildContext context, TreeNode<String> node) {
                  return const SizedBox.shrink();
                },
                contentBuilder:
                    (BuildContext context, TreeNode<String> node, Widget? renameField) {
                      return Text(node.data);
                    },
                logic: const TreeViewConfig<String>(
                  dragAndDrop: TreeDragAndDropConfig(
                    enableAutoScroll: true,
                    autoScrollEdgeThresholdPx: 48,
                    autoScrollMaxStepPx: 18,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final Offset start = tester.getCenter(find.text('Node 0'));
      final Finder treeFinder = find.byType(SuperTreeView<String>);
      final Rect treeRect = tester.getRect(treeFinder);
      final Offset bottomEdgePoint = Offset(start.dx, treeRect.bottom - 2);

      final TestGesture gesture = await tester.startGesture(start);
      await tester.pump();
      await gesture.moveBy(const Offset(0, 30));
      await tester.pump(const Duration(milliseconds: 16));

      for (int i = 0; i < 12; i++) {
        await gesture.moveTo(bottomEdgePoint);
        await tester.pump(const Duration(milliseconds: 16));
      }

      await gesture.up();
      await tester.pumpAndSettle();

      expect(scrollController.offset, greaterThan(0));
    });

    testWidgets('Drag auto-scroll threshold tuning changes edge sensitivity', (
      WidgetTester tester,
    ) async {
      Future<double> runScenario(double thresholdPx) async {
        final ScrollController scenarioScrollController = ScrollController();
        final TreeController<String> scenarioController = TreeController<String>(
          roots: List<TreeNode<String>>.generate(
            30,
            (int index) => TreeNode<String>(id: 'n_$index', data: 'Item $index'),
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 220,
                child: SuperTreeView<String>(
                  controller: scenarioController,
                  scrollController: scenarioScrollController,
                  prefixBuilder: (BuildContext context, TreeNode<String> node) {
                    return const SizedBox.shrink();
                  },
                  contentBuilder:
                      (BuildContext context, TreeNode<String> node, Widget? renameField) {
                        return Text(node.data);
                      },
                  logic: TreeViewConfig<String>(
                    dragAndDrop: TreeDragAndDropConfig(
                      enableAutoScroll: true,
                      autoScrollEdgeThresholdPx: thresholdPx,
                      autoScrollMaxStepPx: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final Offset start = tester.getCenter(find.text('Item 0'));
        final Rect treeRect = tester.getRect(find.byType(SuperTreeView<String>));
        final Offset nearBottomButNotEdge = Offset(start.dx, treeRect.bottom - 20);

        final TestGesture gesture = await tester.startGesture(start);
        await tester.pump();
        await gesture.moveBy(const Offset(0, 30));
        await tester.pump(const Duration(milliseconds: 16));

        for (int i = 0; i < 10; i++) {
          await gesture.moveTo(nearBottomButNotEdge);
          await tester.pump(const Duration(milliseconds: 16));
        }

        await gesture.up();
        await tester.pumpAndSettle();

        final double offset = scenarioScrollController.offset;
        scenarioScrollController.dispose();
        scenarioController.dispose();
        return offset;
      }

      final double smallThresholdOffset = await runScenario(8);
      final double largeThresholdOffset = await runScenario(48);

      expect(smallThresholdOffset, equals(0));
      expect(largeThresholdOffset, greaterThan(0));
    });

    testWidgets(
      'Dragging selected node in multi-select mode uses batch payload',
      (WidgetTester tester) async {
        List<String> observedDraggedIds = <String>[];

        final TreeController<String> controller = TreeController<String>(
          roots: <TreeNode<String>>[
            TreeNode<String>(id: 'node_alpha', data: 'Alpha'),
            TreeNode<String>(id: 'node_beta', data: 'Beta'),
            TreeNode<String>(id: 'node_gamma', data: 'Gamma'),
          ],
        );

        await tester.pumpWidget(
          createTestableWidget(
            SuperTreeView<String>(
              controller: controller,
              prefixBuilder: (BuildContext context, TreeNode<String> node) {
                return const SizedBox.shrink();
              },
              contentBuilder:
                  (BuildContext context, TreeNode<String> node, Widget? renameField) {
                    return Text(node.data);
                  },
              logic: TreeViewConfig<String>(
                selectionMode: SelectionMode.multiple,
                dragAndDrop: TreeDragAndDropConfig<String>(
                  canAcceptDropMany:
                      (
                        List<TreeNode<String>> draggedNodes,
                        TreeNode<String> targetNode,
                        NodeDropPosition position,
                      ) {
                        observedDraggedIds = draggedNodes
                            .map((TreeNode<String> node) => node.id)
                            .toList(growable: false);
                        return true;
                      },
                ),
              ),
            ),
          ),
        );

        controller.setSelectedNodeId('node_alpha');
        controller.toggleSelection('node_beta');
        await tester.pumpAndSettle();

        final Offset alphaCenter = tester.getCenter(find.text('Alpha'));
        final Offset gammaCenter = tester.getCenter(find.text('Gamma'));

        await tester.dragFrom(alphaCenter, gammaCenter - alphaCenter);
        await tester.pumpAndSettle();

        expect(observedDraggedIds, <String>['node_alpha', 'node_beta']);
      },
    );

    testWidgets(
      'Dragging unselected node in multi-select mode stays single-node',
      (WidgetTester tester) async {
        String? observedDraggedId;
        bool batchCallbackTriggered = false;

        final TreeController<String> controller = TreeController<String>(
          roots: <TreeNode<String>>[
            TreeNode<String>(id: 'node_alpha', data: 'Alpha'),
            TreeNode<String>(id: 'node_beta', data: 'Beta'),
            TreeNode<String>(id: 'node_gamma', data: 'Gamma'),
          ],
        );

        await tester.pumpWidget(
          createTestableWidget(
            SuperTreeView<String>(
              controller: controller,
              prefixBuilder: (BuildContext context, TreeNode<String> node) {
                return const SizedBox.shrink();
              },
              contentBuilder:
                  (BuildContext context, TreeNode<String> node, Widget? renameField) {
                    return Text(node.data);
                  },
              logic: TreeViewConfig<String>(
                selectionMode: SelectionMode.multiple,
                dragAndDrop: TreeDragAndDropConfig<String>(
                  canAcceptDrop: (
                    TreeNode<String> draggedNode,
                    TreeNode<String> targetNode,
                    NodeDropPosition position,
                  ) {
                    observedDraggedId = draggedNode.id;
                    return true;
                  },
                  canAcceptDropMany:
                      (
                        List<TreeNode<String>> draggedNodes,
                        TreeNode<String> targetNode,
                        NodeDropPosition position,
                      ) {
                        batchCallbackTriggered = true;
                        return true;
                      },
                ),
              ),
            ),
          ),
        );

        controller.setSelectedNodeId('node_alpha');
        controller.toggleSelection('node_beta');
        await tester.pumpAndSettle();

        final Offset gammaCenter = tester.getCenter(find.text('Gamma'));
        final Offset betaCenter = tester.getCenter(find.text('Beta'));

        await tester.dragFrom(gammaCenter, betaCenter - gammaCenter);
        await tester.pumpAndSettle();

        expect(observedDraggedId, 'node_gamma');
        expect(batchCallbackTriggered, isFalse);
      },
    );

    testWidgets('Keyboard interactions work after tapping tree content', (
      WidgetTester tester,
    ) async {
      final TreeController<String> controller = TreeController<String>(
        roots: <TreeNode<String>>[
          TreeNode<String>(id: 'root_1', data: 'Root 1'),
          TreeNode<String>(id: 'root_2', data: 'Root 2'),
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

    testWidgets('Tree nodes expose accessibility semantics metadata', (
      WidgetTester tester,
    ) async {
      final TreeController<String> controller = TreeController<String>(
        roots: <TreeNode<String>>[
          TreeNode<String>(
            id: 'root_1',
            data: 'Root 1',
            children: <TreeNode<String>>[
              TreeNode<String>(id: 'child_1', data: 'Child 1'),
            ],
          ),
        ],
      );

      addTearDown(() {
        controller.dispose();
      });

      final SemanticsHandle semanticsHandle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          createTestableWidget(
            SuperTreeView<String>(
              controller: controller,
              prefixBuilder: (BuildContext context, TreeNode<String> node) {
                return const Icon(Icons.chevron_right);
              },
              contentBuilder:
                  (BuildContext context, TreeNode<String> node, Widget? renameField) {
                    return Text(node.data);
                  },
            ),
          ),
        );

        final Finder semanticsFinder = find.byKey(const Key('tree_node_semantics_root_1'));
        final SemanticsData initialData = tester.getSemantics(semanticsFinder).getSemanticsData();
        expect(initialData.label, contains('Root 1, Depth 1, Collapsed, Not selected'));
        expect(initialData.flagsCollection.hasExpandedState, isTrue);
        expect(initialData.flagsCollection.isExpanded, isFalse);
        expect(initialData.flagsCollection.hasSelectedState, isTrue);
        expect(initialData.flagsCollection.isSelected, isFalse);

        await tester.tap(find.text('Root 1'));
        await tester.pumpAndSettle();

        final SemanticsData selectedData = tester.getSemantics(semanticsFinder).getSemanticsData();
        expect(selectedData.label, contains('Root 1, Depth 1, Expanded, Selected'));
        expect(selectedData.flagsCollection.hasExpandedState, isTrue);
        expect(selectedData.flagsCollection.isExpanded, isTrue);
        expect(selectedData.flagsCollection.hasSelectedState, isTrue);
        expect(selectedData.flagsCollection.isSelected, isTrue);
      } finally {
        semanticsHandle.dispose();
      }
    });

    testWidgets('Keyboard navigation updates accessibility selected semantics', (
      WidgetTester tester,
    ) async {
      final TreeController<String> controller = TreeController<String>(
        roots: <TreeNode<String>>[
          TreeNode<String>(id: 'root_1', data: 'Root 1'),
          TreeNode<String>(id: 'root_2', data: 'Root 2'),
        ],
      );

      addTearDown(() {
        controller.dispose();
      });

      final SemanticsHandle semanticsHandle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          createTestableWidget(
            SuperTreeView<String>(
              controller: controller,
              prefixBuilder: (BuildContext context, TreeNode<String> node) {
                return const Icon(Icons.chevron_right);
              },
              contentBuilder:
                  (BuildContext context, TreeNode<String> node, Widget? renameField) {
                    return Text(node.data);
                  },
            ),
          ),
        );

        final Finder rootOneSemanticsFinder = find.byKey(
          const Key('tree_node_semantics_root_1'),
        );
        final Finder rootTwoSemanticsFinder = find.byKey(
          const Key('tree_node_semantics_root_2'),
        );

        await tester.tap(find.text('Root 1'));
        await tester.pumpAndSettle();

        final SemanticsData rootOneSelectedData = tester
            .getSemantics(rootOneSemanticsFinder)
            .getSemanticsData();
        expect(rootOneSelectedData.label, contains('Root 1, Depth 1, Leaf, Selected'));
        expect(rootOneSelectedData.flagsCollection.hasExpandedState, isFalse);
        expect(rootOneSelectedData.flagsCollection.hasSelectedState, isTrue);
        expect(rootOneSelectedData.flagsCollection.isSelected, isTrue);

        await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();

        final SemanticsData rootOneAfterMoveData = tester
            .getSemantics(rootOneSemanticsFinder)
            .getSemanticsData();
        final SemanticsData rootTwoAfterMoveData = tester
            .getSemantics(rootTwoSemanticsFinder)
            .getSemanticsData();

        expect(rootOneAfterMoveData.label, contains('Root 1, Depth 1, Leaf, Not selected'));
        expect(rootOneAfterMoveData.flagsCollection.hasExpandedState, isFalse);
        expect(rootOneAfterMoveData.flagsCollection.hasSelectedState, isTrue);
        expect(rootOneAfterMoveData.flagsCollection.isSelected, isFalse);
        expect(rootTwoAfterMoveData.label, contains('Root 2, Depth 1, Leaf, Selected'));
        expect(rootTwoAfterMoveData.flagsCollection.hasExpandedState, isFalse);
        expect(rootTwoAfterMoveData.flagsCollection.hasSelectedState, isTrue);
        expect(rootTwoAfterMoveData.flagsCollection.isSelected, isTrue);
      } finally {
        semanticsHandle.dispose();
      }
    });

    testWidgets('Arrow right expands selected node and arrow left collapses it', (
      WidgetTester tester,
    ) async {
      final TreeController<String> controller = TreeController<String>(
        roots: <TreeNode<String>>[
          TreeNode<String>(
            id: 'root_1',
            data: 'Root 1',
            children: <TreeNode<String>>[TreeNode<String>(id: 'child_1', data: 'Child 1')],
          ),
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

      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();

      expect(find.text('Child 1'), findsOneWidget);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();

      expect(find.text('Child 1'), findsNothing);
    });

    testWidgets('Enter starts renaming when naming strategy is enabled', (
      WidgetTester tester,
    ) async {
      final TreeController<String> controller = TreeController<String>(
        roots: <TreeNode<String>>[TreeNode<String>(id: 'root_1', data: 'Root 1')],
      );

      addTearDown(() {
        controller.dispose();
      });

      await tester.pumpWidget(
        createTestableWidget(
          SuperTreeView<String>(
            controller: controller,
            logic: const TreeViewConfig<String>(namingStrategy: TreeNamingStrategy.contextMenu),
            prefixBuilder: (BuildContext context, TreeNode<String> node) {
              return const Icon(Icons.chevron_right);
            },
            contentBuilder: (BuildContext context, TreeNode<String> node, Widget? renameField) {
              return renameField ?? Text(node.data);
            },
          ),
        ),
      );

      await tester.tap(find.text('Root 1'));
      await tester.pumpAndSettle();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(controller.renamingNodeId, 'root_1');
    });

    testWidgets('Arrow keys do not navigate tree while renaming text field', (
      WidgetTester tester,
    ) async {
      final TreeController<String> controller = TreeController<String>(
        roots: <TreeNode<String>>[
          TreeNode<String>(id: 'root_1', data: 'Root 1'),
          TreeNode<String>(id: 'root_2', data: 'Root 2'),
        ],
      );

      addTearDown(() {
        controller.dispose();
      });

      await tester.pumpWidget(
        createTestableWidget(
          SuperTreeView<String>(
            controller: controller,
            logic: const TreeViewConfig<String>(namingStrategy: TreeNamingStrategy.click),
            prefixBuilder: (BuildContext context, TreeNode<String> node) {
              return const Icon(Icons.chevron_right);
            },
            contentBuilder: (BuildContext context, TreeNode<String> node, Widget? renameField) {
              return renameField ?? Text(node.data);
            },
          ),
        ),
      );

      await tester.tap(find.text('Root 1'));
      await tester.pumpAndSettle();
      expect(controller.selectedNodeId, 'root_1');

      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      expect(controller.renamingNodeId, 'root_1');

      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      expect(controller.selectedNodeId, 'root_1');
      expect(controller.renamingNodeId, 'root_1');
    });

    testWidgets('Shift+Arrow extends selection range in multiple selection mode', (
      WidgetTester tester,
    ) async {
      final TreeController<String> controller = TreeController<String>(
        roots: <TreeNode<String>>[
          TreeNode<String>(id: 'root_1', data: 'Root 1'),
          TreeNode<String>(id: 'root_2', data: 'Root 2'),
          TreeNode<String>(id: 'root_3', data: 'Root 3'),
        ],
      );

      addTearDown(() {
        controller.dispose();
      });

      await tester.pumpWidget(
        createTestableWidget(
          SuperTreeView<String>(
            controller: controller,
            logic: const TreeViewConfig<String>(selectionMode: SelectionMode.multiple),
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

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();

      expect(controller.selectedNodeIds, <String>{'root_1', 'root_2'});
    });

    testWidgets('FileSystemSuperTree uses icon provider in default prefix builder', (
      WidgetTester tester,
    ) async {
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

    testWidgets('FileSystemSuperTree keeps custom prefixBuilder override precedence', (
      WidgetTester tester,
    ) async {
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

    testWidgets('SuperTreeThemes presets expose usable style and icon providers', (
      WidgetTester tester,
    ) async {
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

    testWidgets('TreeHighlightedLabel renders RichText when there are matched indices', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestableWidget(
          const TreeHighlightedLabel(text: 'README.md', matchedIndices: <int>[0, 1, 2, 3]),
        ),
      );

      expect(find.byType(RichText), findsOneWidget);
      expect(find.text('README.md'), findsNothing);
    });

    testWidgets(
      'TreeHighlightedLabel keeps non-highlight style color readable when custom style omits color',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            home: const Scaffold(
              body: TreeHighlightedLabel(
                text: 'Todo Node',
                matchedIndices: <int>[0, 1, 2],
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        );

        final RichText richText = tester.widget<RichText>(find.byType(RichText));
        final TextSpan rootSpan = richText.text as TextSpan;
        final List<InlineSpan> children = rootSpan.children ?? const <InlineSpan>[];
        final TextSpan nonHighlight = children.whereType<TextSpan>().last;

        expect(nonHighlight.style?.color, isNotNull);
      },
    );

    testWidgets(
      'TodoListSuperTree keeps non-highlight text readable during search highlighting',
      (WidgetTester tester) async {
        final ThemeData theme = ThemeData.light();
        final TreeController<TodoItem> controller = TreeController<TodoItem>(
          roots: <TreeNode<TodoItem>>[
            TreeNode<TodoItem>(
              id: 'todo_1',
              data: TodoItem('Todo Node'),
            ),
          ],
        );

        addTearDown(() {
          controller.dispose();
        });

        controller.applyFilter(
          predicate: (TreeNode<TodoItem> node) => true,
          matchedIndicesByNodeId: const <String, List<int>>{
            'todo_1': <int>[0, 1],
          },
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              body: TodoListSuperTree(
                controller: controller,
                style: const TreeViewStyle(
                  textStyle: TextStyle(fontSize: 14),
                ),
              ),
            ),
          ),
        );

        final RichText richText = tester.widget<RichText>(find.byType(RichText));
        final TextSpan rootSpan = richText.text as TextSpan;
        final List<TextSpan> spans = rootSpan.children!.whereType<TextSpan>().toList();
        final TextSpan nonHighlight = spans.last;

        expect(nonHighlight.style?.color, theme.colorScheme.onSurface);
      },
    );

    testWidgets('TodoListSuperTree applies tri-state parent checkbox synchronization', (
      WidgetTester tester,
    ) async {
      final TreeController<TodoItem> controller = TreeController<TodoItem>(
        roots: <TreeNode<TodoItem>>[
          TreeNode<TodoItem>(
            id: 'parent',
            data: TodoItem('Parent Task'),
            isExpanded: true,
            children: <TreeNode<TodoItem>>[
              TreeNode<TodoItem>(id: 'child_a', data: TodoItem('Child A')),
              TreeNode<TodoItem>(id: 'child_b', data: TodoItem('Child B')),
            ],
          ),
        ],
      );

      addTearDown(() {
        controller.dispose();
      });

      await tester.pumpWidget(createTestableWidget(TodoListSuperTree(controller: controller)));

      final Finder checkboxes = find.byType(Checkbox);
      await tester.tap(checkboxes.at(1));
      await tester.pumpAndSettle();

      final Checkbox parentAfterPartial = tester.widget<Checkbox>(checkboxes.at(0));
      final Checkbox childAAfterToggle = tester.widget<Checkbox>(checkboxes.at(1));
      final Checkbox childBAfterToggle = tester.widget<Checkbox>(checkboxes.at(2));

      expect(parentAfterPartial.value, isNull);
      expect(childAAfterToggle.value, isTrue);
      expect(childBAfterToggle.value, isFalse);

      await tester.tap(checkboxes.at(0));
      await tester.pumpAndSettle();

      final Checkbox parentAfterParentTap = tester.widget<Checkbox>(checkboxes.at(0));
      final Checkbox childAAfterParentTap = tester.widget<Checkbox>(checkboxes.at(1));
      final Checkbox childBAfterParentTap = tester.widget<Checkbox>(checkboxes.at(2));

      expect(parentAfterParentTap.value, isTrue);
      expect(childAAfterParentTap.value, isTrue);
      expect(childBAfterParentTap.value, isTrue);
    });

    testWidgets('Lazy loading shows default expansion spinner while loading', (
      WidgetTester tester,
    ) async {
      final Completer<List<TreeNode<String>>> completer = Completer<List<TreeNode<String>>>();

      final TreeController<String> controller = TreeController<String>(
        roots: <TreeNode<String>>[
          TreeNode<String>(id: 'lazy_root', data: 'Lazy Root', canLoadChildren: true),
        ],
        loadChildren: (TreeNode<String> node) => completer.future,
      );

      await tester.pumpWidget(
        createTestableWidget(
          SuperTreeView<String>(
            controller: controller,
            prefixBuilder: (BuildContext context, TreeNode<String> node) =>
                const Icon(Icons.chevron_right),
            contentBuilder: (BuildContext context, TreeNode<String> node, Widget? renameField) {
              return Text(node.data);
            },
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('expansion_caret_lazy_root')));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete(<TreeNode<String>>[
        TreeNode<String>(id: 'lazy_child', data: 'Lazy Child'),
      ]);
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Lazy Child'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('Lazy loading allows custom loadingExpansionBuilder', (
      WidgetTester tester,
    ) async {
      final Completer<List<TreeNode<String>>> completer = Completer<List<TreeNode<String>>>();

      final TreeController<String> controller = TreeController<String>(
        roots: <TreeNode<String>>[
          TreeNode<String>(id: 'lazy_root_custom', data: 'Lazy Root', canLoadChildren: true),
        ],
        loadChildren: (TreeNode<String> node) => completer.future,
      );

      await tester.pumpWidget(
        createTestableWidget(
          SuperTreeView<String>(
            controller: controller,
            loadingExpansionBuilder: (BuildContext context, TreeNode<String> node) {
              return SizedBox(
                key: Key('custom_loading_${node.id}'),
                width: 10,
                height: 10,
                child: const DecoratedBox(
                  decoration: BoxDecoration(color: Colors.orange),
                ),
              );
            },
            prefixBuilder: (BuildContext context, TreeNode<String> node) =>
                const Icon(Icons.chevron_right),
            contentBuilder: (BuildContext context, TreeNode<String> node, Widget? renameField) {
              return Text(node.data);
            },
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('expansion_caret_lazy_root_custom')));
      await tester.pump();

      expect(find.byKey(const Key('custom_loading_lazy_root_custom')), findsOneWidget);

      completer.complete(<TreeNode<String>>[
        TreeNode<String>(id: 'lazy_child_custom', data: 'Lazy Child'),
      ]);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('custom_loading_lazy_root_custom')), findsNothing);
      expect(find.text('Lazy Child'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('Node row shows warning icon when controller reports integrity issue', (
      WidgetTester tester,
    ) async {
      final TreeNode<String> root = TreeNode<String>(id: 'root', data: 'Root');
      final TreeController<String> controller = TreeController<String>(
        roots: <TreeNode<String>>[root],
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

      controller.addChild(root, root);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
  });
}
