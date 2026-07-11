import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/entities/unique_id.dart';
import '../../../files/domain/entities/team_id.dart';
import '../../../files/infrastructure/repositories/team_workspace_bootstrapper.dart';
import '../../domain/entities/create_task_trigger_input.dart';
import '../../domain/entities/schedule_config.dart';
import '../../domain/repositories/task_trigger_repository.dart';
import '../../domain/entities/task_trigger.dart';
import '../models/task_trigger_model.dart';
import 'schedule_next_run_calculator.dart';

class FirestoreTaskTriggerRepository implements TaskTriggerRepository {
  FirestoreTaskTriggerRepository(this._auth, this._firestore)
    : _bootstrapper = TeamWorkspaceBootstrapper(_firestore);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final TeamWorkspaceBootstrapper _bootstrapper;
  final ScheduleNextRunCalculator _nextRunCalculator =
      const ScheduleNextRunCalculator();

  @override
  Stream<List<TaskTrigger>> watchTriggers() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(const []);
    return _triggersReference(
      _teamId(user.uid),
    ).orderBy('nextRunAt').snapshots().map(_toTriggers);
  }

  @override
  Future<void> createTrigger(CreateTaskTriggerInput input) async {
    final user = _auth.currentUser;
    if (user == null || !input.schedule.isValid) return;
    final teamId = _teamId(user.uid);
    final triggerId = UniqueId.random().value;
    final nextRunAt = _nextRunCalculator(input.schedule, DateTime.now());
    if (nextRunAt == null) return;
    await _bootstrapper.ensurePersonalTeam(teamId: teamId, ownerUid: user.uid);
    await _triggersReference(teamId)
        .doc(triggerId)
        .set(_triggerDocument(triggerId, teamId, user.uid, input, nextRunAt));
  }

  @override
  Future<void> setTriggerEnabled(String triggerId, bool enabled) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _triggersReference(_teamId(user.uid)).doc(triggerId).update({
      'enabled': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteTrigger(String triggerId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _triggersReference(_teamId(user.uid)).doc(triggerId).delete();
  }

  Map<String, Object?> _triggerDocument(
    String triggerId,
    TeamId teamId,
    String ownerUid,
    CreateTaskTriggerInput input,
    DateTime nextRunAt,
  ) {
    return {
      'id': triggerId,
      'teamId': teamId.value,
      'createdByUid': ownerUid,
      'taskId': input.taskId,
      'taskTitle': input.taskTitle,
      'type': 'schedule',
      'enabled': input.enabled,
      'config': _scheduleDocument(input.schedule),
      'policy': {'ifRunning': input.policy.name},
      'nextRunAt': Timestamp.fromDate(nextRunAt),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, Object?> _scheduleDocument(ScheduleConfig config) {
    return {
      'kind': config.kind.name,
      'timezone': config.timezone,
      if (config.runAt != null) 'runAt': Timestamp.fromDate(config.runAt!),
      if (config.timeOfDay != null) 'timeOfDay': config.timeOfDay,
      if (config.weekdays.isNotEmpty) 'weekdays': config.weekdays,
      if (config.slots.isNotEmpty)
        'slots': config.slots.map(_slotDocument).toList(growable: false),
    };
  }

  Map<String, Object?> _slotDocument(WeeklyTimeSlot slot) {
    return {'weekday': slot.weekday, 'timeOfDay': slot.timeOfDay};
  }

  List<TaskTrigger> _toTriggers(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs
        .map(TaskTriggerModel.fromDocument)
        .map((model) => model.toDomain())
        .toList(growable: false);
  }

  CollectionReference<Map<String, dynamic>> _triggersReference(TeamId teamId) {
    return _firestore
        .collection('teams')
        .doc(teamId.value)
        .collection('taskTriggers');
  }

  TeamId _teamId(String uid) {
    return TeamId.personal(uid);
  }
}
