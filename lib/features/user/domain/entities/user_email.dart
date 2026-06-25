class UserEmail {
  const UserEmail._(this.value);

  final String value;

  static UserEmail? tryCreate(String rawValue) {
    final normalized = rawValue.trim();
    if (!_emailPattern.hasMatch(normalized)) return null;
    return UserEmail._(normalized);
  }

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
}
