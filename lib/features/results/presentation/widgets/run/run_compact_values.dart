import '../../../../activity/domain/entities/task_activity.dart';
import '../../../../activity/presentation/widgets/node_output_formatter.dart';
import '../../../../task_builder/domain/entities/workflow_node.dart';
import '../../../../task_builder/presentation/cubits/workflow_primitive_labels.dart';

/// Werte und Namen eines Baustein-Ergebnisses in kurzer Form.
abstract final class RunCompactValues {
  /// „Rechnungsnummer: 12 · Name: Penny“. Liefert ein Baustein einzelne
  /// Felder, fällt das Sammelfeld `value` weg, damit nichts doppelt steht.
  static String line(TaskActivity activity) {
    final outputs = activity.outputs;
    final keys = outputs.keys.where(
      (key) => outputs.length == 1 || key != 'value',
    );
    return [
      for (final key in keys)
        _entry(
          key,
          NodeOutputFormatter.format(NodeOutput.fromStored(key, outputs[key])),
        ),
    ].where((entry) => entry.isNotEmpty).join(' · ');
  }

  /// Der Name der Baustein-Art, z. B. „Formulareingabe“.
  static String primitiveLabel(String? primitive) {
    final match = WorkflowPrimitive.values
        .where((value) => value.name == primitive)
        .firstOrNull;
    return match?.label ?? primitive ?? '';
  }

  static String _entry(String key, String value) {
    final text = value.replaceAll('\n', ' ').trim();
    if (text.isEmpty) return '';
    return key == 'value'
        ? text
        : '${NodeOutputFormatter.labelFor(key)}: $text';
  }
}
