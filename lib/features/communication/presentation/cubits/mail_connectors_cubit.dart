import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../domain/entities/mail_connector.dart';
import '../../domain/usecases/begin_microsoft_connection.dart';
import '../../domain/usecases/watch_mail_connectors.dart';
import 'mail_connectors_state.dart';

class MailConnectorsCubit extends Cubit<MailConnectorsState> {
  MailConnectorsCubit(this._watchConnectors, this._beginMicrosoftConnection)
    : super(const MailConnectorsState());

  final WatchMailConnectors _watchConnectors;
  final BeginMicrosoftConnection _beginMicrosoftConnection;
  StreamSubscription<List<MailConnector>>? _subscription;

  void load() {
    emit(const MailConnectorsState());
    _subscription?.cancel();
    _subscription = _watchConnectors().listen(
      _emitConnectors,
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

  void _emitConnectors(List<MailConnector> connectors) {
    if (!isClosed) {
      emit(
        state.copyWith(
          status: MailConnectorsLoadStatus.ready,
          connectors: connectors,
        ),
      );
    }
  }

  void _emitFailure(String message) {
    if (!isClosed) {
      emit(
        state.copyWith(
          status: MailConnectorsLoadStatus.failure,
          isConnecting: false,
          message: message,
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
