import 'unique_id.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.displayName,
  });

  final UniqueId id;
  final String email;
  final String displayName;
}
