import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../domain/entities/application_log.dart';
import '../../domain/usecases/watch_application_logs.dart';
import 'application_logs_state.dart';

class ApplicationLogsCubit extends Cubit<ApplicationLogsState> {
  ApplicationLogsCubit(this._watchApplicationLogs)
    : super(const ApplicationLogsLoading());

  final WatchApplicationLogs _watchApplicationLogs;
  StreamSubscription<List<ApplicationLog>>? _subscription;

  Future<void> load() async {
    emit(const ApplicationLogsLoading());
    await _subscription?.cancel();
    _subscription = _watchApplicationLogs().listen(
      _onLogs,
      onError: (error, stackTrace) => _onFailure(),
    );
  }

  void _onLogs(List<ApplicationLog> logs) {
    if (!isClosed) emit(ApplicationLogsReady(logs));
  }

  void _onFailure() {
    if (!isClosed) emit(const ApplicationLogsFailure());
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
