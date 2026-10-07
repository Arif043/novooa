// Strenge Lesehilfen für JSON der Runtime-API; Fehler als [FormatException].

Map<String, Object?> jsonObject(Object? value) {
  if (value is! Map) {
    throw const FormatException('Ein Modellkatalogeintrag ist ungültig.');
  }
  return {for (final entry in value.entries) entry.key.toString(): entry.value};
}

List<Object?> jsonItems(Object? value) {
  if (value is! List) {
    throw const FormatException('Ein Modellkatalogeintrag ist ungültig.');
  }
  return value;
}

List<Object?> jsonItemsOrEmpty(Object? value) {
  if (value == null) return const [];
  return jsonItems(value);
}

List<String> jsonStrings(Object? value) {
  if (value is! List || !value.every((item) => item is String)) {
    throw const FormatException('Ein Modellkatalogeintrag ist ungültig.');
  }
  return value.cast<String>();
}

int jsonPositiveInt(Object? value) {
  if (value is int && value > 0) return value;
  throw const FormatException('Ein Modellkatalogeintrag ist ungültig.');
}

double jsonNumber(Object? value) {
  if (value is num && value.isFinite) return value.toDouble();
  throw const FormatException('Der Modellparameter ist ungültig.');
}

bool jsonBoolean(Object? value) {
  if (value is bool) return value;
  throw const FormatException('Der Modellparameter ist ungültig.');
}

String jsonText(Map<String, Object?> value, String field) {
  final text = value[field];
  if (text is String && text.isNotEmpty) return text;
  throw const FormatException('Ein Modellkatalogeintrag ist ungültig.');
}
