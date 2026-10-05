import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
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
import 'package:syscat2/features/plugins/presentation/cubits/plugin_install_cubit.dart';
import 'package:syscat2/features/plugins/presentation/cubits/plugin_install_state.dart';
import 'package:syscat2/features/plugins/presentation/cubits/plugin_registry_cubit.dart';
import 'package:syscat2/features/plugins/presentation/cubits/plugin_settings_cubit.dart';
import 'package:syscat2/features/plugins/presentation/cubits/plugin_settings_state.dart';
import 'package:syscat2/features/plugins/presentation/cubits/plugins_cubit.dart';
import 'package:syscat2/features/plugins/presentation/cubits/plugins_state.dart';
import 'package:syscat2/features/teams/domain/repositories/team_repository.dart';
import 'package:syscat2/features/teams/domain/usecases/get_current_team_id.dart';

const _manifest = PluginManifest(
  id: 'hallo',
  version: '1.0.0',
  name: 'Hallo-Plugin',
  description: 'grüßt',
);
const _plugin = InstalledPlugin(manifest: _manifest);
const _preview = PluginInstallPreview(installId: 'inst-1', manifest: _manifest);

void main() {
  group('PluginsCubit', () {
    test('zeigt die installierten Plugins', () async {
      final repository = _PluginRepository(plugins: const [_plugin]);
      final cubit = _pluginsCubit(repository);

      await cubit.load();
      await pumpEventQueue();

      expect(cubit.state.status, PluginsStatus.ready);
      expect(cubit.state.plugins, [_plugin]);
      await cubit.close();
    });

    test('Deinstallieren meldet den Namen des Plugins', () async {
      final repository = _PluginRepository(plugins: const [_plugin]);
      final cubit = _pluginsCubit(repository);
      await cubit.load();
      await pumpEventQueue();

      await cubit.uninstall('hallo');

      expect(repository.uninstalled, ['hallo']);
      expect(cubit.state.message, 'Plugin „Hallo-Plugin“ deinstalliert.');
      cubit.messageShown();
      expect(cubit.state.message, isNull);
      await cubit.close();
    });

    test('ein Fehler beim Deinstallieren wird gemeldet', () async {
      final cubit = _pluginsCubit(
        _PluginRepository(
          uninstallResult: const Error(PluginFailure.uninstallFailed),
        ),
      );

      await cubit.uninstall('hallo');

      expect(cubit.state.message, PluginFailure.uninstallFailed.message);
      await cubit.close();
    });
  });

  group('PluginInstallCubit', () {
    test('Vorschau aus dem Katalog führt zur Bestätigung', () async {
      final cubit = _installCubit();

      await cubit.previewCatalogEntry('hallo');

      expect(cubit.state, const PluginInstallReview(_preview));
    });

    test('Bestätigen installiert und meldet den Namen', () async {
      final repository = _InstallRepository();
      final cubit = _installCubit(repository: repository);
      await cubit.previewCatalogEntry('hallo');

      await cubit.confirm();

      expect(repository.committed, ['inst-1']);
      expect(cubit.state, const PluginInstallDone('Hallo-Plugin'));
    });

    test('Bestätigen ohne Vorschau tut nichts', () async {
      final repository = _InstallRepository();
      final cubit = _installCubit(repository: repository);

      await cubit.confirm();

      expect(repository.committed, isEmpty);
      expect(cubit.state, const PluginInstallIdle());
    });

    test('abgelehnte Pakete zeigen die Meldung des Servers', () async {
      final cubit = _installCubit(
        repository: _InstallRepository(
          previewResult: const Error(
            PluginFailure('Die Signatur des Plugins ist ungültig.'),
          ),
        ),
      );

      await cubit.previewCatalogEntry('hallo');

      expect(
        cubit.state,
        const PluginInstallFailed('Die Signatur des Plugins ist ungültig.'),
      );
    });

    test('ZIP wählen: Abbrechen ist kein Fehler, Auswahl führt zur Vorschau', () async {
      final gateway = _Archives(const Error(PluginFailure.cancelled));
      final repository = _InstallRepository();
      final cubit = _installCubit(repository: repository, gateway: gateway);

      await cubit.pickArchive();
      expect(cubit.state, const PluginInstallIdle());

      gateway.result = Success(
        PluginArchive(fileName: 'hallo.zip', bytes: Uint8List(3)),
      );
      await cubit.pickArchive();

      expect(repository.archiveNames, ['hallo.zip']);
      expect(cubit.state, const PluginInstallReview(_preview));
    });
  });

  group('PluginSettingsCubit', () {
    test('speichert nur den Entwurf und lädt danach neu', () async {
      final repository = _PluginRepository(
        stored: const PluginSettings(
          values: {'greeting': 'Hallo'},
          secretsSet: {'apiKey'},
        ),
      );
      final cubit = PluginSettingsCubit(
        'hallo',
        LoadPluginSettings(repository),
        SavePluginSettings(repository),
      );
      await cubit.load();
      expect(cubit.state.valueOf('greeting'), 'Hallo');
      expect(cubit.state.hasChanges, isFalse);

      cubit.setValue('greeting', 'Moin');
      expect(cubit.state.valueOf('greeting'), 'Moin');
      expect(cubit.state.hasChanges, isTrue);

      await cubit.save();

      expect(repository.saved, [
        {'greeting': 'Moin'},
      ]);
      expect(cubit.state.hasChanges, isFalse);
      expect(cubit.state.message, 'Einstellungen gespeichert.');
    });

    test('ein Fehler beim Speichern erhält den Entwurf', () async {
      final repository = _PluginRepository(
        saveResult: const Error(PluginFailure('Pflichtfeld fehlt.')),
      );
      final cubit = PluginSettingsCubit(
        'hallo',
        LoadPluginSettings(repository),
        SavePluginSettings(repository),
      );
      await cubit.load();
      cubit.setValue('greeting', '');

      await cubit.save();

      expect(cubit.state.message, 'Pflichtfeld fehlt.');
      expect(cubit.state.saving, isFalse);
      expect(cubit.state.hasChanges, isTrue);
      expect(cubit.state.status, PluginSettingsStatus.ready);
    });
  });

  group('PluginRegistryCubit', () {
    test('liefert die Manifeste der installierten Plugins', () async {
      final registry = PluginRegistryCubit(
        WatchPlugins(_PluginRepository(plugins: const [_plugin])),
        GetCurrentTeamId(_Teams()),
      );

      await registry.ensureLoaded();
      await registry.ensureLoaded();
      await pumpEventQueue();

      expect(registry.state, [_manifest]);
      expect(registry.manifestFor('hallo'), _manifest);
      expect(registry.manifestFor('fehlt'), isNull);
      await registry.close();
    });
  });
}

