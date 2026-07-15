import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../domain/entities/team_member.dart';
import '../../domain/entities/team_workspace.dart';
import '../../domain/usecases/add_current_team_member.dart';
import '../../domain/usecases/remove_current_team_member.dart';
import '../../domain/usecases/update_current_team_name.dart';
import '../../domain/usecases/watch_current_team.dart';
import '../../domain/usecases/watch_current_team_members.dart';
import 'team_settings_state.dart';

class TeamSettingsCubit extends Cubit<TeamSettingsState> {
  TeamSettingsCubit(
    this._watchCurrentTeam,
    this._watchCurrentTeamMembers,
    this._updateCurrentTeamName,
    this._addCurrentTeamMember,
    this._removeCurrentTeamMember,
  ) : super(const TeamSettingsState());

  final WatchCurrentTeam _watchCurrentTeam;
  final WatchCurrentTeamMembers _watchCurrentTeamMembers;
  final UpdateCurrentTeamName _updateCurrentTeamName;
  final AddCurrentTeamMember _addCurrentTeamMember;
  final RemoveCurrentTeamMember _removeCurrentTeamMember;
  StreamSubscription<TeamWorkspace>? _teamSubscription;
  StreamSubscription<List<TeamMember>>? _membersSubscription;

  Future<void> load() async {
    await _teamSubscription?.cancel();
    await _membersSubscription?.cancel();
    _teamSubscription = _watchCurrentTeam().listen(
      _emitTeam,
      onError: (_) => _emitFailure(),
    );
    _membersSubscription = _watchCurrentTeamMembers().listen(
      _emitMembers,
      onError: (_) => _emitFailure(),
    );
  }

  void updateName(String value) {
    emit(state.copyWith(nameInput: value));
  }

  void updateMemberInput(String value) {
    emit(state.copyWith(memberInput: value));
  }

  Future<void> saveName() async {
    if (state.nameInput.trim().length < 2) {
      return _emitMessage('Der Teamname muss mindestens 2 Zeichen haben.');
    }
    emit(state.copyWith(isSaving: true));
    try {
      await _updateCurrentTeamName(state.nameInput);
      _emitMessage('Team gespeichert.');
    } catch (_) {
      _emitMessage('Team konnte nicht gespeichert werden.');
    }
  }

  Future<void> addMember() async {
    final identifier = state.memberInput.trim();
    if (identifier.isEmpty) {
      return _emitMessage('Bitte gib eine Nutzer-ID oder E-Mail ein.');
    }
    emit(state.copyWith(isAddingMember: true));
    try {
      await _addCurrentTeamMember(identifier);
      _emitMessage('Einladung versendet.', memberInput: '');
    } catch (_) {
      _emitMessage('Einladung konnte nicht versendet werden.');
    }
  }

  Future<void> removeMember(String uid) async {
    emit(state.copyWith(removingMemberUid: uid));
    try {
      await _removeCurrentTeamMember(uid);
      _emitMessage('Mitglied entfernt.');
    } catch (_) {
      _emitMessage('Mitglied konnte nicht entfernt werden.');
    }
  }

  @override
  Future<void> close() async {
    await _teamSubscription?.cancel();
    await _membersSubscription?.cancel();
    return super.close();
  }

  void _emitTeam(TeamWorkspace team) {
    emit(
      state.copyWith(
        status: TeamSettingsStatus.ready,
        team: team,
        nameInput: team.name,
      ),
    );
  }

  void _emitMembers(List<TeamMember> members) {
    emit(state.copyWith(status: TeamSettingsStatus.ready, members: members));
  }

  void _emitFailure() {
    emit(
      state.copyWith(
        status: TeamSettingsStatus.failure,
        message: 'Team konnte nicht geladen werden.',
      ),
    );
  }

  void _emitMessage(String message, {String? memberInput}) {
    if (isClosed) return;
    emit(
      state.copyWith(
        isSaving: false,
        isAddingMember: false,
        removingMemberUid: null,
        memberInput: memberInput,
        message: message,
      ),
    );
  }
}
