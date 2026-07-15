import '../../domain/entities/team_member.dart';
import '../../domain/entities/team_workspace.dart';

const _unset = Object();

enum TeamSettingsStatus { loading, ready, failure }

class TeamSettingsState {
  const TeamSettingsState({
    this.status = TeamSettingsStatus.loading,
    this.team,
    this.members = const [],
    this.nameInput = '',
    this.memberInput = '',
    this.isSaving = false,
    this.isAddingMember = false,
    this.removingMemberUid,
    this.message,
  });

  final TeamSettingsStatus status;
  final TeamWorkspace? team;
  final List<TeamMember> members;
  final String nameInput;
  final String memberInput;
  final bool isSaving;
  final bool isAddingMember;
  final String? removingMemberUid;
  final String? message;

  TeamSettingsState copyWith({
    TeamSettingsStatus? status,
    TeamWorkspace? team,
    List<TeamMember>? members,
    String? nameInput,
    String? memberInput,
    bool? isSaving,
    bool? isAddingMember,
    Object? removingMemberUid = _unset,
    String? message,
  }) {
    return TeamSettingsState(
      status: status ?? this.status,
      team: team ?? this.team,
      members: members ?? this.members,
      nameInput: nameInput ?? this.nameInput,
      memberInput: memberInput ?? this.memberInput,
      isSaving: isSaving ?? this.isSaving,
      isAddingMember: isAddingMember ?? this.isAddingMember,
      removingMemberUid: removingMemberUid == _unset
          ? this.removingMemberUid
          : removingMemberUid as String?,
      message: message,
    );
  }
}