PluginsCubit _pluginsCubit(_PluginRepository repository) => PluginsCubit(
  WatchPlugins(repository),
  UninstallPlugin(repository),
  GetCurrentTeamId(_Teams()),
);

PluginInstallCubit _installCubit({
  _InstallRepository? repository,
  _Archives? gateway,
}) {
  final target = repository ?? _InstallRepository();
  return PluginInstallCubit(
    PreviewPluginFromCatalog(target),
    PreviewPluginFromArchive(target),
    CommitPluginInstall(target),
    gateway ?? _Archives(const Error(PluginFailure.cancelled)),
  );
}

class _Teams implements TeamRepository {
  @override
  Future<TeamId> currentTeamId() async => const TeamId('team-1');

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _PluginRepository implements PluginRepository {
  _PluginRepository({
    this.plugins = const [],
    this.stored = const PluginSettings(),
    this.uninstallResult = const Success(unit),
    this.saveResult = const Success(unit),
  });

  final List<InstalledPlugin> plugins;
  final PluginSettings stored;
  final Result<Unit, PluginFailure> uninstallResult;
  final Result<Unit, PluginFailure> saveResult;
  final uninstalled = <String>[];
  final saved = <Map<String, Object>>[];

  @override
  Stream<List<InstalledPlugin>> watchPlugins(TeamId teamId) =>
      Stream.value(plugins);

  @override
  Future<Result<Unit, PluginFailure>> uninstall(String pluginId) async {
    uninstalled.add(pluginId);
    return uninstallResult;
  }

  @override
  Future<Result<PluginSettings, PluginFailure>> settings(
    String pluginId,
  ) async => Success(stored);

  @override
  Future<Result<Unit, PluginFailure>> saveSettings(
    String pluginId,
    Map<String, Object> values,
  ) async {
    saved.add(values);
    return saveResult;
  }
}

class _InstallRepository implements PluginInstallRepository {
  _InstallRepository({this.previewResult = const Success(_preview)});

  final Result<PluginInstallPreview, PluginFailure> previewResult;
  final committed = <String>[];
  final archiveNames = <String>[];

  @override
  Future<Result<List<PluginCatalogEntry>, PluginFailure>> catalog() async =>
      const Success([]);

  @override
  Future<Result<PluginInstallPreview, PluginFailure>> previewFromCatalog(
    String pluginId,
  ) async => previewResult;

  @override
  Future<Result<PluginInstallPreview, PluginFailure>> previewFromArchive(
    Uint8List bytes,
    String fileName,
  ) async {
    archiveNames.add(fileName);
    return previewResult;
  }

  @override
  Future<Result<InstalledPlugin, PluginFailure>> commit(
    String installId,
  ) async {
    committed.add(installId);
    return const Success(_plugin);
  }
}

class _Archives implements PluginArchiveGateway {
  _Archives(this.result);

  Result<PluginArchive, PluginFailure> result;

  @override
  Future<Result<PluginArchive, PluginFailure>> pick() async => result;
}
