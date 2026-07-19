/// Entwurf einer Fähigkeit für Create/Update — trägt nur den bearbeitbaren
/// Zustand aus dem Editor. Die ID vergibt das Repository.
class SkillDraft {
  const SkillDraft({
    required this.title,
    required this.description,
    required this.content,
  });

  final String title;
  final String description;
  final String content;
}
