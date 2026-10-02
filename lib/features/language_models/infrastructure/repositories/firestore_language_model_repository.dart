import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../../../core/firebase/firebase_region.dart';
import '../../../files/domain/entities/team_id.dart';
import '../../domain/entities/language_model.dart';
import '../../domain/entities/language_model_draft.dart';
import '../../domain/repositories/language_model_repository.dart';

class FirestoreLanguageModelRepository implements LanguageModelRepository {
  FirestoreLanguageModelRepository(
    this._firestore, {
    FirebaseFunctions? functions,
  }) : _functions =
           functions ??
           FirebaseFunctions.instanceFor(region: firebaseFunctionsRegion);

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  @override
  Stream<List<LanguageModel>> watchLanguageModels(TeamId teamId) {
    return _firestore
        .collection('teams')
        .doc(teamId.value)
        .collection('languageModels')
        .orderBy('name')
        .snapshots()
        .asyncMap((snapshot) => _modelsWithProviders(teamId, snapshot));
  }

  /// Der Anbieter steht an der Verbindung, nicht am Modell-Dokument.
  Future<List<LanguageModel>> _modelsWithProviders(
    TeamId teamId,
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) async {
    final connections = await _firestore
        .collection('teams')
        .doc(teamId.value)
        .collection('languageModelConnections')
        .get();
    final providers = {
      for (final doc in connections.docs)
        doc.id: LanguageModelProvider.tryFromId(doc.data()['provider']),
    };
    return snapshot.docs
        .map((doc) => _modelFrom(doc, providers))
        .toList(growable: false);
  }

  @override
  Future<void> saveLanguageModel(LanguageModelDraft draft) async {
    await _functions.httpsCallable('saveLanguageModel').call({
      'connectionName': draft.connectionName,
      'provider': draft.provider.id,
      if (draft.provider.hasEndpoint) 'baseUrl': draft.baseUrl,
      'name': draft.name,
      'languageModelId': draft.modelId,
      'apiKey': draft.apiKey,
      'capabilities': {
        'textGeneration': true,
        'imageInput': false,
        'structuredOutput': true,
        'toolCalling': false,
        'imageGeneration': false,
      },
    });
  }

  LanguageModel _modelFrom(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    Map<String, LanguageModelProvider?> providers,
  ) {
    final data = doc.data();
    final capabilities = data['capabilities'] as Map<String, dynamic>? ?? {};
    return LanguageModel(
      id: doc.id,
      name: data['name'] as String? ?? data['modelId'] as String? ?? doc.id,
      modelId: data['modelId'] as String? ?? '',
      supportsImageInput: capabilities['imageInput'] == true,
      supportsStructuredOutput: capabilities['structuredOutput'] == true,
      supportsImageGeneration: capabilities['imageGeneration'] == true,
      provider: providers[data['connectionId']],
    );
  }
}
