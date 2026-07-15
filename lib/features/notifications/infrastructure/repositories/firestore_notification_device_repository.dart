import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/notification_device_token.dart';
import '../../domain/repositories/notification_device_repository.dart';

class FirestoreNotificationDeviceRepository
    implements NotificationDeviceRepository {
  const FirestoreNotificationDeviceRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<void> saveToken(NotificationDeviceToken token) async {
    final reference = _tokenReference(token.userId, token.token);
    final exists = (await reference.get()).exists;
    await reference.set({
      'token': token.token,
      'platform': token.platform,
      if (!exists) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> deleteToken({required String userId, required String token}) {
    return _tokenReference(userId, token).delete();
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
