import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/entities/unique_id.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../files/domain/entities/team_id.dart';
import '../../../files/infrastructure/repositories/team_workspace_bootstrapper.dart';
import '../../domain/entities/create_task_trigger_input.dart';
import '../../domain/entities/event_trigger_config.dart';
import '../../domain/entities/schedule_config.dart';
import '../../domain/repositories/task_trigger_repository.dart';
import '../../domain/entities/task_trigger.dart';
import '../models/task_trigger_model.dart';
import 'schedule_next_run_calculator.dart';

class FirestoreTaskTriggerRepository implements TaskTriggerRepository {
  FirestoreTaskTriggerRepository(this._authRepository, this._firestore)
    : _bootstrapper = TeamWorkspaceBootstrapper(_firestore);

  final AuthRepository _authRepository;
  final FirebaseFirestore _firestore;
  final TeamWorkspaceBootstrapper _bootstrapper;
  final ScheduleNextRunCalculator _nextRunCalculator =
      const ScheduleNextRunCalculator();

  @override
  Stream<List<TaskTrigger>> watchTriggers() {
    final user = _authRepository.currentUser();
    if (user == null) return Stream.value(const []);
    return _triggersReference(
      _teamId(user.id.value),
    ).orderBy('nextRunAt').snapshots().map(_toTriggers);
  }

  @override
  Future<void> createTrigger(CreateTaskTriggerInput input) async {
    final user = _authRepository.currentUser();
    if (user == null || !input.isValid) return;
    final ownerUid = user.id.value;
    final teamId = _teamId(ownerUid);
    final triggerId = UniqueId.random().value;
    final nextRunAt = _nextRunAtFor(input);
    if (input.type == TriggerType.schedule && nextRunAt == null) return;
    await _bootstrapper.ensurePersonalTeam(teamId: teamId, ownerUid: ownerUid);
    await _triggersReference(teamId)
        .doc(triggerId)
        .set(_triggerDocument(triggerId, teamId, ownerUid, input, nextRunAt));
  }

  @override
  Future<void> setTriggerEnabled(String triggerId, bool enabled) async {
    final user = _authRepository.currentUser();
    if (user == null) return;
    await _triggersReference(_teamId(user.id.value)).doc(triggerId).update({
      'enabled': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteTrigger(String triggerId) async {
    final user = _authRepository.currentUser();
    if (user == null) return;
    await _triggersReference(_teamId(user.id.value)).doc(triggerId).delete();
  }

  Map<String, Object?> _triggerDocument(
    String triggerId,
    TeamId teamId,
    String ownerUid,
    CreateTaskTriggerInput input,
    DateTime? nextRunAt,
  ) {
    return {
      'id': triggerId,
      'teamId': teamId.value,
      'createdByUid': ownerUid,
      'taskId': input.taskId,
      'taskTitle': input.taskTitle,
      'type': input.type.name,
      'enabled': input.enabled,
      if (input.schedule != null) 'config': _scheduleDocument(input.schedule!),
      if (input.event != null) 'eventConfig': _eventDocument(input.event!),
      'policy': {'ifRunning': input.policy.name},
      'nextRunAt': nextRunAt == null ? null : Timestamp.fromDate(nextRunAt),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  DateTime? _nextRunAtFor(CreateTaskTriggerInput input) {
    final schedule = input.schedule;
    if (schedule == null) return null;
    return _nextRunCalculator(schedule, DateTime.now());
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

  Map<String, Object?> _eventDocument(EventTriggerConfig config) {
    return {
      'source': config.source.name,
      'filter': config.filter.trim(),
      if (config.channelId != null) 'channelId': config.channelId,
    };
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
