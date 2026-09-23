enum TaskRunMediaInputSource { gallery, camera }

class TaskRunMediaInput {
  const TaskRunMediaInput({this.documentScanEnabled = false});

  /// Vom Baustein „Bild anfordern“ gewünschter Dokumentenscan-Modus für
  /// diese Anfrage — siehe `MediaInputNodeConfig.documentScanEnabled`.
  final bool documentScanEnabled;
}
