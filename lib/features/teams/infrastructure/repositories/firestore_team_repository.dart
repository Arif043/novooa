import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../files/domain/entities/team_id.dart';
import '../../domain/entities/team_member.dart';
import '../../domain/entities/team_workspace.dart';
import '../../domain/repositories/team_repository.dart';
import '../datasources/team_member_actions_datasource.dart';

class FirestoreTeamRepository implements TeamRepository {
  const FirestoreTeamRepository(
    this._authRepository,
    this._firestore,
    this._memberActions,
  );

  final AuthRepository _authRepository;
  final FirebaseFirestore _firestore;
  final TeamMemberActionsDatasource _memberActions;

  @override
  Stream<TeamWorkspace> watchCurrentTeam() async* {
    final user = _currentUserOrThrow();
    final teamId = TeamId.personal(user.id.value);
    await _ensurePersonalTeam(teamId, user.id.value);
    yield* _teamReference(teamId).snapshots().map(_teamFrom);
  }

  @override
  Stream<List<TeamMember>> watchCurrentTeamMembers() async* {
    final user = _currentUserOrThrow();
    final teamId = TeamId.personal(user.id.value);
    await _ensurePersonalTeam(teamId, user.id.value);
    yield* _memberReference(teamId).snapshots().map(_membersFrom);
  }

  @override
  Future<void> updateCurrentTeamName(String name) async {
    final user = _currentUserOrThrow();
    final teamId = TeamId.personal(user.id.value);
    await _ensurePersonalTeam(teamId, user.id.value);
    await _teamReference(teamId).update({
      'ownerUid': user.id.value,
      'name': name.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> addCurrentTeamMember(String identifier) {
    return _memberActions.addMember(identifier.trim());
  }

  @override
  Future<void> removeCurrentTeamMember(String uid) {
    return _memberActions.removeMember(uid);
  }

  AuthUser _currentUserOrThrow() {
    final user = _authRepository.currentUser();
    if (user == null) throw StateError('Nicht angemeldet.');
    return user;
  }

  Future<void> _ensurePersonalTeam(TeamId teamId, String ownerUid) async {
    final batch = _firestore.batch();
    batch.set(
      _teamReference(teamId),
      _teamDocument(ownerUid),
      SetOptions(merge: true),
    );
    batch.set(
      _teamReference(teamId).collection('members').doc(ownerUid),
      _memberDocument(ownerUid),
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  Map<String, Object?> _teamDocument(String ownerUid) {
    return {
      'ownerUid': ownerUid,
      'name': 'Persönlicher Arbeitsbereich',
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, Object?> _memberDocument(String ownerUid) {
    return {
      'uid': ownerUid,
      'role': TeamMemberRole.owner.name,
      'joinedAt': FieldValue.serverTimestamp(),
    };
  }

  DocumentReference<Map<String, dynamic>> _teamReference(TeamId teamId) {
    return _firestore.collection('teams').doc(teamId.value);
  }

  CollectionReference<Map<String, dynamic>> _memberReference(TeamId teamId) {
    return _teamReference(teamId).collection('members');
  }

  TeamWorkspace _teamFrom(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? {};
    return TeamWorkspace(
      id: snapshot.id,
      name: data['name'] as String? ?? 'Persönlicher Arbeitsbereich',
      ownerUid: data['ownerUid'] as String? ?? '',
    );
  }

  List<TeamMember> _membersFrom(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs.map(_memberFrom).toList(growable: false);
  }

  TeamMember _memberFrom(QueryDocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data();
    return TeamMember(
      uid: data['uid'] as String? ?? document.id,
      role: _roleFrom(data['role']),
      joinedAt: _dateFrom(data['joinedAt']),
    );
  }

  TeamMemberRole _roleFrom(Object? value) {
    return TeamMemberRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => TeamMemberRole.member,
    );
  }

  DateTime _dateFrom(Object? value) {
    return value is Timestamp
        ? value.toDate()
        : DateTime.fromMillisecondsSinceEpoch(0);
  }
}
