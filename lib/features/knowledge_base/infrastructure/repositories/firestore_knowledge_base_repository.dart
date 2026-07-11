import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';

import '../../domain/entities/knowledge_note.dart';
import '../../domain/repositories/knowledge_base_repository.dart';
import '../models/knowledge_note_model.dart';

class FirestoreKnowledgeBaseRepository implements KnowledgeBaseRepository {
  const FirestoreKnowledgeBaseRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<List<KnowledgeNote>> watchNotes(TeamId teamId) {
    return _notesReference(teamId).orderBy('title').snapshots().map(_notesFrom);
  }

  List<KnowledgeNote> _notesFrom(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs
        .map(KnowledgeNoteModel.fromDocument)
        .map((model) => model.toDomain())
        .toList(growable: false);
  }

  CollectionReference<Map<String, dynamic>> _notesReference(TeamId teamId) {
    return _firestore
        .collection('teams')
        .doc(teamId.value)
        .collection('knowledgeBases')
        .doc('default')
        .collection('notes');
  }
}
