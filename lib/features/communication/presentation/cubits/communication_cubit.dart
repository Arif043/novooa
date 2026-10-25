import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../domain/entities/communication_channel.dart';
import '../../domain/usecases/begin_microsoft_connection.dart';
import '../../domain/usecases/watch_communication_channels.dart';
import 'communication_state.dart';

class CommunicationCubit extends Cubit<CommunicationState> {
  CommunicationCubit(this._watchChannels, this._beginMicrosoftConnection)
    : super(const CommunicationState());

  final WatchCommunicationChannels _watchChannels;
  final BeginMicrosoftConnection _beginMicrosoftConnection;
  StreamSubscription<List<CommunicationChannel>>? _subscription;

  void load() {
    emit(const CommunicationState());
    _subscription?.cancel();
    _subscription = _watchChannels().listen(
      _emitChannels,
      onError: (_) => _emitFailure('Postfächer konnten nicht geladen werden.'),
    );
  }

  Future<String?> beginMicrosoftConnection() async {
    emit(state.copyWith(isConnecting: true, message: null));
    try {
      final authorizationUrl = await _beginMicrosoftConnection();
      if (!isClosed) emit(state.copyWith(isConnecting: false));
      return authorizationUrl;
    } catch (_) {
      _emitFailure('Microsoft-Anmeldung konnte nicht gestartet werden.');
      return null;
    }
  }

  void _emitChannels(List<CommunicationChannel> channels) {
    if (isClosed) return;
    emit(
      state.copyWith(
        status: CommunicationLoadStatus.ready,
        channels: channels,
        message: null,
      ),
    );
  }

  void _emitFailure(String message) {
    if (isClosed) return;
    final status = state.channels.isEmpty
        ? CommunicationLoadStatus.failure
        : state.status;
    emit(state.copyWith(status: status, isConnecting: false, message: message));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
