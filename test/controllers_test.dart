import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:super_tree/src/controllers/tree_search_controller.dart';
import 'package:super_tree/src/models/tree_node.dart';
import 'package:super_tree/src/models/super_tree_data.dart';
import 'package:super_tree/src/controllers/tree_controller.dart';
import 'package:super_tree/src/models/tree_filtering.dart';

void main() {
  group('TreeController Traversal & DFS Tests', () {
    late TreeController<String> controller;

    setUp(() {
      controller = TreeController<String>(
        roots: [
          TreeNode(
            id: 'root_1',
            data: 'Root 1',
            children: [
              TreeNode(id: 'child_1_1', data: 'Child 1.1'),
              TreeNode(
                id: 'child_1_2',
                data: 'Child 1.2',
                children: [TreeNode(id: 'child_1_2_1', data: 'Child 1.2.1')],
              ),
            ],
          ),
          TreeNode(id: 'root_2', data: 'Root 2'),
        ],
      );
    });

    test('Initial flat list should only contain roots if not expanded', () {
      final visible = controller.flatVisibleNodes;
      expect(visible.length, 2);
      expect(visible[0].id, 'root_1');
      expect(visible[1].id, 'root_2');
    });

    test('Expanding a root includes its immediate children', () {
      final root1 = controller.roots[0];
      controller.expandNode(root1);
      final visible = controller.flatVisibleNodes;

      expect(visible.length, 4); // root1, child1.1, child1.2, root2
      expect(visible[0].id, 'root_1');
      expect(visible[1].id, 'child_1_1');
      expect(visible[2].id, 'child_1_2');
      expect(visible[3].id, 'root_2');
    });

    test('Expanding nested children works recursively in DFS order', () {
      final root1 = controller.roots[0];
      final child1_2 = root1.children[1];

      controller.expandNode(root1);
      controller.expandNode(child1_2);

      final visible = controller.flatVisibleNodes;
      expect(visible.length, 5);
      expect(visible[0].id, 'root_1');
      expect(visible[1].id, 'child_1_1');
      expect(visible[2].id, 'child_1_2');
      expect(visible[3].id, 'child_1_2_1'); // Nested child
      expect(visible[4].id, 'root_2');
    });

    test(
      'Collapsing hides children but preserves their expansion state internally',
      () {
        final root1 = controller.roots[0];
        final child1_2 = root1.children[1];

        controller.expandAll();
        expect(controller.flatVisibleNodes.length, 5);

        controller.collapseNode(root1);
        expect(controller.flatVisibleNodes.length, 2); // Hidden
        expect(child1_2.isExpanded, true); // Still expanded internally
      },
    );

    test('findNodeById correctly locates nodes', () {
      final found = controller.findNodeById('child_1_2_1');
      expect(found, isNotNull);
      expect(found?.data, 'Child 1.2.1');
    });

    test('Depth calculation works properly via parent references', () {
      final root = controller.roots[0];
      final child1_2 = root.children[1];
      final child1_2_1 = child1_2.children[0];

      expect(root.depth, 0);
      expect(child1_2.depth, 1);
      expect(child1_2_1.depth, 2);
    });
  });

  group('TreeController Sorting Tests', () {
    test('Setting sortComparator sorts existing roots and children', () {
      final controller = TreeController<String>(
        roots: [
          TreeNode(id: 'b', data: 'B'),
          TreeNode(
            id: 'a',
            data: 'A',
            children: [
              TreeNode(id: 'a2', data: 'a2'),
              TreeNode(id: 'a1', data: 'a1'),
            ],
          ),
          TreeNode(id: 'c', data: 'C'),
        ],
      );

      // Not sorted
      expect(controller.roots[0].id, 'b');
      expect(controller.roots[1].id, 'a');
      expect(controller.roots[1].children[0].id, 'a2');

      // Set comparator
      controller.sortComparator = (a, b) => a.data.compareTo(b.data);

      // Sorted recursively
      expect(controller.roots[0].id, 'a');
      expect(controller.roots[1].id, 'b');
      expect(controller.roots[2].id, 'c');
      expect(controller.roots[0].children[0].id, 'a1');
      expect(controller.roots[0].children[1].id, 'a2');
    });

    test('addRoot applies sorting if comparator is set', () {
      final controller = TreeController<String>(
        sortComparator: (a, b) => a.data.compareTo(b.data),
      );

      controller.addRoot(TreeNode(id: 'c', data: 'c'));
      controller.addRoot(TreeNode(id: 'a', data: 'a'));
      controller.addRoot(TreeNode(id: 'b', data: 'b'));

      expect(controller.roots.map((r) => r.data).toList(), ['a', 'b', 'c']);
    });

    test('addChild applies sorting if comparator is set', () {
      final controller = TreeController<String>(
        roots: [TreeNode(id: 'root', data: 'root')],
        sortComparator: (a, b) => a.data.compareTo(b.data),
      );

      final root = controller.roots[0];
      controller.addChild(root, TreeNode(id: 'c', data: 'c'));
      controller.addChild(root, TreeNode(id: 'a', data: 'a'));
      controller.addChild(root, TreeNode(id: 'b', data: 'b'));

      expect(root.children.map((c) => c.data).toList(), ['a', 'b', 'c']);
    });
  });

  group('TreeController Drag and Drop Ancestry Check', () {
    test('isDescendantOf correctly identifies descendants', () {
      final controller = TreeController<String>(
        roots: [
          TreeNode(
            id: 'root',
            data: 'root',
            children: [
              TreeNode(
                id: 'child',
                data: 'child',
                children: [TreeNode(id: 'grandchild', data: 'grandchild')],
              ),
            ],
          ),
        ],
      );

      expect(controller.isDescendantOf('child', 'root'), true);
      expect(controller.isDescendantOf('grandchild', 'root'), true);
      expect(controller.isDescendantOf('grandchild', 'child'), true);
      expect(controller.isDescendantOf('root', 'child'), false);
      expect(controller.isDescendantOf('child', 'grandchild'), false);
    });

    test('moveNode prevents circular references', () {
      final root = TreeNode(id: 'root', data: 'root');
      final child = TreeNode(id: 'child', data: 'child');
      final controller = TreeController<String>(roots: [root]);
      controller.addChild(root, child);

      // Attempt to move root into child
      controller.moveNode(
        dragged: root,
        target: child,
        insertBefore: false,
        nestInside: true,
      );

      // Root should still be a root, child should still be its child
      expect(controller.roots.length, 1);
      expect(controller.roots[0].id, 'root');
      expect(controller.roots[0].children[0].id, 'child');
      expect(child.parent?.id, 'root');
    });

    test('moveNode does not delete node if nestInside is invalid', () {
      final root_1 = TreeNode(
        id: 'root_1',
        data: TestData(canHaveChildren: false),
      );
      final root_2 = TreeNode(
        id: 'root_2',
        data: TestData(canHaveChildren: true),
      );
      final controller = TreeController<TestData>(roots: [root_1, root_2]);

      expect(controller.roots.length, 2);

      // Attempt to move root_2 into root_1 (which cannot have children)
      controller.moveNode(
        dragged: root_2,
        target: root_1,
        insertBefore: false,
        nestInside: true,
      );

      // root_2 should NOT be deleted, it should still be a root
      expect(controller.roots.length, 2);
      expect(controller.roots[1].id, 'root_2');
      expect(controller.findNodeById('root_2'), isNotNull);
    });

    test('addChild prevents circular references', () {
      final TreeNode<String> root = TreeNode<String>(id: 'root', data: 'root');
      final TreeNode<String> child = TreeNode<String>(
        id: 'child',
        data: 'child',
      );
      final TreeNode<String> grandchild = TreeNode<String>(
        id: 'grandchild',
        data: 'grandchild',
      );
      final TreeController<String> controller = TreeController<String>(
        roots: <TreeNode<String>>[root],
      );

      controller.addChild(root, child);
      controller.addChild(child, grandchild);

      controller.addChild(grandchild, root);

      expect(controller.findNodeById('root')?.isRoot, isTrue);
      expect(controller.findNodeById('child')?.parent?.id, 'root');
      expect(controller.findNodeById('grandchild')?.parent?.id, 'child');
      expect(
        controller.lastIntegrityIssue?.type,
        TreeIntegrityIssueType.circularReference,
      );
    });
  });

  group('TreeController Integrity Validation', () {
    test(
      'constructor ignores duplicated root IDs without mutating existing IDs',
      () {
        final TreeController<String> controller = TreeController<String>(
          roots: <TreeNode<String>>[
            TreeNode<String>(id: 'dup', data: 'first'),
            TreeNode<String>(id: 'dup', data: 'second'),
          ],
        );

        expect(controller.roots.length, 1);
        expect(controller.roots.first.id, 'dup');
        expect(
          controller.lastIntegrityIssue?.type,
          TreeIntegrityIssueType.duplicateId,
        );
      },
    );

    test('addRoot rejects duplicate IDs and keeps previous tree stable', () {
      final TreeController<String> controller = TreeController<String>(
        roots: <TreeNode<String>>[TreeNode<String>(id: 'root_a', data: 'A')],
      );

      controller.addRoot(TreeNode<String>(id: 'root_a', data: 'A2'));

      expect(controller.roots.length, 1);
      expect(controller.findNodeById('root_a')?.data, 'A');
      expect(
        controller.lastIntegrityIssue?.type,
        TreeIntegrityIssueType.duplicateId,
      );
    });

    test('addChild rejects duplicate IDs and records issue on parent node', () {
      final TreeNode<String> root = TreeNode<String>(id: 'root', data: 'root');
      final TreeController<String> controller = TreeController<String>(
        roots: <TreeNode<String>>[root],
      );

      controller.addChild(root, TreeNode<String>(id: 'node_1', data: 'one'));
      controller.addChild(
        root,
        TreeNode<String>(id: 'node_1', data: 'duplicate'),
      );

      expect(root.children.length, 1);
      expect(root.children.first.data, 'one');
      expect(
        controller.lastIntegrityIssue?.type,
        TreeIntegrityIssueType.duplicateId,
      );
      expect(controller.getIntegrityIssueForNode(root.id), isNotNull);
    });
  });

  group('TreeController Filtering and Search', () {
    test('applyFilter predicate keeps ancestor context', () {
      final controller = TreeController<String>(
        roots: [
          TreeNode(
            id: 'root',
            data: 'Workspace',
            children: [
              TreeNode(id: 'a', data: 'README.md'),
              TreeNode(id: 'b', data: 'lib'),
            ],
          ),
        ],
      );

      controller.applyFilter(
        predicate: (TreeNode<String> node) => node.id == 'a',
      );

      expect(controller.flatVisibleNodes.map((node) => node.id).toList(), [
        'root',
        'a',
      ]);
      expect(controller.hasMatchedIndices('a'), isFalse);
    });

    test(
      'TreeSearchController supports custom matcher and restores expansion on clear',
      () {
        final TreeNode<String> docs = TreeNode<String>(
          id: 'docs',
          data: 'docs',
          isExpanded: false,
          children: <TreeNode<String>>[
            TreeNode<String>(id: 'guide', data: 'guide.md'),
            TreeNode<String>(id: 'api', data: 'api.md'),
          ],
        );

        final controller = TreeController<String>(
          roots: <TreeNode<String>>[docs],
        );
        final searchController = TreeSearchController<String>(
          treeController: controller,
          labelProvider: (String value) => value,
          expansionBehavior:
              TreeSearchExpansionBehavior.expandMatchesAndAncestors,
          searchMatcher:
              (String query, TreeNode<String> node, String candidate) {
                if (query == 'md' && candidate.endsWith('.md')) {
                  final int start = candidate.length - 2;
                  return TreeFuzzyMatchResult(
                    score: 0,
                    matchedIndices: <int>[start, start + 1],
                  );
                }
                return defaultTreeFuzzyMatcher(query, candidate);
              },
        );

        expect(docs.isExpanded, isFalse);

        searchController.search('md');

        expect(controller.flatVisibleNodes.map((node) => node.id).toList(), [
          'docs',
          'guide',
          'api',
        ]);
        expect(docs.isExpanded, isTrue);
        expect(controller.getMatchedIndices('guide').isNotEmpty, isTrue);

        searchController.clearSearch();

        expect(controller.hasActiveFilter, isFalse);
        expect(docs.isExpanded, isFalse);
      },
    );
  });

  group('TreeController State Persistence', () {
    TreeController<String> buildController() {
      return TreeController<String>(
        roots: <TreeNode<String>>[
          TreeNode<String>(
            id: 'root_1',
            data: 'Root 1',
            children: <TreeNode<String>>[
              TreeNode<String>(id: 'child_1_1', data: 'Child 1.1'),
              TreeNode<String>(id: 'child_1_2', data: 'Child 1.2'),
            ],
          ),
          TreeNode<String>(id: 'root_2', data: 'Root 2'),
        ],
      );
    }

    test('toJson/fromJson roundtrip restores expanded and selected state', () {
      final TreeController<String> source = buildController();
      final TreeNode<String> root1 = source.findNodeById('root_1')!;

      source.expandNode(root1);
      source.setSelectedNodeId('root_1');
      source.toggleSelection('root_2');

      final Map<String, Object?> payload = source.toJson();

      final TreeController<String> restored = buildController();
      restored.fromJson(payload);

      expect(restored.findNodeById('root_1')?.isExpanded, isTrue);
      expect(restored.findNodeById('root_2')?.isExpanded, isFalse);
      expect(restored.selectedNodeIds, <String>{'root_1', 'root_2'});
      expect(restored.selectedNodeId, 'root_2');
    });

    test('fromJson ignores unknown and malformed values', () {
      final TreeController<String> controller = buildController();

      controller.fromJson(<String, Object?>{
        'expandedNodeIds': <Object?>['root_1', 7, null, 'unknown'],
        'selectedNodeIds': <Object?>['child_1_1', false, 'missing'],
        'anchorNodeId': 123,
      });

      expect(controller.findNodeById('root_1')?.isExpanded, isTrue);
      expect(controller.findNodeById('root_2')?.isExpanded, isFalse);
      expect(controller.selectedNodeIds, <String>{'child_1_1'});
      expect(controller.selectedNodeId, 'child_1_1');
    });

    test('fromJson with empty payload clears previous state', () {
      final TreeController<String> controller = buildController();
      controller.expandAll();
      controller.setSelectedNodeId('root_1');

      controller.fromJson(const <String, Object?>{});

      expect(controller.findNodeById('root_1')?.isExpanded, isFalse);
      expect(controller.findNodeById('child_1_1')?.isExpanded, isFalse);
      expect(controller.selectedNodeIds, isEmpty);
      expect(controller.selectedNodeId, isNull);
    });

    test('fromJson can be applied repeatedly without stale state', () {
      final TreeController<String> controller = buildController();

      controller.fromJson(<String, Object?>{
        'expandedNodeIds': <String>['root_1'],
        'selectedNodeIds': <String>['root_1'],
        'anchorNodeId': 'root_1',
      });

      expect(controller.findNodeById('root_1')?.isExpanded, isTrue);
      expect(controller.selectedNodeIds, <String>{'root_1'});

      controller.fromJson(<String, Object?>{
        'expandedNodeIds': <String>['root_2'],
        'selectedNodeIds': <String>['root_2'],
        'anchorNodeId': 'root_2',
      });

      expect(controller.findNodeById('root_1')?.isExpanded, isFalse);
      expect(controller.findNodeById('root_2')?.isExpanded, isTrue);
      expect(controller.selectedNodeIds, <String>{'root_2'});
      expect(controller.selectedNodeId, 'root_2');
    });
  });

  group('TreeController Lazy Loading', () {
    test('toggleNodeExpansion lazy-loads children and expands node', () async {
      int loadCalls = 0;
      final TreeNode<String> root = TreeNode<String>(
        id: 'lazy_root',
        data: 'Lazy Root',
        canLoadChildren: true,
      );

      final TreeController<String> controller = TreeController<String>(
        roots: <TreeNode<String>>[root],
        loadChildren: (TreeNode<String> node) async {
          loadCalls++;
          return <TreeNode<String>>[
            TreeNode<String>(id: 'lazy_child', data: 'Lazy Child'),
          ];
        },
      );

      await controller.toggleNodeExpansion(root);

      expect(loadCalls, 1);
      expect(root.isExpanded, isTrue);
      expect(root.children.length, 1);
      expect(controller.findNodeById('lazy_child'), isNotNull);
      expect(
        controller.flatVisibleNodes.map((TreeNode<String> n) => n.id).toList(),
        <String>['lazy_root', 'lazy_child'],
      );
    });

    test('ensureNodeChildrenLoaded deduplicates in-flight requests', () async {
      int loadCalls = 0;
      final Completer<List<TreeNode<String>>> completer =
          Completer<List<TreeNode<String>>>();
      final TreeNode<String> root = TreeNode<String>(
        id: 'lazy_root',
        data: 'Lazy Root',
        canLoadChildren: true,
      );

      final TreeController<String> controller = TreeController<String>(
        roots: <TreeNode<String>>[root],
        loadChildren: (TreeNode<String> node) {
          loadCalls++;
          return completer.future;
        },
      );

      final Future<void> first = controller.ensureNodeChildrenLoaded(root);
      final Future<void> second = controller.ensureNodeChildrenLoaded(root);

      expect(controller.isNodeLoading(root.id), isTrue);
      expect(loadCalls, 1);

      completer.complete(<TreeNode<String>>[
        TreeNode<String>(id: 'lazy_child', data: 'Lazy Child'),
      ]);
      await Future.wait(<Future<void>>[first, second]);

      expect(loadCalls, 1);
      expect(controller.isNodeLoading(root.id), isFalse);
      expect(root.children.length, 1);
    });

    test('toggleNodeExpansion captures load errors and allows retry', () async {
      int loadCalls = 0;
      final TreeNode<String> root = TreeNode<String>(
        id: 'lazy_root',
        data: 'Lazy Root',
        canLoadChildren: true,
      );

      final TreeController<String> controller = TreeController<String>(
        roots: <TreeNode<String>>[root],
        loadChildren: (TreeNode<String> node) async {
          loadCalls++;
          if (loadCalls == 1) {
            throw StateError('load failed');
          }
          return <TreeNode<String>>[
            TreeNode<String>(id: 'lazy_child', data: 'Lazy Child'),
          ];
        },
      );

      await controller.toggleNodeExpansion(root);

      expect(controller.hasNodeLoadError(root.id), isTrue);
      expect(root.isExpanded, isFalse);
      expect(root.children, isEmpty);

      await controller.toggleNodeExpansion(root);

      expect(loadCalls, 2);
      expect(controller.hasNodeLoadError(root.id), isFalse);
      expect(root.isExpanded, isTrue);
      expect(root.children.length, 1);
    });

    test(
      'toggleNodeExpansion handles empty lazy result without expanding',
      () async {
        final TreeNode<String> root = TreeNode<String>(
          id: 'lazy_root',
          data: 'Lazy Root',
          canLoadChildren: true,
        );

        final TreeController<String> controller = TreeController<String>(
          roots: <TreeNode<String>>[root],
          loadChildren: (TreeNode<String> node) async => <TreeNode<String>>[],
        );

        await controller.toggleNodeExpansion(root);

        expect(root.isExpanded, isFalse);
        expect(root.children, isEmpty);
        expect(controller.canNodeLoadChildren(root), isFalse);
        expect(controller.hasNodeLoadError(root.id), isFalse);
      },
    );
  });
}

class TestData with SuperTreeData {
  @override
  final bool canHaveChildren;
  TestData({required this.canHaveChildren});
}
