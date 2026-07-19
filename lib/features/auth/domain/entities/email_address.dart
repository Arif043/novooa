/// Value-Object für validierte E-Mail-Adressen.
///
/// Die Regex spiegelt bewusst die Regel bewusst in `firestore.rules`
/// (`isValidEmail`), damit ein Client-Wert, der hier akzeptiert wird, auch
/// beim späteren Firestore-Write akzeptiert wird und nicht auf `unknown`
/// landet.
class EmailAddress {
  const EmailAddress._(this.value);

  final String value;

  static EmailAddress? tryCreate(String rawValue) {
    final normalized = rawValue.trim();
    if (normalized.length > 254) return null;
    if (!_emailPattern.hasMatch(normalized)) return null;
    return EmailAddress._(normalized);
  }

  static final RegExp _emailPattern = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
}
