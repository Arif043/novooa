import 'dart:async';

/// Meldet, dass die Runtime die Sitzung dieser App nicht mehr anerkennt —
/// abgelaufen, von einem anderen Gerät abgemeldet oder widerrufen.
///
/// Entkoppelt die Stelle, die das bemerkt (jede beliebige API-Anfrage), von
/// der, die darauf reagiert (die Verbindungssteuerung, die zur Anmeldung
/// zurückkehrt).
class RuntimeSessionEvents {
  final StreamController<void> _sessionEnded =
      StreamController<void>.broadcast();

  Stream<void> get sessionEnded => _sessionEnded.stream;

  void reportSessionEnded() {
    if (!_sessionEnded.isClosed) _sessionEnded.add(null);
  }

  Future<void> close() => _sessionEnded.close();
}
