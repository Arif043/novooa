import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../../../core/firebase/firebase_region.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../files/domain/entities/team_id.dart';
import '../../../teams/domain/repositories/team_repository.dart';
import '../../domain/entities/mail_connector.dart';
import '../../domain/repositories/mail_connector_repository.dart';
import '../models/mail_connector_model.dart';

class FirestoreMailConnectorRepository implements MailConnectorRepository {
  FirestoreMailConnectorRepository(
    this._authRepository,
    this._firestore,
    this._teamRepository, {
    FirebaseFunctions? functions,
  }) : _functions =
           functions ??
           FirebaseFunctions.instanceFor(region: firebaseFunctionsRegion);

  final AuthRepository _authRepository;
  final FirebaseFirestore _firestore;
  final TeamRepository _teamRepository;
  final FirebaseFunctions _functions;

  @override
  Stream<List<MailConnector>> watchConnectors() {
    if (_authRepository.currentUser() == null) return Stream.value(const []);
    return _teamRepository.watchCurrentTeamId().asyncExpand((teamId) {
      return _connectors(teamId).snapshots().map(_connectorsFrom);
    });
  }

  @override
  Future<String> beginMicrosoftConnection() async {
    final callable = _functions.httpsCallable(
      'beginMicrosoftMailConnector',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
    );
    final response = await callable.call<Object?>(null);
    final data = response.data;
    final url = data is Map ? data['authorizationUrl'] : null;
    if (url is! String || url.isEmpty) {
      throw StateError('Microsoft-Anmeldung fehlt.');
    }
    return url;
  }

  Query<Map<String, dynamic>> _connectors(TeamId teamId) {
    return _firestore
        .collection('teams')
        .doc(teamId.value)
        .collection('mailConnectors')
        .orderBy('createdAt', descending: true);
  }

  List<MailConnector> _connectorsFrom(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs
        .map(MailConnectorModel.fromDocument)
        .map((model) => model.toDomain())
        .toList(growable: false);
  }
}
