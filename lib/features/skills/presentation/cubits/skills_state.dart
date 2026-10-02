import 'package:equatable/equatable.dart';

import '../../domain/entities/skill.dart';

enum SkillsStatus { loading, ready, failure }

class SkillsState extends Equatable {
  const SkillsState({
    this.status = SkillsStatus.loading,
    this.skills = const [],
    this.message,
  });

  final SkillsStatus status;
  final List<Skill> skills;

  /// Einmalige Rückmeldung (Fehler oder Bestätigung) für eine Snackbar.
  final String? message;

  SkillsState copyWith({
    SkillsStatus? status,
    List<Skill>? skills,
    String? message,
    bool clearMessage = false,
  }) {
    return SkillsState(
      status: status ?? this.status,
      skills: skills ?? this.skills,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, skills, message];
}
