import 'package:flutter/material.dart';
import 'package:example/examples/async_lazy_loading_example.dart';
import 'package:example/examples/checkbox_example.dart';
import 'package:example/examples/complex_node_example.dart';
import 'package:example/examples/file_system_example.dart';
import 'package:example/examples/integrity_guardrails_example.dart';
import 'package:example/examples/simple_file_system_example.dart';
import 'package:example/examples/todo_list_example.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Super Tree Examples',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.dark,
      home: const ExampleHubScreen(),
    );
  }
}

class ExampleInfo {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Widget screen;

  const ExampleInfo({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.screen,
  });
}

class ExampleHubScreen extends StatelessWidget {
  const ExampleHubScreen({super.key});

  final List<ExampleInfo> _examples = const [
    ExampleInfo(
      id: 'file-system',
      title: 'File System Explorer',
      description: 'The classic file explorer example with drag & drop and multiple presets (VS Code, Material, Compact).',
      icon: Icons.folder_open,
      screen: FileSystemExample(),
    ),
    ExampleInfo(
      id: 'checkbox-state',
      title: 'Checkboxes & State',
      description: 'A permissions tree demonstrating checkboxes with recursive parent/child state management.',
      icon: Icons.check_box,
      screen: CheckboxExample(),
    ),
    ExampleInfo(
      id: 'complex-node-ui',
      title: 'Complex Node UI',
      description: 'A task management board showing rich custom node content, avatars, and inline actions.',
      icon: Icons.dashboard_customize,
      screen: ComplexNodeExample(),
    ),
    ExampleInfo(
      id: 'todo-tree',
      title: 'Todo List Tree',
      description: 'A prebuilt convenience tree view demonstrating default checkboxes, data models, and sorting logic for a hierarchical todo list.',
      icon: Icons.checklist_rtl,
      screen: TodoListExample(),
    ),
    ExampleInfo(
      id: 'minimal-file-system',
      title: 'Minimal File System',
      description: 'A minimalist example showing how to build a file tree with zero boilerplate and hardcoded data.',
      icon: Icons.folder,
      screen: SimpleFileSystemExample(),
    ),
    ExampleInfo(
      id: 'async-lazy-loading',
      title: 'Async Lazy Loading',
      description: 'Shows on-demand child loading with spinner and error retry states when expanding nodes.',
      icon: Icons.hourglass_top,
      screen: AsyncLazyLoadingExample(),
    ),
    ExampleInfo(
      id: 'integrity-guardrails',
      title: 'Integrity Guardrails',
      description: 'Demonstrates duplicate-ID and circular-reference safety checks with non-fatal UI warnings.',
      icon: Icons.health_and_safety,
      screen: IntegrityGuardrailsExample(),
    ),
  ];

  void _openExample(BuildContext context, ExampleInfo example) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (BuildContext context) => example.screen),
    );
  }

  Widget _buildQuickLinks(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _examples
          .map(
            (ExampleInfo example) => ActionChip(
              key: ValueKey<String>('quick_link_${example.id}'),
              label: Text(example.title),
              avatar: Icon(example.icon, size: 16),
              onPressed: () => _openExample(context, example),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildExampleTile(BuildContext context, ExampleInfo example) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Card(
      key: ValueKey<String>('example_tile_${example.id}'),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          child: Icon(example.icon, size: 18),
        ),
        title: Text(example.title, style: textTheme.titleMedium),
        subtitle: Text(
          example.description,
          style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _openExample(context, example),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Tree Examples'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: <Widget>[
              Text(
                'Quick Links',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              _buildQuickLinks(context),
              const SizedBox(height: 20),
              Text(
                'All Examples',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              ..._examples.map((ExampleInfo example) {
                return _buildExampleTile(context, example);
              }),
            ],
          ),
        ),
      ),
    );
  }
}
