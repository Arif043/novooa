import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/team_id.dart';

class TeamWorkspaceBootstrapper {
  const TeamWorkspaceBootstrapper(this._firestore);

  final FirebaseFirestore _firestore;

  Future<void> ensurePersonalTeam({
    required TeamId teamId,
    required String ownerUid,
  }) async {
    final batch = _firestore.batch();
    batch.set(
      _teamReference(teamId),
      _teamDocument(ownerUid),
      SetOptions(merge: true),
    );
    batch.set(
      _memberReference(teamId, ownerUid),
      _memberDocument(ownerUid),
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  DocumentReference<Map<String, dynamic>> _teamReference(TeamId teamId) {
    return _firestore.collection('teams').doc(teamId.value);
  }

  DocumentReference<Map<String, dynamic>> _memberReference(
    TeamId teamId,
    String ownerUid,
  ) {
    return _teamReference(teamId).collection('members').doc(ownerUid);
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
      'role': 'owner',
      'joinedAt': FieldValue.serverTimestamp(),
    };
  }
}
