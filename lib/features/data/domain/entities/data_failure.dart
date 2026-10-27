import 'package:equatable/equatable.dart';

enum DataFailureKind {
  /// Eine andere Sammlung trägt den Namen schon.
  nameTaken,
  notFound,

  /// Die Datei überschreitet die Importgrenze.
  tooLarge,

  /// Die Datei ist weder CSV noch JSON oder enthält Fehler.
  invalidFile,

  /// Die Dateiauswahl oder das Speichern wurde abgebrochen.
  cancelled,
  failed,
}

/// Fehler der Sammlungsverwaltung und des Datenaustauschs; übersetzt wird in `presentation/`.
class DataFailure extends Equatable {
  const DataFailure(this.kind, [this.detail]);

  final DataFailureKind kind;

  /// Meldung der Runtime, falls vorhanden — nur für unbekannte Fehler gezeigt.
  final String? detail;

  @override
  List<Object?> get props => [kind, detail];
}
