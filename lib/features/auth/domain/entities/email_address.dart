class EmailAddress {
  const EmailAddress._(this.value);

  final String value;

  static EmailAddress? tryCreate(String rawValue) {
    final normalized = rawValue.trim();
    if (!_emailPattern.hasMatch(normalized)) return null;
    return EmailAddress._(normalized);
  }

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
}
