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

/// Etwa ein Bild aufnehmen; das kann nur das offizielle Frontend.
final class UnsupportedRequest extends RunInteraction {
  const UnsupportedRequest(super.instruction);
}

enum FormFieldType {
  string,
  number,
  integer,
  decimal,
  selection,
  boolean,
  radio,
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

  @override
  List<Object?> get props => [name, type, options];
}
