import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:syscat2/core/logging/logger.dart';
import 'package:syscat2/features/auth/domain/repositories/auth_repository.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';
import 'package:syscat2/features/skills/domain/entities/skill.dart';
import 'package:syscat2/features/skills/domain/usecases/watch_skills.dart';
import 'package:syscat2/features/teams/domain/usecases/get_current_team_id.dart';

import '../../domain/entities/skill_attachment.dart';
import 'node_skill_attachments_state.dart';

/// Beobachtet die verfügbaren Fähigkeiten des Teams und stellt sie dem
/// NodeInspector als Auswahl bereit — analog zu
/// [NodeKnowledgeAttachmentsCubit].
class NodeSkillAttachmentsCubit extends Cubit<NodeSkillAttachmentsState> {
  NodeSkillAttachmentsCubit(
    this._authRepository,
    this._watchSkills,
    this._getCurrentTeamId,
  ) : super(const NodeSkillAttachmentsState());

  final AuthRepository _authRepository;
  final WatchSkills _watchSkills;
  final GetCurrentTeamId _getCurrentTeamId;
  StreamSubscription<List<Skill>>? _subscription;

  Future<void> load() async {
    final user = _authRepository.currentUser();
    if (user == null) return _emitFailure('Du musst angemeldet sein.');
    emit(const NodeSkillAttachmentsState());
    _subscription?.cancel();
    final teamId = await _teamIdOrNull();
    if (teamId == null) return;
    _subscription = _watchSkills(teamId).listen(
      _emitSkills,
      onError: (Object error, StackTrace stackTrace) {
        _logAndEmitFailure(
          'Fähigkeiten konnten nicht geladen werden.',
          error,
          stackTrace,
        );
      },
    );
  }

  Future<TeamId?> _teamIdOrNull() async {
    try {
      return await _getCurrentTeamId();
    } catch (error, stackTrace) {
      _logAndEmitFailure(
        'Team konnte nicht geladen werden.',
        error,
        stackTrace,
      );
      return null;
    }
  }

  void _emitSkills(List<Skill> skills) {
    if (isClosed) return;
    emit(
      NodeSkillAttachmentsState(
        status: NodeSkillAttachmentsStatus.ready,
        skills: skills.map(_toAttachment).toList(growable: false),
      ),
    );
  }

  SkillAttachment _toAttachment(Skill skill) {
    return SkillAttachment(
      skillId: skill.id,
      title: skill.title,
      description: skill.description,
      storagePath: skill.storagePath,
    );
  }

  void _emitFailure(String message) {
    if (isClosed) return;
    emit(
      NodeSkillAttachmentsState(
        status: NodeSkillAttachmentsStatus.failure,
        message: message,
      ),
    );
  }

  void _logAndEmitFailure(String message, Object error, StackTrace stackTrace) {
    logException(
      message: message,
      error: error,
      stackTrace: stackTrace,
      name: 'node_skill_attachments',
    );
    _emitFailure(message);
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
