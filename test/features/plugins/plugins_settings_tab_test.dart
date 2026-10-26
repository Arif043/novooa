import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/plugins/domain/entities/plugin_activation.dart';
import 'package:syscat2/features/plugins/presentation/plugin_catalog.dart';
import 'package:syscat2/features/plugins/presentation/widgets/plugins_settings_tab.dart';

import '../../helpers/plugins_scope.dart';

const _id = PluginId('hello');

Future<FakePluginRepository> _pumpTab(
  WidgetTester tester, {
  Set<String> enabled = const {},
}) async {
  final repository = FakePluginRepository(enabled);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: BlocProvider(
          create: (_) => pluginsCubitWith(repository),
          child: const PluginsSettingsTab(),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return repository;
}

void main() {
  setUp(
    () => PluginCatalog.register(
      PluginDescription(
        id: _id,
        title: () => 'Hallo-Plugin',
        description: () => 'Sagt Hallo.',
        icon: Icons.waving_hand,
        settingsBuilder: (_) => const Text('Hallo-Einstellungen'),
      ),
    ),
  );
  tearDown(() => PluginCatalog.unregister(_id));

  testWidgets('ein ausgeschaltetes Plugin zeigt keine Einstellungen', (
    tester,
  ) async {
    await _pumpTab(tester);

    expect(find.text('Hallo-Plugin'), findsOneWidget);
    expect(find.text('Aus'), findsOneWidget);
    expect(find.text('Hallo-Einstellungen'), findsNothing);
  });

  testWidgets('Einschalten zeigt die Einstellungen des Plugins', (
    tester,
  ) async {
    await _pumpTab(tester);

    await tester.tap(find.byType(Switch));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Aktiv'), findsOneWidget);
    expect(find.text('Hallo-Einstellungen'), findsOneWidget);
  });

  testWidgets('Ausschalten fragt nach; Abbrechen lässt es aktiv', (
    tester,
  ) async {
    await _pumpTab(tester, enabled: {'hello'});

    await tester.tap(find.byType(Switch));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Hallo-Plugin deaktivieren?'), findsOneWidget);
    await tester.tap(find.text('Abbrechen'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Aktiv'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Deaktivieren'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Aus'), findsOneWidget);
  });
}
