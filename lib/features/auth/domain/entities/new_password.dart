class NewPassword {
  const NewPassword._(this.value);

  /// Gilt für Cloud und Runtime; die Runtime lehnt kürzere Passwörter ab.
  static const minimumLength = 12;

  final String value;

  static NewPassword? parse(String value) {
    if (value.length < minimumLength || value.length > 1000) return null;
    return NewPassword._(value);
  }
}
