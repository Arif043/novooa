enum TaskRunMediaInputSource {
  gallery,
  camera;

  static TaskRunMediaInputSource fromName(String value) {
    return values.firstWhere(
      (source) => source.name == value,
      orElse: () => TaskRunMediaInputSource.gallery,
    );
  }

  String get actionLabel {
    return this == TaskRunMediaInputSource.camera
        ? 'Kamera öffnen'
        : 'Bild auswählen';
  }
}

class TaskRunMediaInput {
  const TaskRunMediaInput({required this.source});

  final TaskRunMediaInputSource source;
}
