import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/core/di/service_locator.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';
import 'package:syscat2/features/plugins/domain/entities/installed_plugin.dart';
import 'package:syscat2/features/plugins/domain/entities/plugin_catalog_entry.dart';
import 'package:syscat2/features/plugins/domain/entities/plugin_failure.dart';
import 'package:syscat2/features/plugins/domain/entities/plugin_manifest.dart';
import 'package:syscat2/features/plugins/domain/entities/plugin_settings.dart';
import 'package:syscat2/features/plugins/domain/repositories/plugin_archive_gateway.dart';
import 'package:syscat2/features/plugins/domain/repositories/plugin_install_repository.dart';
import 'package:syscat2/features/plugins/domain/repositories/plugin_repository.dart';
import 'package:syscat2/features/plugins/domain/usecases/plugin_use_cases.dart';
import 'package:syscat2/features/plugins/presentation/cubits/plugin_catalog_cubit.dart';
import 'package:syscat2/features/plugins/presentation/cubits/plugin_install_cubit.dart';
import 'package:syscat2/features/plugins/presentation/cubits/plugins_cubit.dart';
import 'package:syscat2/features/plugins/presentation/widgets/plugin_field_editor.dart';
import 'package:syscat2/features/plugins/presentation/widgets/plugins_settings_tab.dart';
import 'package:syscat2/features/teams/domain/repositories/team_repository.dart';
import 'package:syscat2/features/teams/domain/usecases/get_current_team_id.dart';

const _panelField = PluginField(
  key: 'greeting',
  label: 'Gruß',
  kind: PluginFieldKind.text,
  defaultValue: 'Hallo',
);
const _manifest = PluginManifest(
  id: 'hallo',
  version: '1.0.0',
  name: 'Hallo-Plugin',
  description: 'grüßt freundlich',
  primitives: [
    PluginPrimitiveDefinition(
      type: 'greet',
      label: 'Begrüßen',
      description: '',
    ),
  ],
  settingsPanels: [
    PluginSettingsPanel(id: 'main', title: 'Hallo-Einstellungen', fields: [_panelField]),
  ],
);

