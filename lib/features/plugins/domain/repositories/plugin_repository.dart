import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';

import '../entities/installed_plugin.dart';
import '../entities/plugin_failure.dart';
import '../entities/plugin_settings.dart';

/// Die installierten Plugins. `watchPlugins` liest neu, wenn sich dort etwas ändert.
abstract class PluginRepository {
  Stream<List<InstalledPlugin>> watchPlugins(TeamId teamId);

  Future<Result<Unit, PluginFailure>> uninstall(String pluginId);

  Future<Result<PluginSettings, PluginFailure>> settings(String pluginId);

  /// Leere Geheimnisse lassen den gespeicherten Wert unverändert.
  Future<Result<Unit, PluginFailure>> saveSettings(
    String pluginId,
    Map<String, Object> values,
  );
}
