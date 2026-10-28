import '../../../../activity/domain/entities/task_activity.dart';
import '../../../../activity/presentation/widgets/node_output_formatter.dart';

/// Lesbare Werte eines Baustein-Ergebnisses für Karte und Pfeile.
abstract final class RunResultValues {
  /// Der erste Wert (meist `value`) als Vorschau; `null` ohne Werte.
  static String? previewOf(TaskActivity? result) {
    if (result == null) return null;
    if (result.status == TaskActivityStatus.failed) return result.message;
    final outputs = result.outputs;
    final key = outputs.containsKey('value')
        ? 'value'
        : outputs.keys.firstOrNull;
    return key == null ? null : valueOf(result, key);
  }

  /// Ein bestimmter Wert; `null`, wenn der Baustein ihn nicht geliefert hat.
  static String? valueOf(TaskActivity? result, String key) {
    final stored = result?.outputs[key];
    if (stored == null) return null;
    final text = NodeOutputFormatter.format(NodeOutput.fromStored(key, stored));
    return text.trim().isEmpty ? null : text.replaceAll('\n', ' ');
  }
}
