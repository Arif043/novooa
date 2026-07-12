import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../domain/entities/communication_channel.dart';
import '../../domain/entities/create_communication_channel_input.dart';
import '../../domain/usecases/create_communication_channel.dart';
import '../../domain/usecases/delete_communication_channel.dart';
import '../../domain/usecases/watch_communication_channels.dart';
import 'communication_state.dart';

class CommunicationCubit extends Cubit<CommunicationState> {
  CommunicationCubit(
    this._watchChannels,
    this._createChannel,
    this._deleteChannel,
  ) : super(const CommunicationState());

  final WatchCommunicationChannels _watchChannels;
  final CreateCommunicationChannel _createChannel;
  final DeleteCommunicationChannel _deleteChannel;
  StreamSubscription<List<CommunicationChannel>>? _subscription;

  void load() {
    emit(const CommunicationState());
    _subscription?.cancel();
    _subscription = _watchChannels().listen(
      _emitChannels,
      onError: (_) => _emitFailure('Kanäle konnten nicht geladen werden.'),
    );
  }

  Future<void> create(CreateCommunicationChannelInput input) async {
    if (!input.isValid) return _emitFailure('Bitte fülle alle Pflichtfelder.');
    emit(state.copyWith(isCreating: true, message: null));
    try {
      await _createChannel(input);
      if (!isClosed) {
        emit(state.copyWith(isCreating: false, message: 'Kanal erstellt.'));
      }
    } catch (_) {
      _emitFailure('Kanal konnte nicht erstellt werden.');
    }
  }

  Future<void> delete(CommunicationChannel channel) async {
    try {
      await _deleteChannel(channel.id);
      if (!isClosed) {
        emit(state.copyWith(message: 'Kanal entfernt.'));
      }
    } catch (_) {
      _emitFailure('Kanal konnte nicht entfernt werden.');
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
    emit(state.copyWith(status: status, isCreating: false, message: message));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
