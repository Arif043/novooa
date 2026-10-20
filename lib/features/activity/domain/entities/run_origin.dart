/// Woher ein Lauf kommt: von Hand gestartet (Name der Person) oder durch einen
/// Auslöser; dazu, wer eine Freigabe oder ein Formular beantwortet hat.
/// Gelöschte Konten erscheinen ohne Namen.
class RunOrigin {
  const RunOrigin({this.startedBy, this.reviewedBy, this.triggerType});

  static const unknown = RunOrigin();

  final String? startedBy;
  final String? reviewedBy;

  /// `schedule` oder `event` (auch Webhooks); `null` bei manuellem Start.
  final String? triggerType;

  bool get isKnown =>
      startedBy != null || reviewedBy != null || triggerType != null;
}
