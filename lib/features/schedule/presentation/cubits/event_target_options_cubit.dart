import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../../communication/domain/entities/communication_channel.dart';
import '../../../communication/domain/usecases/watch_communication_channels.dart';
import '../../../files/domain/entities/team_file.dart';
import '../../../files/domain/entities/team_folder.dart';
import '../../../files/domain/usecases/watch_team_files.dart';
import '../../../files/domain/usecases/watch_team_folders.dart';
import '../../../teams/domain/usecases/get_current_team_id.dart';
import 'event_target_options_state.dart';

/// Liefert die Dateien, Verzeichnisse und Kanäle, aus denen die Zielwahl eines
/// Event-Triggers besteht. Kanäle sind optional: Nicht jede Betriebsvariante
/// kennt Kommunikationskanäle.
class EventTargetOptionsCubit extends Cubit<EventTargetOptionsState> {
  EventTargetOptionsCubit(
    this._watchTeamFiles,
    this._watchTeamFolders,
    this._watchChannels,
    this._getCurrentTeamId,
  ) : super(const EventTargetOptionsState());

  final WatchTeamFiles _watchTeamFiles;
  final WatchTeamFolders _watchTeamFolders;
  final WatchCommunicationChannels? _watchChannels;
  final GetCurrentTeamId _getCurrentTeamId;
  final List<StreamSubscription<Object?>> _subscriptions = [];

  Future<void> load() async {
    emit(const EventTargetOptionsState());
    await _cancelSubscriptions();
    try {
      final teamId = await _getCurrentTeamId();
      _listen<List<TeamFile>>(_watchTeamFiles(teamId), _onFiles);
      _listen<List<TeamFolder>>(_watchTeamFolders(teamId), _onFolders);
      final channels = _watchChannels;
      if (channels != null) {
        _listen<List<CommunicationChannel>>(channels(), _onChannels);
      }
    } catch (_) {
      _emitFailure();
    }
  }

  void _listen<T>(Stream<T> stream, void Function(T value) onData) {
    _subscriptions.add(stream.listen(onData, onError: (_) => _emitFailure()));
  }

  void _onFiles(List<TeamFile> files) {
    if (isClosed) return;
    emit(state.copyWith(status: EventTargetOptionsStatus.ready, files: files));
  }

  void _onFolders(List<TeamFolder> folders) {
    if (isClosed) return;
    emit(
      state.copyWith(status: EventTargetOptionsStatus.ready, folders: folders),
    );
  }

  void _onChannels(List<CommunicationChannel> channels) {
    if (isClosed) return;
    emit(state.copyWith(channels: channels));
  }

  void _emitFailure() {
    if (isClosed) return;
    emit(state.copyWith(status: EventTargetOptionsStatus.failure));
  }

  Future<void> _cancelSubscriptions() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
  }

  @override
  Future<void> close() async {
    await _cancelSubscriptions();
    return super.close();
  }
}
