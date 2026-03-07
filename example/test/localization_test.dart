import 'package:example/main.dart';
import 'package:example/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Example app renders Spanish localization in hub screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('es'),
        localizationsDelegates: <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: ExampleHubScreen(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Accesos rapidos'), findsOneWidget);
    expect(find.text('Todos los ejemplos'), findsOneWidget);
    expect(find.text('Explorador de archivos'), findsWidgets);
  });
}
