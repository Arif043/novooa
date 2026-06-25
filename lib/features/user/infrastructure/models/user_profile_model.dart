import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syscat2/core/domain/unique_id.dart';

import '../../domain/entities/user_email.dart';
import '../../domain/entities/user_profile.dart';

class UserProfileModel {
  const UserProfileModel({
    required this.id,
    required this.email,
    required this.displayName,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String email;
  final String displayName;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory UserProfileModel.fromDocument(DocumentSnapshot document) {
    final data = document.data() as Map<String, dynamic>? ?? {};
    return UserProfileModel(
      id: document.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      createdAt: _dateFrom(data['createdAt']),
      updatedAt: _dateFrom(data['updatedAt']),
    );
  }

  factory UserProfileModel.fromDomain(UserProfile profile) {
    return UserProfileModel(
      id: profile.id.value,
      email: profile.email.value,
      displayName: profile.displayName,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt,
    );
  }

  Map<String, Object?> toDocument({
    bool includeCreatedAt = true,
    bool useServerTimestamps = false,
  }) {
    final document = <String, Object?>{
      'email': email,
      'displayName': displayName,
      'updatedAt': _timestampFor(updatedAt, useServerTimestamps),
    };
    if (includeCreatedAt) {
      document['createdAt'] = _timestampFor(createdAt, useServerTimestamps);
    }
    return document;
  }

  UserProfile toDomain() {
    return UserProfile(
      id: UniqueId(id),
      email: UserEmail.tryCreate(email)!,
      displayName: displayName,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static Object _timestampFor(DateTime value, bool useServerTimestamp) {
    if (useServerTimestamp) return FieldValue.serverTimestamp();
    return Timestamp.fromDate(value);
  }

  static DateTime _dateFrom(Object? value) {
    if (value is Timestamp) return value.toDate();
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
