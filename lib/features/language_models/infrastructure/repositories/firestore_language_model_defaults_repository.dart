import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../files/domain/entities/team_id.dart';
import '../../domain/entities/language_model_defaults.dart';
import '../../domain/repositories/language_model_defaults_repository.dart';

/// Liegt direkt auf dem `teams/{teamId}`-Dokument, nicht in einer eigenen
/// Collection: Anders als Modelle/Verbindungen enthält die Vorgabe keine
/// Geheimnisse — ein eigener Schreib-Callable (wie bei `saveLanguageModel`)
/// ist deshalb nicht nötig.
class FirestoreLanguageModelDefaultsRepository
    implements LanguageModelDefaultsRepository {
  FirestoreLanguageModelDefaultsRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<LanguageModelDefaults> watchLanguageModelDefaults(TeamId teamId) {
    return _teamDoc(teamId).snapshots().map(_defaultsFrom);
  }

  @override
  Future<void> saveLanguageModelDefaults(
    TeamId teamId,
    LanguageModelDefaults defaults,
  ) {
    return _teamDoc(teamId).set({
      'languageModelDefaults': {
        'blockModelId': defaults.blockModelId,
        'knowledgeAssistantModelId': defaults.knowledgeAssistantModelId,
      },
    }, SetOptions(merge: true));
  }

  DocumentReference<Map<String, dynamic>> _teamDoc(TeamId teamId) {
    return _firestore.collection('teams').doc(teamId.value);
  }

  LanguageModelDefaults _defaultsFrom(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final value = snapshot.data()?['languageModelDefaults'];
    if (value is! Map) return const LanguageModelDefaults.empty();
    return LanguageModelDefaults(
      blockModelId: value['blockModelId'] as String?,
      knowledgeAssistantModelId: value['knowledgeAssistantModelId'] as String?,
    );
  }
}
