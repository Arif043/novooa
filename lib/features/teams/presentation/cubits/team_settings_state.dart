import '../../domain/entities/team_member.dart';
import '../../domain/entities/team_workspace.dart';

enum TeamSettingsStatus { loading, ready, failure }

class TeamSettingsState {
  const TeamSettingsState({
    this.status = TeamSettingsStatus.loading,
    this.team,
    this.members = const [],
    this.nameInput = '',
    this.isSaving = false,
    this.message,
  });

  final TeamSettingsStatus status;
  final TeamWorkspace? team;
  final List<TeamMember> members;
  final String nameInput;
  final bool isSaving;
  final String? message;

  TeamSettingsState copyWith({
    TeamSettingsStatus? status,
    TeamWorkspace? team,
    List<TeamMember>? members,
    String? nameInput,
    bool? isSaving,
    String? message,
  }) {
    return TeamSettingsState(
      status: status ?? this.status,
      team: team ?? this.team,
      members: members ?? this.members,
      nameInput: nameInput ?? this.nameInput,
      isSaving: isSaving ?? this.isSaving,
      message: message,
    );
  }
}
