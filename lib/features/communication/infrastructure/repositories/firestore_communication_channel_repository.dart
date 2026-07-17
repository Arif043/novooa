import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../../../core/entities/unique_id.dart';
import '../../../../core/firebase/firebase_region.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../files/domain/entities/team_id.dart';
import '../../../teams/domain/repositories/team_repository.dart';
import '../../domain/entities/communication_channel.dart';
import '../../domain/entities/create_communication_channel_input.dart';
import '../../domain/entities/send_channel_message_input.dart';
import '../../domain/repositories/communication_channel_repository.dart';
import '../models/communication_channel_model.dart';

class FirestoreCommunicationChannelRepository
    implements CommunicationChannelRepository {
  FirestoreCommunicationChannelRepository(
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
  Stream<List<CommunicationChannel>> watchChannels() {
    final user = _authRepository.currentUser();
    if (user == null) return Stream.value(const []);
    return Stream.fromFuture(_teamRepository.currentTeamId()).asyncExpand(
      (teamId) => _channelsReference(
        teamId,
      ).orderBy('createdAt', descending: true).snapshots().map(_toChannels),
    );
  }

  @override
  Future<void> createChannel(CreateCommunicationChannelInput input) async {
    final user = _authRepository.currentUser();
    if (user == null || !input.isValid) return;
    final ownerUid = user.id.value;
    final teamId = await _teamRepository.currentTeamId();
    final channelId = UniqueId.random().value;
    await _channelsReference(
      teamId,
    ).doc(channelId).set(_channelDocument(channelId, teamId, ownerUid, input));
  }

  @override
  Future<void> deleteChannel(String channelId) async {
    final user = _authRepository.currentUser();
    if (user == null) return;
    final teamId = await _teamRepository.currentTeamId();
    await _channelsReference(teamId).doc(channelId).delete();
  }

  @override
  Future<void> dispatchFakeMessage(String channelId) async {
    final callable = _functions.httpsCallable(
      'dispatchFakeChannelMessage',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
    );
    await callable.call<void>({
      'channelId': channelId,
      'body': 'Testnachricht aus Syscat',
    });
  }

  @override
  Future<void> sendMessage(SendChannelMessageInput input) async {
    if (!input.isValid) return;
    final callable = _functions.httpsCallable(
      'sendChannelMessage',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
    );
    await callable.call<void>({
      'channelId': input.channelId,
      'to': input.to.trim(),
      'body': input.body.trim(),
    });
  }

  Map<String, Object?> _channelDocument(
    String channelId,
    TeamId teamId,
    String ownerUid,
    CreateCommunicationChannelInput input,
  ) {
    return {
      'id': channelId,
      'teamId': teamId.value,
      'createdByUid': ownerUid,
      'provider': input.provider.name,
      'kind': input.kind.name,
      'label': input.label.trim(),
      'address': input.address.trim(),
      'status': CommunicationChannelStatus.active.name,
      'capabilities': _capabilities(input.capabilities),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, Object?> _capabilities(ChannelCapabilities capabilities) {
    return {'inbound': capabilities.inbound, 'outbound': capabilities.outbound};
  }

  List<CommunicationChannel> _toChannels(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs
        .map(CommunicationChannelModel.fromDocument)
        .map((model) => model.toDomain())
        .toList(growable: false);
  }

  CollectionReference<Map<String, dynamic>> _channelsReference(TeamId teamId) {
    return _firestore
        .collection('teams')
        .doc(teamId.value)
        .collection('communicationChannels');
  }
}
