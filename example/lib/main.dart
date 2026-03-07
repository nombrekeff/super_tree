import 'package:flutter/material.dart';
import 'examples/file_system_example.dart';
import 'examples/checkbox_example.dart';
import 'examples/complex_node_example.dart';
import 'examples/todo_list_example.dart';

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
      home: const ExampleHubScreen(),
    );
  }
}

class ExampleInfo {
  final String title;
  final String description;
  final IconData icon;
  final Widget screen;

  const ExampleInfo({
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
      title: 'File System Explorer',
      description: 'The classic file explorer example with drag & drop and multiple themes (VS Code, Finder, etc).',
      icon: Icons.folder_open,
      screen: FileSystemExample(),
    ),
    ExampleInfo(
      title: 'Checkboxes & State',
      description: 'A permissions tree demonstrating checkboxes with recursive parent/child state management.',
      icon: Icons.check_box,
      screen: CheckboxExample(),
    ),
    ExampleInfo(
      title: 'Complex Node UI',
      description: 'A task management board showing rich custom node content, avatars, and inline actions.',
      icon: Icons.dashboard_customize,
      screen: ComplexNodeExample(),
    ),
    ExampleInfo(
      title: 'Todo List Tree',
      description: 'A prebuilt convenience tree view demonstrating default checkboxes, data models, and sorting logic for a hierarchical todo list.',
      icon: Icons.checklist_rtl,
      screen: TodoListExample(),
    ),
  ];

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
          child: ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: _examples.length,
            itemBuilder: (context, index) {
              final example = _examples[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => example.screen),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            example.icon,
                            size: 32,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                example.title,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                example.description,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
