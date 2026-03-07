import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:example/examples/async_lazy_loading_example.dart';
import 'package:example/examples/checkbox_example.dart';
import 'package:example/examples/complex_node_example.dart';
import 'package:example/examples/file_system_example.dart';
import 'package:example/examples/integrity_guardrails_example.dart';
import 'package:example/examples/simple_file_system_example.dart';
import 'package:example/examples/todo_list_example.dart';
import 'package:example/l10n/app_localizations.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (BuildContext context) =>
          AppLocalizations.of(context)!.appTitle,
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
  final IconData icon;
  final Widget screen;

  const ExampleInfo({
    required this.id,
    required this.icon,
    required this.screen,
  });
}

class ExampleHubScreen extends StatelessWidget {
  const ExampleHubScreen({super.key});

  final List<ExampleInfo> _examples = const [
    ExampleInfo(
      id: 'file-system',
      icon: Icons.folder_open,
      screen: FileSystemExample(),
    ),
    ExampleInfo(
      id: 'checkbox-state',
      icon: Icons.check_box,
      screen: CheckboxExample(),
    ),
    ExampleInfo(
      id: 'complex-node-ui',
      icon: Icons.dashboard_customize,
      screen: ComplexNodeExample(),
    ),
    ExampleInfo(
      id: 'todo-tree',
      icon: Icons.checklist_rtl,
      screen: TodoListExample(),
    ),
    ExampleInfo(
      id: 'minimal-file-system',
      icon: Icons.folder,
      screen: SimpleFileSystemExample(),
    ),
    ExampleInfo(
      id: 'async-lazy-loading',
      icon: Icons.hourglass_top,
      screen: AsyncLazyLoadingExample(),
    ),
    ExampleInfo(
      id: 'integrity-guardrails',
      icon: Icons.health_and_safety,
      screen: IntegrityGuardrailsExample(),
    ),
  ];

  String _exampleTitle(AppLocalizations l10n, ExampleInfo example) {
    switch (example.id) {
      case 'file-system':
        return l10n.exampleFileSystemTitle;
      case 'checkbox-state':
        return l10n.exampleCheckboxTitle;
      case 'complex-node-ui':
        return l10n.exampleComplexNodeTitle;
      case 'todo-tree':
        return l10n.exampleTodoTitle;
      case 'minimal-file-system':
        return l10n.exampleSimpleFileSystemTitle;
      case 'async-lazy-loading':
        return l10n.exampleAsyncLazyTitle;
      case 'integrity-guardrails':
        return l10n.exampleIntegrityTitle;
      default:
        return example.id;
    }
  }

  String _exampleDescription(AppLocalizations l10n, ExampleInfo example) {
    switch (example.id) {
      case 'file-system':
        return l10n.exampleFileSystemDescription;
      case 'checkbox-state':
        return l10n.exampleCheckboxDescription;
      case 'complex-node-ui':
        return l10n.exampleComplexNodeDescription;
      case 'todo-tree':
        return l10n.exampleTodoDescription;
      case 'minimal-file-system':
        return l10n.exampleSimpleFileSystemDescription;
      case 'async-lazy-loading':
        return l10n.exampleAsyncLazyDescription;
      case 'integrity-guardrails':
        return l10n.exampleIntegrityDescription;
      default:
        return '';
    }
  }

  void _openExample(BuildContext context, ExampleInfo example) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (BuildContext context) => example.screen),
    );
  }

  Widget _buildQuickLinks(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _examples
          .map(
            (ExampleInfo example) => ActionChip(
              key: ValueKey<String>('quick_link_${example.id}'),
              label: Text(_exampleTitle(l10n, example)),
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
    final AppLocalizations l10n = AppLocalizations.of(context)!;

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
        title: Text(_exampleTitle(l10n, example), style: textTheme.titleMedium),
        subtitle: Text(
          _exampleDescription(l10n, example),
          style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _openExample(context, example),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: <Widget>[
              Text(
                l10n.quickLinksTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              _buildQuickLinks(context),
              const SizedBox(height: 20),
              Text(
                l10n.allExamplesTitle,
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
