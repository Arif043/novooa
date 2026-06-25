import 'package:syscat2/core/domain/unique_id.dart';

import 'user_email.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.createdAt,
    required this.updatedAt,
  });

  final UniqueId id;
  final UserEmail email;
  final String displayName;
  final DateTime createdAt;
  final DateTime updatedAt;
}
