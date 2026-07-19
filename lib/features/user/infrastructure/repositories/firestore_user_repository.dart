import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/core/entities/unique_id.dart';

import '../../domain/entities/user_email.dart';
import '../../domain/entities/user_failure.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_repository.dart';
import '../models/user_profile_model.dart';

class FirestoreUserRepository implements UserRepository {
  const FirestoreUserRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users {
    return _firestore.collection('users');
  }

  @override
  Future<Result<UserProfile, UserFailure>> ensureProfile({
    required UniqueId id,
    required UserEmail email,
    required String displayName,
  }) async {
    final trimmedName = displayName.trim();
    if (trimmedName.length < 2) {
      return Error(UserFailure(UserFailureKind.invalidName));
    }
    try {
      final reference = _users.doc(id.value);
      final current = await reference.get();
      final now = DateTime.now();
      final createdAt = current.exists
          ? _createdAtFrom(current.data())
          : now;
      final model = UserProfileModel(
        id: id.value,
        email: email.value,
        displayName: trimmedName,
        createdAt: createdAt,
        updatedAt: now,
      );
      if (current.exists) {
        await reference.update(
          model.toDocument(includeCreatedAt: false, useServerTimestamps: true),
        );
      } else {
        await reference.set(model.toDocument(useServerTimestamps: true));
      }
      return Success(model.toDomain());
    } catch (_) {
      return Error(UserFailure(UserFailureKind.unknown));
    }
  }

  @override
  Future<Result<UserProfile, UserFailure>> getProfile(UniqueId id) async {
    try {
      final snapshot = await _users.doc(id.value).get();
      if (!snapshot.exists) return Error(UserFailure(UserFailureKind.notFound));
      return _profileFrom(snapshot);
    } catch (_) {
      return Error(UserFailure(UserFailureKind.unknown));
    }
  }

  Result<UserProfile, UserFailure> _profileFrom(DocumentSnapshot snapshot) {
    final model = UserProfileModel.fromDocument(snapshot);
    if (UserEmail.tryCreate(model.email) == null) {
      return Error(UserFailure(UserFailureKind.invalidEmail));
    }
    return Success(model.toDomain());
  }

  DateTime _createdAtFrom(Map<String, Object?>? data) {
    final value = data?['createdAt'];
    if (value is Timestamp) return value.toDate();
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
