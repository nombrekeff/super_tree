import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class _OpenSearchIntent extends Intent {
  const _OpenSearchIntent();
}

class _CloseSearchIntent extends Intent {
  const _CloseSearchIntent();
}

/// Shared keyboard shortcuts wrapper for example search UI.
class ExampleTreeSearchShortcuts extends StatelessWidget {
  const ExampleTreeSearchShortcuts({
    super.key,
    required this.onOpenSearch,
    required this.onCloseSearch,
    required this.child,
  });

  final VoidCallback onOpenSearch;
  final VoidCallback onCloseSearch;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Map<ShortcutActivator, Intent> shortcuts = <ShortcutActivator, Intent>{
      const SingleActivator(LogicalKeyboardKey.keyF, control: true): const _OpenSearchIntent(),
      const SingleActivator(LogicalKeyboardKey.keyF, meta: true): const _OpenSearchIntent(),
      const SingleActivator(LogicalKeyboardKey.escape): const _CloseSearchIntent(),
    };

    final Map<Type, Action<Intent>> actions = <Type, Action<Intent>>{
      _OpenSearchIntent: CallbackAction<_OpenSearchIntent>(
        onInvoke: (_) {
          onOpenSearch();
          return null;
        },
      ),
      _CloseSearchIntent: CallbackAction<_CloseSearchIntent>(
        onInvoke: (_) {
          onCloseSearch();
          return null;
        },
      ),
    };

    return Shortcuts(
      shortcuts: shortcuts,
      child: Actions(
        actions: actions,
        child: child,
      ),
    );
  }
}
