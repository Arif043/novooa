import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/plugins/domain/entities/plugin_activation.dart';
import 'package:syscat2/features/plugins/domain/entities/plugin_failure.dart';
import 'package:syscat2/features/plugins/presentation/cubits/plugins_state.dart';

import '../../helpers/plugins_scope.dart';

const _drive = PluginId('googleDrive');

void main() {
  test('bis zum Laden ist jedes Plugin aus, danach gilt die Runtime', () async {
    final cubit = pluginsCubitWith(FakePluginRepository({'googleDrive'}));

    expect(cubit.state.isEnabled(_drive), isFalse);
    await pumpEventQueue();

    expect(cubit.state.isEnabled(_drive), isTrue);
    expect(cubit.state.isEnabled(const PluginId('shopware')), isFalse);
    await cubit.close();
  });

  test('schaltet ein Plugin ein und wieder aus', () async {
    final cubit = pluginsCubitWith(FakePluginRepository());
    await pumpEventQueue();

    await cubit.setEnabled(_drive, enabled: true);
    expect(cubit.state.isEnabled(_drive), isTrue);

    await cubit.setEnabled(_drive, enabled: false);
    await pumpEventQueue();
    expect(cubit.state.isEnabled(_drive), isFalse);
    await cubit.close();
  });

  test('eine Ablehnung bleibt aus und meldet den Grund', () async {
    final repository = FakePluginRepository()
      ..failNextSwitch = const PluginFailure(PluginFailureKind.adminRequired);
    final cubit = pluginsCubitWith(repository);
    await pumpEventQueue();

    await cubit.setEnabled(_drive, enabled: true);

    final state = cubit.state as PluginsLoaded;
    expect(state.isEnabled(_drive), isFalse);
    expect(state.switchingId, isNull);
    expect(state.notice?.kind, PluginFailureKind.adminRequired);
    await cubit.close();
  });

  test('ein Ladefehler lässt sich erneut versuchen', () async {
    final repository = FakePluginRepository({'googleDrive'})
      ..loadError = const PluginFailure(PluginFailureKind.runtimeUnavailable);
    final cubit = pluginsCubitWith(repository);
    await pumpEventQueue();

    expect(
      (cubit.state as PluginsLoadFailed).failure.kind,
      PluginFailureKind.runtimeUnavailable,
    );
    repository.loadError = null;
    cubit.start();
    await pumpEventQueue();

    expect(cubit.state.isEnabled(_drive), isTrue);
    await cubit.close();
  });
}
