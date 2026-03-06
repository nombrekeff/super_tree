import 'package:flutter_test/flutter_test.dart';
import 'package:super_tree/src/models/tree_node.dart';
import 'package:super_tree/src/controllers/tree_controller.dart';

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
                children: [
                  TreeNode(id: 'child_1_2_1', data: 'Child 1.2.1'),
                ],
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

    test('Collapsing hides children but preserves their expansion state internally', () {
      final root1 = controller.roots[0];
      final child1_2 = root1.children[1];
      
      controller.expandAll();
      expect(controller.flatVisibleNodes.length, 5);

      controller.collapseNode(root1);
      expect(controller.flatVisibleNodes.length, 2); // Hidden
      expect(child1_2.isExpanded, true); // Still expanded internally
    });

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
}
