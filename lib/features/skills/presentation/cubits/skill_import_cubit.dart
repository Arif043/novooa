import 'package:bloc/bloc.dart';

import '../../domain/entities/skill_failure.dart';
import '../../domain/entities/skill_import.dart';
import 'package:multiple_result/multiple_result.dart';
import '../../domain/repositories/skill_source_gateway.dart';
import '../../domain/usecases/skill_catalog_use_cases.dart';
import '../../domain/usecases/skill_import_use_cases.dart';
import 'skill_import_state.dart';

/// Ablauf des Imports: Quelle wählen → Vorschau der gefundenen Skills →
/// Auswahl übernehmen. Die Vorschau speichert noch nichts.
class SkillImportCubit extends Cubit<SkillImportState> {
  SkillImportCubit(this._preview, this._commit, this._loadAudits, this._gateway)
    : super(const SkillImportState());

  final PreviewSkillImport _preview;
  final CommitSkillImport _commit;
  final LoadSkillAudits _loadAudits;
  final SkillSourceGateway _gateway;

  bool get canPickFolder => _gateway.canPickFolder;

  Future<void> start(SkillImportSource source) async {
    emit(const SkillImportState(step: SkillImportStep.loading));
    final result = await _preview(source);
    if (isClosed) return;
    result.when(
      (preview) => _showPreview(preview, source),
      (failure) => emit(SkillImportState(message: failure.message)),
    );
  }

  Future<void> startFromGitHub(String url) =>
      start(GitHubImportSource(url.trim()));

  Future<void> startFromCatalog(String id) => start(CatalogImportSource(id));

  Future<void> pickArchive() => _startFromPick(_gateway.pickArchive());

  Future<void> pickFolder() => _startFromPick(_gateway.pickFolder());

  Future<void> _startFromPick(
    Future<Result<SkillImportSource, SkillFailure>> picked,
  ) async {
    final result = await picked;
    if (isClosed) return;
    switch (result) {
      case Success(:final success):
        await start(success);
      case Error(:final error) when error.isCancelled:
        break;
      case Error(:final error):
        emit(SkillImportState(message: error.message));
    }
  }

  void toggle(String name) {
    final selected = {...state.selected};
    if (!selected.remove(name)) selected.add(name);
    emit(state.copyWith(selected: selected));
  }

  void selectAll(bool all) {
    final names = state.preview?.candidates.map((c) => c.name) ?? const [];
    emit(state.copyWith(selected: all ? names.toSet() : <String>{}));
  }

  Future<void> commit() async {
    final preview = state.preview;
    if (preview == null || !state.canCommit) return;
    emit(state.copyWith(step: SkillImportStep.saving, clearMessage: true));
    final result = await _commit(preview.importId, state.selected.toList());
    if (isClosed) return;
    result.when(
      (skills) => emit(
        state.copyWith(
          step: SkillImportStep.done,
          importedCount: skills.length,
        ),
      ),
      (failure) => emit(
        state.copyWith(step: SkillImportStep.review, message: failure.message),
      ),
    );
  }

  void restart() => emit(const SkillImportState());

  void _showPreview(SkillImportPreview preview, SkillImportSource source) {
    emit(
      SkillImportState(
        step: SkillImportStep.review,
        preview: preview,
        selected: preview.candidates.map((c) => c.name).toSet(),
        message: preview.candidates.isEmpty
            ? 'Es wurde kein importierbarer Skill gefunden.'
            : null,
      ),
    );
    if (source is CatalogImportSource) _loadAuditsFor(source.id);
  }

  Future<void> _loadAuditsFor(String id) async {
    final result = await _loadAudits(id);
    if (isClosed) return;
    result.when((audits) => emit(state.copyWith(audits: audits)), (_) {});
  }
}
