import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:syscat2/core/logging/logger.dart';

import '../../domain/usecases/save_file_version_limit.dart';
import '../../domain/usecases/watch_file_version_limit.dart';
import 'file_settings_state.dart';

class FileSettingsCubit extends Cubit<FileSettingsState> {
  FileSettingsCubit(this._watchVersionLimit, this._saveVersionLimit)
    : super(const FileSettingsLoading());

  final WatchFileVersionLimit _watchVersionLimit;
  final SaveFileVersionLimit _saveVersionLimit;

  StreamSubscription<int>? _subscription;

  Future<void> load() async {
    await _subscription?.cancel();
    emit(const FileSettingsLoading());
    _subscription = _watchVersionLimit().listen(
      (limit) => emit(FileSettingsReady(versionLimit: limit)),
      onError: (Object error, StackTrace stackTrace) {
        _log('Dateieinstellungen konnten nicht geladen werden.', error, stackTrace);
        emit(
          const FileSettingsFailure(
            'Dateieinstellungen konnten nicht geladen werden.',
          ),
        );
      },
    );
  }

  Future<void> saveVersionLimit(int limit) async {
    final current = state;
    if (current is! FileSettingsReady) return;
    emit(current.copyWith(isSaving: true));
    try {
      await _saveVersionLimit(limit);
    } catch (error, stackTrace) {
      _log('Versionslimit konnte nicht gespeichert werden.', error, stackTrace);
      if (!isClosed) {
        emit(
          current.copyWith(
            message: 'Versionslimit konnte nicht gespeichert werden.',
          ),
        );
      }
    }
  }

  void _log(String message, Object error, StackTrace stackTrace) {
    logException(
      message: message,
      error: error,
      stackTrace: stackTrace,
      name: 'file_settings',
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
