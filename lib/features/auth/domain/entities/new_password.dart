class NewPassword {
  const NewPassword._(this.value);

  /// Wie in der Runtime, die kürzere Passwörter ablehnt.
  static const minimumLength = 12;

  final String value;

  static NewPassword? parse(String value) {
    if (value.length < minimumLength || value.length > 1000) return null;
    return NewPassword._(value);
  }
}
