enum TaskRunDialogInputFieldType {
  string,
  number,
  integer,
  decimal,
  selection,
  boolean,
  radio,

  /// Wert ist beim Absenden die `fileId` des hochgeladenen Bilds.
  image;

  static TaskRunDialogInputFieldType fromName(String value) {
    return values.firstWhere(
      (type) => type.name == value,
      orElse: () => TaskRunDialogInputFieldType.string,
    );
  }

  bool get needsOptions {
    return this == TaskRunDialogInputFieldType.selection ||
        this == TaskRunDialogInputFieldType.radio;
  }
}

class TaskRunDialogInputField {
  const TaskRunDialogInputField({
    required this.name,
    required this.type,
    required this.options,
  });

  final String name;
  final TaskRunDialogInputFieldType type;
  final List<String> options;
}
