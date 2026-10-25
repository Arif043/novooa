import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/task_run.dart';
import '../../domain/usecases/review_run.dart';

sealed class RunReviewState {
  const RunReviewState();
}

final class RunReviewIdle extends RunReviewState {
  const RunReviewIdle();
}

final class RunReviewSending extends RunReviewState {
  const RunReviewSending();
}

final class RunReviewSent extends RunReviewState {
  const RunReviewSent();
}

final class RunReviewFailed extends RunReviewState {
  const RunReviewFailed(this.failure);

  final RunReviewFailure failure;
}

/// Sendet eine Freigabe, Ablehnung oder ein ausgefülltes Formular.
class RunReviewCubit extends Cubit<RunReviewState> {
  RunReviewCubit(this._reviewRun) : super(const RunReviewIdle());

  final ReviewRun _reviewRun;

  Future<void> review(
    TaskRun run,
    RunReviewDecision decision, {
    Map<String, Object> formValues = const {},
  }) async {
    if (state is RunReviewSending) return;
    emit(const RunReviewSending());
    final runIdOrFailure = await _reviewRun(
      run,
      decision,
      formValues: formValues,
    );
    emit(
      runIdOrFailure.when((_) => const RunReviewSent(), RunReviewFailed.new),
    );
  }
}
