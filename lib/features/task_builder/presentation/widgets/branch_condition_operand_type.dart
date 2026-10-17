import '../../domain/entities/node_config.dart';
import '../../domain/entities/task_execution_result.dart';
import '../../domain/entities/workflow_graph.dart';
import '../../domain/entities/workflow_node.dart';
import '../../domain/entities/workflow_output_types.dart';

/// Grobe, rein UI-seitige Typ-Einschätzung eines Operanden (Template-
/// Ausdruck oder Literal) innerhalb einer [ComparisonCondition] — steuert
/// nur, welche [ComparisonOperator]s vorgeschlagen werden und ob der
/// Gegenoperand frei eingebbar bleibt oder auf feste Werte beschränkt wird.
/// Die Persistenz selbst bleibt typ-agnostisch (siehe `branch_condition.dart`).
sealed class OperandTypeHint {
  const OperandTypeHint();
}

/// Kein Rückschluss möglich (z.B. gemischter Text oder ein Pfad in JSON) —
/// die allgemeinen Operatoren, Freitext.
class UnknownTypeHint extends OperandTypeHint {
  const UnknownTypeHint();
}

class StringTypeHint extends OperandTypeHint {
  const StringTypeHint();
}

class NumberTypeHint extends OperandTypeHint {
  const NumberTypeHint();
}

class BooleanTypeHint extends OperandTypeHint {
  const BooleanTypeHint();
}

class DateTimeTypeHint extends OperandTypeHint {
  const DateTimeTypeHint();
}

class JsonTypeHint extends OperandTypeHint {
  const JsonTypeHint();
}

/// Datei, Bild oder Audio — alle sind Verweise auf eine Team-Datei.
class FileTypeHint extends OperandTypeHint {
  const FileTypeHint();
}

class TableTypeHint extends OperandTypeHint {
  const TableTypeHint();
}

/// Ein fest umrissener Wertevorrat (Entscheidungs-Prompt-`choices` oder
/// Dialogeingabe-`options` bei Auswahl/Radio) — der Gegenoperand wird auf
/// [values] beschränkt statt Freitext zu sein.
class EnumTypeHint extends OperandTypeHint {
  const EnumTypeHint(this.values);
  final List<String> values;
}

/// Nur ein isolierter `{{Name}}`-Ausdruck (die gesamte Eingabe, keine
/// Umgebungszeichen) lässt sich einem Wert zuordnen — exakt dieselbe Regel
/// wie beim `resolveValue` des Backend-Resolvers, da nur dort der rohe
/// typisierte Wert statt eines gerenderten Strings erhalten bleibt.
final _isolatedExpressionPattern = RegExp(
  r'^\{\{\s*([a-zA-Z_][\w]*(?:\.[a-zA-Z_][\w]*|\.\d+)*)\s*\}\}$',
);

OperandTypeHint operandTypeHintFor(String expression, WorkflowGraph graph) {
  final match = _isolatedExpressionPattern.firstMatch(expression.trim());
  if (match == null) return _literalTypeHint(expression.trim());
  final segments = match.group(1)!.split('.');
  // Ein Pfad führt in den JSON-Inhalt eines Werts; dessen Typ ist unbekannt.
  if (segments.length > 1) return const UnknownTypeHint();
  return _valueTypeHintFor(segments.single, graph) ?? const UnknownTypeHint();
}

/// Reines Literal ohne `{{}}` — Zahl/Boolean werden ad-hoc aus der
/// Zeichenkette selbst erkannt, keine Deklaration nötig.
OperandTypeHint _literalTypeHint(String literal) {
  if (literal.isEmpty) return const UnknownTypeHint();
  if (num.tryParse(literal) != null) return const NumberTypeHint();
  final lower = literal.toLowerCase();
  if (lower == 'true' || lower == 'false') return const BooleanTypeHint();
  return const StringTypeHint();
}

/// Sucht den Wert mit diesem Namen im ganzen Graphen; sein Schlüssel und die
/// Konfiguration des Bausteins bestimmen den Typ ([outputTypeOf]).
OperandTypeHint? _valueTypeHintFor(String name, WorkflowGraph graph) {
  for (final node in _allNodesIn(graph)) {
    final key = _keyOfOutputNamed(node, name);
    if (key == null) continue;
    return _choiceHintFor(node.config, key) ??
        _hintForType(outputTypeOf(node.config, key));
  }
  return null;
}

/// Entscheidungs-Prompt (Hauptwert) und Dialog-Auswahlfelder sind fachlich
/// ein Enum, kein Text und kein Wahrheitswert (auch bei genau zwei Werten).
EnumTypeHint? _choiceHintFor(NodeConfig config, String key) {
  switch (config) {
    case PromptNodeConfig(outputType: PromptOutputType.decision, :final choices)
        when key == WorkflowOutput.primaryOutputKey:
      return EnumTypeHint(choices);
    case DialogInputNodeConfig(:final fields):
      for (final field in fields) {
        if (field.name.trim() != key) continue;
        if (field.type == DialogInputFieldType.selection ||
            field.type == DialogInputFieldType.radio) {
          return EnumTypeHint(field.options);
        }
      }
    default:
      break;
  }
  return null;
}

OperandTypeHint _hintForType(NodeOutputType type) {
  return switch (type) {
    NodeOutputType.string => const StringTypeHint(),
    NodeOutputType.number => const NumberTypeHint(),
    NodeOutputType.boolean => const BooleanTypeHint(),
    NodeOutputType.datetime => const DateTimeTypeHint(),
    NodeOutputType.json => const JsonTypeHint(),
    NodeOutputType.file ||
    NodeOutputType.media ||
    NodeOutputType.audio => const FileTypeHint(),
    NodeOutputType.table => const TableTypeHint(),
  };
}

String? _keyOfOutputNamed(WorkflowNode node, String name) {
  for (final output in node.outputs) {
    if (output.name.trim() == name) return output.key;
  }
  return null;
}

Iterable<WorkflowNode> _allNodesIn(WorkflowGraph graph) sync* {
  for (final node in graph.nodes) {
    yield node;
    switch (node.config) {
      case ConditionalNodeConfig(:final branches):
        for (final branch in branches) {
          yield* _allNodesIn(branch.graph);
        }
      case ForEachNodeConfig(:final graph):
        yield* _allNodesIn(graph);
      default:
        break;
    }
  }
}
