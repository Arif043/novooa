import 'package:equatable/equatable.dart';

/// Wozu ein wartender Lauf dich auffordert.
sealed class RunInteraction extends Equatable {
  const RunInteraction(this.instruction);

  final String instruction;

  @override
  List<Object?> get props => [instruction];
}

/// Freigeben oder ablehnen.
final class ApprovalRequest extends RunInteraction {
  const ApprovalRequest(super.instruction);
}

/// Ein Formular (Baustein „Formulareingabe“).
final class FormRequest extends RunInteraction {
  const FormRequest(super.instruction, this.fields);

  final List<FormFieldSpec> fields;

  @override
  List<Object?> get props => [instruction, fields];
}

enum FormFieldType {
  string,
  number,
  integer,
  decimal,
  selection,
  boolean,
  radio,

  /// Ein Bild als hochgeladene Team-Datei; die Vorlage kann es noch nicht.
  image,
}

class FormFieldSpec extends Equatable {
  const FormFieldSpec({
    required this.name,
    required this.type,
    this.options = const [],
  });

  final String name;
  final FormFieldType type;
  final List<String> options;

  bool get isNumeric =>
      type == FormFieldType.number ||
      type == FormFieldType.integer ||
      type == FormFieldType.decimal;

  bool get isSupported => type != FormFieldType.image;

  @override
  List<Object?> get props => [name, type, options];
}
