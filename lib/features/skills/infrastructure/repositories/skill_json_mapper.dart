import '../../domain/entities/skill.dart';
import '../../domain/entities/skill_catalog.dart';
import '../../domain/entities/skill_import.dart';

List<Object?> _items(Map<String, Object?> json, String what) {
  final items = json['items'];
  if (items is! List) {
    throw FormatException('$what konnten nicht gelesen werden.');
  }
  return items;
}

Map<String, Object?> _record(Object? value, String what) {
  if (value is! Map) throw FormatException('$what ist ungültig.');
  return value.cast<String, Object?>();
}

List<String> _strings(Object? value) => value is List
    ? value.whereType<String>().toList(growable: false)
    : const [];

Skill skillFromJson(Object? value) {
  final json = _record(value, 'Fähigkeit');
  return Skill(
    name: json['name'] as String? ?? '',
    description: json['description'] as String? ?? '',
    license: json['license'] as String?,
    compatibility: json['compatibility'] as String?,
    fileCount: (json['fileCount'] as num?)?.toInt() ?? 0,
    warnings: _strings(json['warnings']),
  );
}

List<Skill> skillsFromJson(Map<String, Object?> json) =>
    _items(json, 'Fähigkeiten').map(skillFromJson).toList(growable: false);

SkillImportPreview previewFromJson(Map<String, Object?> json) {
  final candidates = json['candidates'];
  final rejected = json['rejected'];
  final importId = json['importId'];
  if (candidates is! List || rejected is! List || importId is! String) {
    throw const FormatException('Die Importvorschau ist ungültig.');
  }
  return SkillImportPreview(
    importId: importId,
    candidates: candidates.map(_candidateFrom).toList(growable: false),
    rejected: rejected.map(_rejectionFrom).toList(growable: false),
  );
}

SkillImportCandidate _candidateFrom(Object? value) {
  final json = _record(value, 'Ein Importkandidat');
  return SkillImportCandidate(
    name: json['name'] as String? ?? '',
    description: json['description'] as String? ?? '',
    fileCount: (json['fileCount'] as num?)?.toInt() ?? 0,
    totalBytes: (json['totalBytes'] as num?)?.toInt() ?? 0,
    warnings: _strings(json['warnings']),
    nameTaken: json['nameTaken'] == true,
  );
}

SkillImportRejection _rejectionFrom(Object? value) {
  final json = _record(value, 'Eine Ablehnung');
  return SkillImportRejection(
    directory: json['directory'] as String? ?? '',
    reason: json['reason'] as String? ?? '',
  );
}

List<CatalogSkill> catalogSkillsFromJson(Map<String, Object?> json) => _items(
  json,
  'Katalogeinträge',
).map(_catalogSkillFrom).toList(growable: false);

CatalogPage catalogPageFromJson(Map<String, Object?> json) => CatalogPage(
  items: catalogSkillsFromJson(json),
  hasMore: json['hasMore'] == true,
);

CatalogSkill _catalogSkillFrom(Object? value) {
  final json = _record(value, 'Ein Katalogeintrag');
  return CatalogSkill(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    source: json['source'] as String? ?? '',
    installs: (json['installs'] as num?)?.toInt() ?? 0,
  );
}

List<CatalogAudit> auditsFromJson(Map<String, Object?> json) =>
    _items(json, 'Prüfungen').map(_auditFrom).toList(growable: false);

CatalogAudit _auditFrom(Object? value) {
  final json = _record(value, 'Eine Prüfung');
  return CatalogAudit(
    provider: json['provider'] as String? ?? '',
    status: switch (json['status']) {
      'pass' => CatalogAuditStatus.pass,
      'fail' => CatalogAuditStatus.fail,
      _ => CatalogAuditStatus.warn,
    },
    summary: json['summary'] as String? ?? '',
  );
}
