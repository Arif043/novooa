import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/firebase/firebase_region.dart';
import '../../domain/entities/app_notification.dart';
import '../../../activity/domain/entities/task_run_dialog_input_field.dart';
import '../../../activity/domain/entities/task_run_interaction.dart';
import '../../../activity/domain/entities/task_run_media_input.dart';
import '../../domain/repositories/app_notification_repository.dart';

class FirestoreAppNotificationRepository implements AppNotificationRepository {
  FirestoreAppNotificationRepository(
    this._auth,
    this._firestore, {
    FirebaseFunctions? functions,
  }) : _functions =
           functions ??
           FirebaseFunctions.instanceFor(region: firebaseFunctionsRegion);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  @override
  Stream<List<AppNotification>> watchNotifications() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(const []);
    return _reference(uid)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map(_notificationsFrom);
  }

  @override
  Future<void> acceptTeamInvitation(String notificationId) async {
    await _call('acceptTeamInvitationFlow', notificationId);
  }

  @override
  Future<void> rejectTeamInvitation(String notificationId) async {
    await _call('rejectTeamInvitationFlow', notificationId);
  }

  CollectionReference<Map<String, dynamic>> _reference(String uid) {
    return _firestore.collection('users').doc(uid).collection('notifications');
  }

  List<AppNotification> _notificationsFrom(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs.map(_notificationFrom).toList(growable: false);
  }

  AppNotification _notificationFrom(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    return AppNotification(
      id: document.id,
      type: _typeFrom(data['type']),
      status: _statusFrom(data['status']),
      title: data['title'] as String? ?? 'Benachrichtigung',
      message: data['message'] as String? ?? '',
      teamId: data['teamId'] as String?,
      teamName: data['teamName'] as String?,
      runId: data['runId'] as String?,
      taskId: data['taskId'] as String?,
      taskTitle: data['taskTitle'] as String?,
      waitingNodeId: data['waitingNodeId'] as String?,
      finalOutput: data['finalOutput'] as String?,
      reviewOutput: data['reviewOutput'] as String?,
      interaction:
          _interactionFrom(data['interaction']) ?? _legacyInteractionFrom(data),
      createdAt: _dateFrom(data['createdAt']),
    );
  }

  AppNotificationType _typeFrom(Object? value) {
    return switch (value) {
      'teamInvitation' => AppNotificationType.teamInvitation,
      'taskRunApproval' => AppNotificationType.taskRunApproval,
      _ => AppNotificationType.unknown,
    };
  }

  List<TaskRunDialogInputField> _dialogInputFieldsFrom(Object? value) {
    if (value is! Map || value['fields'] is! List) return const [];
    return (value['fields'] as List)
        .whereType<Map>()
        .map(_dialogInputFieldFrom)
        .toList(growable: false);
  }

  TaskRunInteraction? _interactionFrom(Object? value) {
    if (value is! Map) return null;
    final data = Map<Object?, Object?>.from(value);
    final type = TaskRunInteractionType.fromName(data['kind'] as String? ?? '');
    final instruction = data['instruction'] as String? ?? '';
    return switch (type) {
      TaskRunInteractionType.approval => TaskRunInteraction(
        type: type,
        instruction: instruction,
      ),
      TaskRunInteractionType.dialogInput => TaskRunInteraction(
        type: type,
        instruction: instruction,
        dialogInputFields: _dialogInputFieldsFrom(data),
      ),
      TaskRunInteractionType.mediaInput => TaskRunInteraction(
        type: type,
        instruction: instruction,
        mediaInput: TaskRunMediaInput(
          source: TaskRunMediaInputSource.fromName(
            data['source'] as String? ?? '',
          ),
        ),
      ),
    };
  }

  TaskRunInteraction? _legacyInteractionFrom(Map<String, dynamic> data) {
    final fields = _dialogInputFieldsFrom(data['dialogInput']);
    final instruction = data['reviewInstruction'] as String?;
    if (fields.isNotEmpty) {
      return TaskRunInteraction(
        type: TaskRunInteractionType.dialogInput,
        instruction: instruction ?? '',
        dialogInputFields: fields,
      );
    }
    if (instruction == null) return null;
    return TaskRunInteraction(
      type: TaskRunInteractionType.approval,
      instruction: instruction,
    );
  }

  TaskRunDialogInputField _dialogInputFieldFrom(Map<Object?, Object?> data) {
    return TaskRunDialogInputField(
      name: data['name'] as String? ?? '',
      type: TaskRunDialogInputFieldType.fromName(data['type'] as String? ?? ''),
      options: (data['options'] as List? ?? const [])
          .whereType<String>()
          .toList(growable: false),
    );
  }

  AppNotificationStatus _statusFrom(Object? value) {
    return AppNotificationStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => AppNotificationStatus.unknown,
    );
  }

  DateTime _dateFrom(Object? value) {
    return value is Timestamp
        ? value.toDate()
        : DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<void> _call(String functionName, String notificationId) async {
    await _functions.httpsCallable(functionName).call<void>({
      'notificationId': notificationId,
    });
  }
}
