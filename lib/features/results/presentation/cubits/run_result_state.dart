import '../../domain/entities/run_result.dart';

sealed class RunResultState {
  const RunResultState();
}

final class RunResultLoading extends RunResultState {
  const RunResultLoading();
}

final class RunResultError extends RunResultState {
  const RunResultError();
}

final class RunResultReady extends RunResultState {
  const RunResultReady({
    required this.result,
    this.rounds = const {},
    this.selectedNodeId,
  });

  final RunResult result;

  /// Gewählte Runde je Schleife (ab 0); fehlt eine, gilt die erste.
  final Map<String, int> rounds;

  /// Der Baustein, dessen Details offen sind.
  final String? selectedNodeId;

  int roundOf(String loopNodeId) => rounds[loopNodeId] ?? 0;

  RunResultReady copyWith({
    Map<String, int>? rounds,
    String? selectedNodeId,
    bool clearSelection = false,
  }) {
    return RunResultReady(
      result: result,
      rounds: rounds ?? this.rounds,
      selectedNodeId: clearSelection
          ? null
          : selectedNodeId ?? this.selectedNodeId,
    );
  }
}
