import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/entities/unique_id.dart';
import 'package:syscat2/features/application_logs/domain/entities/application_log.dart';
import 'package:syscat2/features/application_logs/domain/repositories/application_log_repository.dart';
import 'package:syscat2/features/application_logs/domain/usecases/watch_application_logs.dart';
import 'package:syscat2/features/application_logs/presentation/cubits/application_logs_cubit.dart';
import 'package:syscat2/features/application_logs/presentation/cubits/application_logs_state.dart';

void main() {
  test('load stellt lokale Anwendungseintraege bereit', () async {
    final cubit = ApplicationLogsCubit(
      WatchApplicationLogs(_LogRepositoryFake(Stream.value([_log]))),
    );

    await cubit.load();
    await Future<void>.delayed(Duration.zero);

    final state = cubit.state as ApplicationLogsReady;
    expect(state.logs, [_log]);
    await cubit.close();
  });

  test('load meldet einen Fehler aus dem Protokollstream', () async {
    final cubit = ApplicationLogsCubit(
      WatchApplicationLogs(
        _LogRepositoryFake(Stream.error(StateError('Fehler'))),
      ),
    );

    await cubit.load();
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state, isA<ApplicationLogsFailure>());
    await cubit.close();
  });
}

final _log = ApplicationLog(
  id: UniqueId('log-1'),
  level: ApplicationLogLevel.info,
  source: ApplicationLogSource.runtime,
  event: 'task_run.started',
  data: {'runId': 'run-1'},
  occurredAt: DateTime(2026, 9, 9),
);

class _LogRepositoryFake implements ApplicationLogRepository {
  const _LogRepositoryFake(this.stream);

  final Stream<List<ApplicationLog>> stream;

  @override
  Stream<List<ApplicationLog>> watchRecent() => stream;
}
