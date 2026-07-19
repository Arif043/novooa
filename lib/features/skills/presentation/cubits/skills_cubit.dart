import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:syscat2/features/auth/domain/repositories/auth_repository.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';
import 'package:syscat2/features/teams/domain/usecases/get_current_team_id.dart';

import '../../domain/entities/skill.dart';
import '../../domain/entities/skill_draft.dart';
import '../../domain/entities/skill_failure.dart';
import '../../domain/usecases/create_skill.dart';
import '../../domain/usecases/delete_skill.dart';
import '../../domain/usecases/load_skill_content.dart';
import '../../domain/usecases/update_skill.dart';
import '../../domain/usecases/watch_skills.dart';
import 'skills_state.dart';

/// Verwaltet die Fähigkeiten-Seite. CRUD läuft über Dialoge — die Seite
/// selbst zeigt nur eine Liste + Aktionen. Für das Bearbeiten wird der
/// SKILL.md-Inhalt aus Storage nachgeladen.
class SkillsCubit extends Cubit<SkillsState> {
  SkillsCubit(
    this._authRepository,
    this._watchSkills,
    this._loadSkillContent,
    this._createSkill,
    this._updateSkill,
    this._deleteSkill,
    this._getCurrentTeamId,
  ) : super(const SkillsState());

  final AuthRepository _authRepository;
  final WatchSkills _watchSkills;
  final LoadSkillContent _loadSkillContent;
  final CreateSkill _createSkill;
  final UpdateSkill _updateSkill;
  final DeleteSkill _deleteSkill;
  final GetCurrentTeamId _getCurrentTeamId;
  StreamSubscription<List<Skill>>? _subscription;

  Future<void> load() async {
    final teamId = await _teamIdOrNull();
    if (teamId == null) {
      return _emitFailure(SkillFailureKind.unauthenticated);
    }
    emit(const SkillsState());
    _subscription?.cancel();
    _subscription = _watchSkills(teamId).listen(
      _emitSkills,
      onError: (_) => _emitFailure(SkillFailureKind.loadFailed),
    );
  }

  Future<Skill?> loadContent(String skillId) async {
    final teamId = await _teamIdOrNull();
    if (teamId == null) {
      _emitFailure(SkillFailureKind.unauthenticated);
      return null;
    }
    final result = await _loadSkillContent(teamId: teamId, skillId: skillId);
    return result.when((skill) => skill, (failure) {
      _emitFailure(failure.kind);
      return null;
    });
  }

  Future<Skill?> createSkill(SkillDraft draft) async {
    final teamId = await _teamIdOrNull();
    if (teamId == null) {
      _emitFailure(SkillFailureKind.unauthenticated);
      return null;
    }
    final result = await _createSkill(teamId: teamId, draft: draft);
    return result.when(
      (skill) {
        emit(state.copyWith(message: 'Fähigkeit gespeichert.'));
        return skill;
      },
      (failure) {
        _emitFailure(failure.kind);
        return null;
      },
    );
  }

  Future<Skill?> updateSkill({
    required String skillId,
    required SkillDraft draft,
  }) async {
    final teamId = await _teamIdOrNull();
    if (teamId == null) {
      _emitFailure(SkillFailureKind.unauthenticated);
      return null;
    }
    final result = await _updateSkill(
      teamId: teamId,
      skillId: skillId,
      draft: draft,
    );
    return result.when(
      (skill) {
        emit(state.copyWith(message: 'Fähigkeit gespeichert.'));
        return skill;
      },
      (failure) {
        _emitFailure(failure.kind);
        return null;
      },
    );
  }

  Future<bool> deleteSkill(String skillId) async {
    final teamId = await _teamIdOrNull();
    if (teamId == null) {
      _emitFailure(SkillFailureKind.unauthenticated);
      return false;
    }
    final result = await _deleteSkill(teamId: teamId, skillId: skillId);
    return result.when(
      (_) {
        emit(state.copyWith(message: 'Fähigkeit gelöscht.'));
        return true;
      },
      (failure) {
        _emitFailure(failure.kind);
        return false;
      },
    );
  }

  void _emitSkills(List<Skill> skills) {
    if (isClosed) return;
    emit(
      state.copyWith(
        status: SkillsStatus.ready,
        skills: skills,
        clearMessage: true,
      ),
    );
  }

  Future<TeamId?> _teamIdOrNull() async {
    final user = _authRepository.currentUser();
    if (user == null) return null;
    try {
      return await _getCurrentTeamId();
    } catch (_) {
      return null;
    }
  }

  void _emitFailure(SkillFailureKind kind) {
    if (isClosed) return;
    emit(
      state.copyWith(
        status: SkillsStatus.failure,
        message: SkillFailure(kind).message,
      ),
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
