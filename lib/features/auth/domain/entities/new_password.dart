class NewPassword {
  const NewPassword._(this.value);

  final String value;

  static NewPassword? parse(String value) {
    if (value.length < 6 || value.length > 1000) return null;
    return NewPassword._(value);
  }
}
