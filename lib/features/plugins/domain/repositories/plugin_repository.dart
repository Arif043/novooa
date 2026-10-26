import 'package:multiple_result/multiple_result.dart';

import '../entities/plugin_activation.dart';
import '../entities/plugin_failure.dart';

abstract interface class PluginRepository {
  /// Zustand der Plugins, live: Schaltet ein Admin, kommt die neue Liste.
  /// Ein Fehler kommt als [PluginFailure] im Stream.
  Stream<List<PluginActivation>> watchPlugins();

  Future<Result<PluginActivation, PluginFailure>> setEnabled(
    PluginId id, {
    required bool enabled,
  });
}
