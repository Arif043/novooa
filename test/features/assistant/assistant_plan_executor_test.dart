import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/assistant/presentation/agent/assistant_plan_action.dart';
import 'package:syscat2/features/assistant/presentation/agent/assistant_plan_executor.dart';

void main() {
  test('führt Aktionen geordnet aus und nimmt sie rückwärts zurück', () async {
    final changes = <String>[];
    final execution =
        await const AssistantPlanExecutor(stepDelay: Duration.zero).execute([
          _Action('Erster Schritt', changes),
          _Action('Zweiter Schritt', changes),
        ]);

    expect(changes, ['Erster Schritt', 'Zweiter Schritt']);

    await execution.undo();

    expect(changes, [
      'Erster Schritt',
      'Zweiter Schritt',
      'undo Zweiter Schritt',
      'undo Erster Schritt',
    ]);
  });

  test('nimmt bereits ausgeführte Aktionen nach einem Fehler zurück', () async {
    final changes = <String>[];

    await expectLater(
      const AssistantPlanExecutor(
        stepDelay: Duration.zero,
      ).execute([_Action('Erster Schritt', changes), _FailingAction()]),
      throwsStateError,
    );

    expect(changes, ['Erster Schritt', 'undo Erster Schritt']);
  });
}

class _Action implements AssistantPlanAction {
  const _Action(this.label, this._changes);

  @override
  final String label;
  final List<String> _changes;

  @override
  Future<AssistantPlanUndo> execute() async {
    _changes.add(label);
    return _Undo(label, _changes);
  }
}

class _Undo implements AssistantPlanUndo {
  const _Undo(this._label, this._changes);

  final String _label;
  final List<String> _changes;

  @override
  Future<void> undo() async {
    _changes.add('undo $_label');
  }
}

class _FailingAction implements AssistantPlanAction {
  @override
  String get label => 'Fehlerhafter Schritt';

  @override
  Future<AssistantPlanUndo?> execute() {
    throw StateError('Fehler');
  }
}
