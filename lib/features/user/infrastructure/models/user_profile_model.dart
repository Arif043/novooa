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

  UserProfile toDomain() {
    return UserProfile(
      id: UniqueId(id),
      email: UserEmail.tryCreate(email)!,
      displayName: displayName,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static DateTime _dateFrom(Object? value) {
    if (value is Timestamp) return value.toDate();
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
