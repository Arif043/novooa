import 'package:equatable/equatable.dart';

/// Ein fachliches Thema aus dem Tag-Vokabular der Runtime, etwa „Tiere“ oder „Rechnungen“.
class ModelTag extends Equatable {
  const ModelTag({
    required this.key,
    this.parent,
    required this.labels,
    this.synonyms = const {},
  });

  final String key;

  /// Obertag; ein Modell mit `pets` gehört auch zum Thema `animals`.
  final String? parent;

  /// Sprachcode → Bezeichnung; `en` ist der Rückfall.
  final Map<String, String> labels;

  /// Sprachcode → weitere Suchbegriffe.
  final Map<String, List<String>> synonyms;

  @override
  List<Object?> get props => [key, parent, labels, synonyms];
}
