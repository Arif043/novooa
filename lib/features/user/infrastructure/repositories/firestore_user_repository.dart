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
    if (displayName.trim().length < 2) {
      return Error(UserFailure(UserFailureKind.invalidName));
    }
    try {
      final reference = _users.doc(id.value);
      final current = await reference.get();
      current.exists
          ? await _updateProfile(reference, email, displayName)
          : await _createProfile(reference, id, email, displayName);
      final snapshot = await reference.get();
      return _profileFrom(snapshot);
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

  Future<void> _createProfile(
    DocumentReference<Map<String, dynamic>> reference,
    UniqueId id,
    UserEmail email,
    String displayName,
  ) {
    final model = _newModel(id, email, displayName);
    return reference.set(model.toDocument(useServerTimestamps: true));
  }

  Future<void> _updateProfile(
    DocumentReference<Map<String, dynamic>> reference,
    UserEmail email,
    String displayName,
  ) {
    final model = _newModel(UniqueId(reference.id), email, displayName);
    return reference.update(
      model.toDocument(includeCreatedAt: false, useServerTimestamps: true),
    );
  }

  UserProfileModel _newModel(UniqueId id, UserEmail email, String displayName) {
    final now = DateTime.now();
    return UserProfileModel(
      id: id.value,
      email: email.value,
      displayName: displayName.trim(),
      createdAt: now,
      updatedAt: now,
    );
  }

  Result<UserProfile, UserFailure> _profileFrom(DocumentSnapshot snapshot) {
    final model = UserProfileModel.fromDocument(snapshot);
    if (UserEmail.tryCreate(model.email) == null) {
      return Error(UserFailure(UserFailureKind.invalidEmail));
    }
    return Success(model.toDomain());
  }
}
