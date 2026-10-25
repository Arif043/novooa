import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:__DASHBOARD_PACKAGE__/features/runs/domain/entities/task_run.dart';
import 'package:__DASHBOARD_PACKAGE__/features/runs/domain/usecases/review_run.dart';
import 'package:__DASHBOARD_PACKAGE__/features/runs/domain/usecases/watch_runs.dart';
import 'package:__DASHBOARD_PACKAGE__/features/runs/presentation/cubits/run_review_cubit.dart';
import 'package:__DASHBOARD_PACKAGE__/features/runs/presentation/cubits/runs_cubit.dart';

import 'fakes.dart';

void main() {
  test('zeigt Läufe live und begrenzt ihre Zahl', () async {
    final repository = FakeRunRepository();
    final cubit = RunsCubit(
      WatchRuns(repository, isOffered: (_) => true, limit: 1),
    )..load();

    repository.runs.add([waitingRun(), waitingRun()]);
    await pumpEventQueue();

    expect((cubit.state as RunsLoaded).runs, hasLength(1));
    await cubit.close();
  });

  test('gibt einen wartenden Lauf frei', () async {
    final repository = FakeRunRepository();
    final cubit = RunReviewCubit(ReviewRun(repository));

    await cubit.review(waitingRun(), RunReviewDecision.approve);

    expect(repository.reviews.single.$2, RunReviewDecision.approve);
    expect(cubit.state, isA<RunReviewSent>());
    await cubit.close();
  });

  test('sendet Formularwerte mit', () async {
    final repository = FakeRunRepository();
    final cubit = RunReviewCubit(ReviewRun(repository));

    await cubit.review(
      waitingRun(),
      RunReviewDecision.approve,
      formValues: const {'betrag': 12.5},
    );

    expect(repository.reviews.single.$3, {'betrag': 12.5});
    await cubit.close();
  });

  test('meldet eine gescheiterte Freigabe', () async {
    final repository = FakeRunRepository()
      ..reviewResult = const Error(RunReviewFailure.unreachable);
    final cubit = RunReviewCubit(ReviewRun(repository));

    await cubit.review(waitingRun(), RunReviewDecision.reject);

    expect(
      (cubit.state as RunReviewFailed).failure,
      RunReviewFailure.unreachable,
    );
    await cubit.close();
  });
}
