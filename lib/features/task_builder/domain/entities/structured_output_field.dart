part of 'node_config.dart';

/// Der Werttyp eines Ergebnisfelds — steuert das Ausgabeschema im Backend
/// (`structuredSchemaFor`, `teamworkSchemaFor`) und den Typ des
/// Workflow-Ausgabewerts. [file] gibt es nur bei der Teamarbeit: Das Feld
/// verweist dann auf eine Textdatei, die das Team geschrieben hat.
enum StructuredFieldType { string, number, boolean, datetime, json, file }

/// Textformate, die Agenten als Ergebnisdatei schreiben können.
enum OutputFileFormat { markdown, csv, json, text }

class StructuredOutputField extends Equatable {
  const StructuredOutputField({
    required this.name,
    required this.description,
    this.type = StructuredFieldType.string,
    this.fileFormat = OutputFileFormat.markdown,
  });

  final String name;
  final String description;
  final StructuredFieldType type;

  /// Nur bei [StructuredFieldType.file] von Bedeutung.
  final OutputFileFormat fileFormat;

  StructuredOutputField copyWith({
    String? name,
    String? description,
    StructuredFieldType? type,
    OutputFileFormat? fileFormat,
  }) {
    return StructuredOutputField(
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      fileFormat: fileFormat ?? this.fileFormat,
    );
  }

  @override
  List<Object?> get props => [name, description, type, fileFormat];
}
