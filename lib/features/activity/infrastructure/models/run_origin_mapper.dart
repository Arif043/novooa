import '../../domain/entities/run_origin.dart';

/// Liest `origin` aus `GET /v1/activities`; fehlt es, ist die Herkunft unbekannt.
RunOrigin runOriginFrom(Object? value) {
  if (value is! Map) return RunOrigin.unknown;
  return RunOrigin(
    startedBy: _nameOf(value['startedBy']),
    reviewedBy: _nameOf(value['reviewedBy']),
    triggerType: value['triggerType'] is String
        ? value['triggerType'] as String
        : null,
  );
}

String? _nameOf(Object? person) {
  if (person is! Map) return null;
  final name = person['displayName'];
  return name is String && name.isNotEmpty ? name : null;
}
