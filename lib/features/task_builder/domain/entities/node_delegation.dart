import 'skill_attachment.dart';

/// Ein Baustein delegiert entweder an einen **Mitarbeiter** (dessen
/// Fähigkeiten er dann implizit erhält) oder trägt **eigene Fähigkeiten** —
/// nie beides. Diese Funktion setzt die Regel für alle Configs durch: Wer
/// zuletzt etwas Konkretes angibt, gewinnt. Ein Mitarbeiter leert die
/// Fähigkeiten, eine nicht leere Fähigkeitenliste entfernt den Mitarbeiter.
typedef NodeDelegation = ({
  String? employeeId,
  List<SkillAttachment> skillAttachments,
});

NodeDelegation resolveNodeDelegation({
  required String? currentEmployeeId,
  required List<SkillAttachment> currentSkills,
  String? employeeId,
  bool clearEmployee = false,
  List<SkillAttachment>? skillAttachments,
}) {
  if (employeeId != null) {
    return (
      employeeId: employeeId,
      skillAttachments: skillAttachments ?? const [],
    );
  }
  final skills = skillAttachments ?? currentSkills;
  if (clearEmployee) return (employeeId: null, skillAttachments: skills);
  if (skillAttachments != null && skillAttachments.isNotEmpty) {
    return (employeeId: null, skillAttachments: skillAttachments);
  }
  return (employeeId: currentEmployeeId, skillAttachments: skills);
}

/// Für Altdaten, die beides tragen: Der Mitarbeiter gewinnt.
NodeDelegation normalizedNodeDelegation({
  required String? employeeId,
  required List<SkillAttachment> skillAttachments,
}) {
  if (employeeId != null) {
    return (employeeId: employeeId, skillAttachments: const []);
  }
  return (employeeId: null, skillAttachments: skillAttachments);
}
