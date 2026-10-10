import '../../domain/entities/node_config.dart';
import '../../domain/entities/workflow_graph.dart';
import '../../domain/entities/task_execution_result.dart';
import '../../domain/entities/workflow_node.dart';
import '../../domain/entities/workflow_node_outputs.dart';

/// Grobe, rein UI-seitige Typ-Einschätzung eines Operanden (Template-
/// Ausdruck oder Literal) innerhalb einer [ComparisonCondition] — steuert
/// nur, welche [ComparisonOperator]s vorgeschlagen werden und ob der
/// Gegenoperand frei eingebbar bleibt oder auf feste Werte beschränkt wird.
/// Die Persistenz selbst bleibt typ-agnostisch (siehe `branch_condition.dart`).
sealed class OperandTypeHint {
  const OperandTypeHint();
}

/// Kein Rückschluss möglich (z.B. Referenz auf einen untypisierten
/// Baustein-Output oder gemischter Text) — volle Operatorliste, Freitext.
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

/// Ein fest umrissener Wertevorrat (Entscheidungs-Prompt-`choices` oder
/// Dialogeingabe-`options` bei Auswahl/Radio) — Operator ist immer "ist",
/// der Gegenoperand wird auf [values] beschränkt statt Freitext zu sein.
class EnumTypeHint extends OperandTypeHint {
  const EnumTypeHint(this.values);
  final List<String> values;
}

/// Nur ein isolierter `{{knoten(.feld)}}`-Ausdruck (die gesamte Eingabe,
/// keine Umgebungszeichen) lässt sich einer bekannten Feld-/Choice-Quelle
/// zuordnen — exakt dieselbe Regel wie beim `resolveValue` des
/// Backend-Resolvers (`isolatedExpressionPattern`), da nur dort der rohe
/// typisierte Wert statt eines gerenderten Strings erhalten bleibt.
final _isolatedExpressionPattern = RegExp(
  r'^\{\{\s*([a-zA-Z_][\w]*(?:\.[a-zA-Z_][\w]*|\.\d+)*)\s*\}\}$',
);

OperandTypeHint operandTypeHintFor(String expression, WorkflowGraph graph) {
  final match = _isolatedExpressionPattern.firstMatch(expression.trim());
  if (match == null) return _literalTypeHint(expression.trim());
  final segments = match.group(1)!.split('.');
  return _fieldTypeHintFor(segments.first, graph) ??
      (segments.length == 1
          ? _decisionTypeHintFor(segments.first, graph)
          : null) ??
      const UnknownTypeHint();
}

List<ComparisonOperator> operatorsFor(OperandTypeHint hint) {
  return switch (hint) {
    EnumTypeHint() => const [ComparisonOperator.equals],
    NumberTypeHint() => const [
      ComparisonOperator.equals,
      ComparisonOperator.notEquals,
      ComparisonOperator.greaterThan,
      ComparisonOperator.greaterThanOrEqual,
      ComparisonOperator.lessThan,
      ComparisonOperator.lessThanOrEqual,
    ],
    BooleanTypeHint() => const [
      ComparisonOperator.equals,
      ComparisonOperator.notEquals,
    ],
    StringTypeHint() => const [
      ComparisonOperator.equals,
      ComparisonOperator.notEquals,
      ComparisonOperator.contains,
    ],
    UnknownTypeHint() => ComparisonOperator.values,
  };
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

/// Strukturierte Prompt-/Dialogeingabe-Felder leben in einem flachen,
/// knotennamenlosen Namensraum (siehe `template-expression-resolver.ts`
/// `hasFlatOutputs`) — adressiert also über den bloßen Feldnamen, nicht
/// `{{knoten.feld}}`.
OperandTypeHint? _fieldTypeHintFor(String name, WorkflowGraph graph) {
  for (final node in _allNodesIn(graph)) {
    switch (node.config) {
      case PromptNodeConfig(
        outputType: PromptOutputType.structured,
        :final structuredFields,
      ):
        for (final field in structuredFields) {
          if (field.name.trim() == name)
            return _structuredFieldHint(field.type);
        }
      case DialogInputNodeConfig(:final fields):
        for (final field in fields) {
          if (field.name.trim() == name) return _dialogFieldHint(field);
        }
      case final ScriptNodeConfig config:
        for (final output in scriptWorkflowOutputsOf(config)) {
          if (output.name == name) return _scriptOutputHint(output.type);
        }
      default:
        break;
    }
  }
  return null;
}

OperandTypeHint _scriptOutputHint(NodeOutputType type) {
  return switch (type) {
    NodeOutputType.string => const StringTypeHint(),
    NodeOutputType.number => const NumberTypeHint(),
    NodeOutputType.boolean => const BooleanTypeHint(),
    _ => const UnknownTypeHint(),
  };
}

OperandTypeHint _structuredFieldHint(StructuredFieldType type) {
  return switch (type) {
    StructuredFieldType.number => const NumberTypeHint(),
    StructuredFieldType.boolean => const BooleanTypeHint(),
    StructuredFieldType.string => const StringTypeHint(),
  };
}

OperandTypeHint _dialogFieldHint(DialogInputField field) {
  return switch (field.type) {
    DialogInputFieldType.number ||
    DialogInputFieldType.integer ||
    DialogInputFieldType.decimal => const NumberTypeHint(),
    DialogInputFieldType.boolean => const BooleanTypeHint(),
    DialogInputFieldType.selection ||
    DialogInputFieldType.radio => EnumTypeHint(field.options),
    DialogInputFieldType.string => const StringTypeHint(),
  };
}

/// Ein Entscheidungs-Prompt hat keinen Feldnamen, sondern adressiert sich
/// über den Namen seines Hauptwerts — fachlich ein Enum aus den vom Nutzer
/// definierten `choices`, kein Wahrheitswert (auch bei genau zwei Choices).
OperandTypeHint? _decisionTypeHintFor(String valueName, WorkflowGraph graph) {
  for (final node in _allNodesIn(graph)) {
    if (node.primaryOutputName != valueName) continue;
    if (node.config case PromptNodeConfig(
      outputType: PromptOutputType.decision,
      :final choices,
    )) {
      return EnumTypeHint(choices);
    }
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
