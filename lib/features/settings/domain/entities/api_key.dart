class ApiKey {
  const ApiKey._(this.value);

  final String value;

  static ApiKey? tryCreate(String rawValue) {
    final normalized = rawValue.trim();
    if (normalized.length < 8) return null;
    return ApiKey._(normalized);
  }
}
