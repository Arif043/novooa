import 'package:equatable/equatable.dart';

/// Welches bereits verbundene Sprachmodell als Vorgabe für Sprachmodell-
/// Bausteine gilt ("Standardmodell verwenden"). `null` heißt: kein
/// Vorgabemodell gewählt, die bisherige systemseitige Vorgabe bleibt aktiv.
/// Das Modell des KI-Agenten legt die Cloud fest, nicht der Nutzer.
class LanguageModelDefaults extends Equatable {
  const LanguageModelDefaults({this.blockModelId});

  const LanguageModelDefaults.empty() : blockModelId = null;

  final String? blockModelId;

  @override
  List<Object?> get props => [blockModelId];
}
