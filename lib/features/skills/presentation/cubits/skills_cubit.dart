import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:syscat2/core/logging/logger.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';
import 'package:syscat2/features/teams/domain/usecases/get_current_team_id.dart';

import '../../domain/entities/skill.dart';
import '../../domain/entities/skill_failure.dart';
import '../../domain/usecases/delete_skill.dart';
import '../../domain/usecases/load_skills_location.dart';
import '../../domain/usecases/watch_skills.dart';
import 'skills_state.dart';

/// Zeigt den Skills-Ordner des Nutzers: die gefundenen Skills, den Pfad des
/// Ordners und das Löschen. Neue Skills kommen über den Import oder von Hand
/// in den Ordner; „Neu einlesen" ([load]) liest ihn erneut.
class SkillsCubit extends Cubit<SkillsState> {
  SkillsCubit(
    this._watchSkills,
    this._deleteSkill,
    this._loadLocation,
    this._getCurrentTeamId,
  ) : super(const SkillsState());

  final WatchSkills _watchSkills;
  final DeleteSkill _deleteSkill;
  final LoadSkillsLocation _loadLocation;
  final GetCurrentTeamId _getCurrentTeamId;
  StreamSubscription<List<Skill>>? _subscription;

  Future<void> load() async {
    emit(const SkillsState());
    await _subscription?.cancel();
    final teamId = await _teamIdOrNull();
    if (teamId == null) return;
    _subscription = _watchSkills(teamId).listen(
      _emitSkills,
      onError: (Object error, StackTrace stackTrace) {
        logException(
          message: 'Fähigkeiten konnten nicht geladen werden.',
          error: error,
          stackTrace: stackTrace,
          name: 'skills',
        );
        _emitFailure(SkillFailure.loadFailed.message);
      },
    );
    await _loadFolderLocation();
  }

  Future<void> delete(String name) async {
    final result = await _deleteSkill(name);
    if (isClosed) return;
    result.when(
      (_) => emit(state.copyWith(message: 'Fähigkeit „$name“ gelöscht.')),
      (failure) => emit(state.copyWith(message: failure.message)),
    );
  }

  void messageShown() => emit(state.copyWith(clearMessage: true));

  Future<TeamId?> _teamIdOrNull() async {
    try {
      return await _getCurrentTeamId();
    } catch (error, stackTrace) {
      logException(
        message: 'Team konnte nicht geladen werden.',
        error: error,
        stackTrace: stackTrace,
        name: 'skills',
      );
      _emitFailure('Team konnte nicht geladen werden.');
      return null;
    }
  }

  Future<void> _loadFolderLocation() async {
    final result = await _loadLocation();
    if (isClosed) return;
    result.when((path) => emit(state.copyWith(location: path)), (_) {});
  }

  void _emitSkills(List<Skill> skills) {
    if (isClosed) return;
    emit(state.copyWith(status: SkillsStatus.ready, skills: skills));
  }

  void _emitFailure(String message) {
    if (isClosed) return;
    emit(state.copyWith(status: SkillsStatus.failure, message: message));
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
