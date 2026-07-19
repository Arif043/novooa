/// Value-Object für validierte E-Mail-Adressen auf Profil-Ebene. Muss
/// synchron zur Firestore-Regel `isValidEmail` bleiben — sonst würde ein
/// eingehendes Profil abgelehnt und der Client fällt auf `unknown` zurück.
class UserEmail {
  const UserEmail._(this.value);

  final String value;

  static UserEmail? tryCreate(String rawValue) {
    final normalized = rawValue.trim();
    if (normalized.length > 254) return null;
    if (!_emailPattern.hasMatch(normalized)) return null;
    return UserEmail._(normalized);
  }

  static final RegExp _emailPattern = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
}