void main() {
  group('PluginFieldEditor', () {
    Future<List<Object>> edit(WidgetTester tester, PluginField field, Object? value, Future<void> Function() act) async {
      final changes = <Object>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PluginFieldEditor(field: field, value: value, onChanged: changes.add),
          ),
        ),
      );
      await act();
      return changes;
    }

    testWidgets('Text meldet die Eingabe', (tester) async {
      final changes = await edit(tester, _panelField, null, () async {
        expect(find.text('Hallo'), findsOneWidget);
        await tester.enterText(find.byType(TextField), 'Moin');
      });
      expect(changes, ['Moin']);
    });

    testWidgets('Zahl meldet eine Zahl, auch mit Komma', (tester) async {
      const field = PluginField(key: 'n', label: 'Anzahl', kind: PluginFieldKind.number);
      final changes = await edit(tester, field, null, () => tester.enterText(find.byType(TextField), '2,5'));
      expect(changes, [2.5]);
    });

    testWidgets('Schalter meldet bool', (tester) async {
      const field = PluginField(key: 'on', label: 'Aktiv', kind: PluginFieldKind.toggle);
      final changes = await edit(tester, field, false, () => tester.tap(find.byType(Switch)));
      expect(changes, [true]);
    });

    testWidgets('Auswahl zeigt Optionen und meldet den Wert', (tester) async {
      const field = PluginField(
        key: 'mode',
        label: 'Modus',
        kind: PluginFieldKind.choice,
        options: [PluginFieldOption(value: 'a', label: 'Option A'), PluginFieldOption(value: 'b', label: 'Option B')],
      );
      final changes = await edit(tester, field, 'a', () async {
        await tester.tap(find.byType(DropdownButtonFormField<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Option B').last);
      });
      expect(changes, ['b']);
    });

    testWidgets('Geheimnisse sind verdeckt und verraten, ob eines gesetzt ist', (tester) async {
      const field = PluginField(key: 'k', label: 'Schlüssel', kind: PluginFieldKind.text, secret: true);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PluginFieldEditor(field: field, value: 'geheim', secretIsSet: true, onChanged: (_) {}),
          ),
        ),
      );
      expect(tester.widget<TextField>(find.byType(TextField)).obscureText, isTrue);
      expect(find.text('geheim'), findsNothing);
      expect(find.text('Gesetzt – leer lassen, um ihn zu behalten'), findsOneWidget);
    });
  });

  group('PluginsSettingsTab', () {
    final repository = _Repository();
    final installs = _Installs();

    setUp(() {
      final locator = serviceLocator;
      final teams = GetCurrentTeamId(_Teams());
      locator
        ..registerFactory(() => PluginsCubit(WatchPlugins(repository), UninstallPlugin(repository), teams))
        ..registerFactory(
          () => PluginInstallCubit(
            PreviewPluginFromCatalog(installs),
            PreviewPluginFromArchive(installs),
            CommitPluginInstall(installs),
            _Archives(),
          ),
        )
        ..registerFactory(() => PluginCatalogCubit(LoadPluginCatalog(installs)))
        ..registerLazySingleton(() => LoadPluginSettings(repository))
        ..registerLazySingleton(() => SavePluginSettings(repository));
      repository.plugins = const [InstalledPlugin(manifest: _manifest)];
      repository.uninstalled.clear();
    });

    tearDown(serviceLocator.reset);

    // Der Titel steht auch im Katalog; die installierte Kachel ist die aufklappbare.
    Finder installedTitle() => find.descendant(
      of: find.byType(ExpansionTile),
      matching: find.text('Hallo-Plugin 1.0.0'),
    );

    Future<void> pumpTab(WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: PluginsSettingsTab())));
      await tester.pumpAndSettle();
    }

    testWidgets('listet installierte Plugins mit Zusammenfassung und zeigt den Katalog', (tester) async {
      await pumpTab(tester);

      expect(installedTitle(), findsOneWidget);
      expect(find.text('1 Baustein · 1 Einstellungs-Panel'), findsOneWidget);
      expect(find.text('Installiert'), findsOneWidget);
    });

    testWidgets('aufgeklappt erscheinen die Einstellungs-Panels des Plugins', (tester) async {
      await pumpTab(tester);

      await tester.tap(installedTitle());
      await tester.pumpAndSettle();

      expect(find.text('Hallo-Einstellungen'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Gruß'), findsOneWidget);
    });

    testWidgets('Deinstallieren verlangt eine Bestätigung', (tester) async {
      await pumpTab(tester);
      await tester.tap(installedTitle());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Deinstallieren'));
      await tester.tap(find.text('Deinstallieren'));
      await tester.pumpAndSettle();
      expect(find.text('„Hallo-Plugin“ deinstallieren?'), findsOneWidget);
      expect(repository.uninstalled, isEmpty);

      await tester.tap(find.widgetWithText(FilledButton, 'Deinstallieren'));
      await tester.pumpAndSettle();

      expect(repository.uninstalled, ['hallo']);
    });

    testWidgets('ein neues Plugin aus dem Katalog zeigt vor dem Installieren, was es mitbringt', (tester) async {
      repository.plugins = const [];
      await pumpTab(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Installieren'));
      await tester.pumpAndSettle();

      expect(find.text('Bringt mit:'), findsOneWidget);
      expect(find.text('Baustein „Begrüßen“'), findsOneWidget);
      expect(find.text('Einstellungen „Hallo-Einstellungen“'), findsOneWidget);
    });
  });
}

class _Teams implements TeamRepository {
  @override
  Future<TeamId> currentTeamId() async => const TeamId('team-1');

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Repository implements PluginRepository {
  List<InstalledPlugin> plugins = const [];
  final uninstalled = <String>[];

  @override
  Stream<List<InstalledPlugin>> watchPlugins(TeamId teamId) => Stream.value(plugins);

  @override
  Future<Result<Unit, PluginFailure>> uninstall(String pluginId) async {
    uninstalled.add(pluginId);
    return const Success(unit);
  }

  @override
  Future<Result<PluginSettings, PluginFailure>> settings(String pluginId) async =>
      const Success(PluginSettings(values: {'greeting': 'Hallo'}));

  @override
  Future<Result<Unit, PluginFailure>> saveSettings(String pluginId, Map<String, Object> values) async =>
      const Success(unit);
}

class _Installs implements PluginInstallRepository {
  @override
  Future<Result<List<PluginCatalogEntry>, PluginFailure>> catalog() async => const Success([
    PluginCatalogEntry(id: 'hallo', name: 'Hallo-Plugin', description: 'grüßt freundlich', version: '1.0.0', sizeBytes: 1),
  ]);

  @override
  Future<Result<PluginInstallPreview, PluginFailure>> previewFromCatalog(String pluginId) async =>
      const Success(PluginInstallPreview(installId: 'i', manifest: _manifest));

  @override
  Future<Result<PluginInstallPreview, PluginFailure>> previewFromArchive(Uint8List bytes, String fileName) async =>
      const Success(PluginInstallPreview(installId: 'i', manifest: _manifest));

  @override
  Future<Result<InstalledPlugin, PluginFailure>> commit(String installId) async =>
      const Success(InstalledPlugin(manifest: _manifest));
}

class _Archives implements PluginArchiveGateway {
  @override
  Future<Result<PluginArchive, PluginFailure>> pick() async => const Error(PluginFailure.cancelled);
}
