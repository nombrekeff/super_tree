import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:super_tree/super_tree.dart';

void main() {
  group('Public API aliases', () {
    test('SuperTree aliases map to existing core types', () {
      final SuperTreeController<String> controller =
          SuperTreeController<String>();
      final SuperTreeNode<String> node = SuperTreeNode<String>(
        id: 'n1',
        data: 'Node 1',
      );
      const SuperTreeViewConfig<String> config = SuperTreeViewConfig<String>();
      const SuperTreeViewStyle style = SuperTreeViewStyle();

      expect(controller, isA<TreeController<String>>());
      expect(node, isA<TreeNode<String>>());
      expect(config, isA<TreeViewConfig<String>>());
      expect(style, isA<TreeViewStyle>());
    });

    test('SuperTree event aliases are assignable from controller events', () {
      final SuperTreeController<String> controller =
          SuperTreeController<String>();

      final Stream<SuperTreeEvent<String>> aliasedEvents = controller.events;
      final Stream<SuperTreeNodeAddedEvent<String>> aliasedAddedEvents =
          controller.nodeAddedEvents;

      expect(aliasedEvents, isA<Stream<TreeEvent<String>>>());
      expect(aliasedAddedEvents, isA<Stream<TreeNodeAddedEvent<String>>>());
    });
  });

  group('TreeController event-specific streams', () {
    test('nodeAddedEvents emits only add operations', () async {
      final TreeController<String> controller = TreeController<String>();
      final List<String> addedIds = <String>[];
      final StreamSubscription<TreeNodeAddedEvent<String>> subscription =
          controller.nodeAddedEvents.listen((TreeNodeAddedEvent<String> event) {
            addedIds.add(event.node.id);
          });

      controller.addRoot(TreeNode<String>(id: 'root_1', data: 'Root 1'));
      controller.addRoot(TreeNode<String>(id: 'root_2', data: 'Root 2'));

      await Future<void>.delayed(Duration.zero);
      expect(addedIds, <String>['root_1', 'root_2']);

      await subscription.cancel();
      controller.dispose();
    });

    test('listener helpers subscribe to the matching event type', () async {
      final TreeController<String> controller = TreeController<String>(
        roots: <TreeNode<String>>[
          TreeNode<String>(id: 'root_1', data: 'Root 1'),
          TreeNode<String>(id: 'root_2', data: 'Root 2'),
        ],
      );

      final List<String> renamed = <String>[];
      final List<String> removed = <String>[];
      final List<List<String>> moved = <List<String>>[];

      final StreamSubscription<TreeNodeRenamedEvent<String>> renamedSub =
          controller.addNodeRenamedListener((
            TreeNodeRenamedEvent<String> event,
          ) {
            renamed.add(event.newName);
          });
      final StreamSubscription<TreeNodeRemovedEvent<String>> removedSub =
          controller.addNodeRemovedListener((
            TreeNodeRemovedEvent<String> event,
          ) {
            removed.add(event.node.id);
          });
      final StreamSubscription<TreeNodeMovedEvent<String>> movedSub = controller
          .addNodeMovedListener((TreeNodeMovedEvent<String> event) {
            moved.add(
              event.nodes.map((TreeNode<String> node) => node.id).toList(),
            );
          });

      final TreeNode<String> root1 = controller.findNodeById('root_1')!;
      final TreeNode<String> root2 = controller.findNodeById('root_2')!;
      controller.renameNode('root_1', 'Renamed Root');
      controller.moveNode(dragged: root1, target: root2, insertBefore: false);
      controller.removeNode(root2);

      await Future<void>.delayed(Duration.zero);

      expect(renamed, <String>['Renamed Root']);
      expect(moved, <List<String>>[
        <String>['root_1'],
      ]);
      expect(removed, <String>['root_2']);

      await renamedSub.cancel();
      await removedSub.cancel();
      await movedSub.cancel();
      controller.dispose();
    });
  });

  group('Shared node data contract', () {
    test('SuperTreeData provides default contract values', () {
      const _SharedContractData data = _SharedContractData();

      expect(data, isA<SuperTreeNodeContract>());
      expect(data.canHaveChildren, isTrue);
      expect(data.iconToken, isNull);
    });

    test(
      'SuperTreeData implementations can override icon and child capability',
      () {
        const _SharedContractData data = _SharedContractData(
          canHaveChildren: false,
          iconToken: 'file-icon',
        );

        expect(data.canHaveChildren, isFalse);
        expect(data.iconToken, 'file-icon');
      },
    );
  });
}

class _SharedContractData with SuperTreeData {
  const _SharedContractData({this.canHaveChildren = true, this.iconToken});

  @override
  final bool canHaveChildren;

  @override
  final Object? iconToken;
}
