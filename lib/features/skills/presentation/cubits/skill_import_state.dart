import 'package:equatable/equatable.dart';

import '../../domain/entities/skill_catalog.dart';
import '../../domain/entities/skill_import.dart';

enum SkillImportStep { chooseSource, loading, review, saving, done }

class SkillImportState extends Equatable {
  const SkillImportState({
    this.step = SkillImportStep.chooseSource,
    this.preview,
    this.selected = const {},
    this.audits = const [],
    this.importedCount = 0,
    this.message,
  });

  final SkillImportStep step;
  final SkillImportPreview? preview;

  /// Namen der Kandidaten, die übernommen werden.
  final Set<String> selected;

  /// Sicherheitsprüfungen des Katalog-Skills (leer bei anderen Quellen).
  final List<CatalogAudit> audits;
  final int importedCount;

  /// Fehler der letzten Aktion, in der Oberfläche über dem Schritt gezeigt.
  final String? message;

  bool get canCommit => step == SkillImportStep.review && selected.isNotEmpty;

  SkillImportState copyWith({
    SkillImportStep? step,
    SkillImportPreview? preview,
    Set<String>? selected,
    List<CatalogAudit>? audits,
    int? importedCount,
    String? message,
    bool clearMessage = false,
  }) {
    return SkillImportState(
      step: step ?? this.step,
      preview: preview ?? this.preview,
      selected: selected ?? this.selected,
      audits: audits ?? this.audits,
      importedCount: importedCount ?? this.importedCount,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [
    step,
    preview,
    selected,
    audits,
    importedCount,
    message,
  ];
}
