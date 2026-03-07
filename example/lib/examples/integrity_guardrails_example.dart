import 'package:flutter/material.dart';
import 'package:super_tree/super_tree.dart';

class IntegrityGuardrailsExample extends StatefulWidget {
  const IntegrityGuardrailsExample({super.key});

  @override
  State<IntegrityGuardrailsExample> createState() =>
      _IntegrityGuardrailsExampleState();
}

class _IntegrityGuardrailsExampleState extends State<IntegrityGuardrailsExample> {
  late final TreeController<FileSystemItem> _controller;

  @override
  void initState() {
    super.initState();
    _controller = TreeController<FileSystemItem>(roots: _buildRoots());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<TreeNode<FileSystemItem>> _buildRoots() {
    return <TreeNode<FileSystemItem>>[
      TreeNode<FileSystemItem>(
        id: 'workspace',
        data: FolderItem('workspace'),
        isExpanded: true,
        children: <TreeNode<FileSystemItem>>[
          TreeNode<FileSystemItem>(
            id: 'lib',
            data: FolderItem('lib'),
            isExpanded: true,
            children: <TreeNode<FileSystemItem>>[
              TreeNode<FileSystemItem>(
                id: 'readme',
                data: FileItem('README.md'),
              ),
            ],
          ),
          TreeNode<FileSystemItem>(
            id: 'test',
            data: FolderItem('test'),
          ),
        ],
      ),
    ];
  }

  void _triggerDuplicateIdIssue() {
    final TreeNode<FileSystemItem>? parent = _controller.findNodeById('workspace');
    if (parent == null) {
      return;
    }

    _controller.addChild(
      parent,
      TreeNode<FileSystemItem>(
        id: 'readme',
        data: FileItem('README_DUPLICATE.md'),
      ),
    );
  }

  void _triggerCircularReferenceIssue() {
    final TreeNode<FileSystemItem>? workspace = _controller.findNodeById('workspace');
    final TreeNode<FileSystemItem>? lib = _controller.findNodeById('lib');
    if (workspace == null || lib == null) {
      return;
    }

    _controller.addChild(lib, workspace);
  }

  void _clearIntegrityIssues() {
    _controller.clearIntegrityIssues();
  }

  Widget _buildLastIssueCard(BuildContext context) {
    final TreeIntegrityIssue? issue = _controller.lastIntegrityIssue;
    final TextStyle? bodyStyle = Theme.of(context).textTheme.bodyMedium;

    if (issue == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('No integrity issues captured yet.'),
      );
    }

    final String relatedNodeText = issue.relatedNodeId == null
        ? 'n/a'
        : issue.relatedNodeId!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Last issue: ${issue.type.name}',
            style: bodyStyle?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(issue.message),
          const SizedBox(height: 6),
          Text('Operation: ${issue.operation}'),
          Text('Node: ${issue.nodeId ?? 'n/a'}'),
          Text('Related node: $relatedNodeText'),
        ],
      ),
    );
  }

  Widget _buildIntegrityActions() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        FilledButton.tonalIcon(
          onPressed: _triggerDuplicateIdIssue,
          icon: const Icon(Icons.content_copy),
          label: const Text('Try duplicate ID'),
        ),
        FilledButton.tonalIcon(
          onPressed: _triggerCircularReferenceIssue,
          icon: const Icon(Icons.sync_problem),
          label: const Text('Try circular reference'),
        ),
        TextButton.icon(
          onPressed: _clearIntegrityIssues,
          icon: const Icon(Icons.clear_all),
          label: const Text('Clear warnings'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Integrity Guardrails'),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(12),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Text(
                  'Use the actions below to trigger duplicate-ID and circular-reference protections. '
                  'The tree keeps running and reports non-fatal integrity issues.',
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: _buildIntegrityActions(),
              ),
              Expanded(
                child: Row(
                  children: <Widget>[
                    Expanded(
                      flex: 3,
                      child: FileSystemSuperTree(
                        controller: _controller,
                        logic: const TreeViewConfig<FileSystemItem>(
                          enableDragAndDrop: false,
                          namingStrategy: TreeNamingStrategy.none,
                        ),
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: _buildLastIssueCard(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
