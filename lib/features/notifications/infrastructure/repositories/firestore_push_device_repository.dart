import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/push_device.dart';
import '../../domain/repositories/push_device_repository.dart';

class FirestorePushDeviceRepository implements PushDeviceRepository {
  const FirestorePushDeviceRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<void> save(PushDevice device) async {
    final reference = _tokenReference(device.ownerId, device.token);
    final exists = (await reference.get()).exists;
    await reference.set({
      'token': device.token,
      'platform': device.platform,
      if (!exists) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> remove({required String ownerId, required String token}) {
    return _tokenReference(ownerId, token).delete();
  }

  DocumentReference<Map<String, dynamic>> _tokenReference(
    String userId,
    String token,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('fcmTokens')
        .doc(_tokenDocumentId(token));
  }

  String _tokenDocumentId(String token) {
    return base64Url.encode(utf8.encode(token)).replaceAll('=', '');
  }
}
