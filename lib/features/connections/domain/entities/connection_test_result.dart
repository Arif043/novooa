import 'package:equatable/equatable.dart';

/// Ergebnis von „Verbindung testen“ — [message] ist fertig formuliert.
class ConnectionTestResult extends Equatable {
  const ConnectionTestResult({required this.ok, required this.message});

  final bool ok;
  final String message;

  @override
  List<Object?> get props => [ok, message];
}
