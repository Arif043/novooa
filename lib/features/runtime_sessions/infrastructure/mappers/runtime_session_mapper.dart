import '../../domain/entities/runtime_session.dart';
import '../../domain/entities/session_device.dart';

/// Übersetzt `GET /v1/auth/sessions` in Entitäten; unvollständige Einträge
/// fallen weg, statt die ganze Liste scheitern zu lassen.
abstract final class RuntimeSessionMapper {
  static List<RuntimeSession> sessionsFrom(Map<String, Object?> response) {
    final items = response['items'];
    if (items is! List) return const [];
    return items
        .whereType<Map<String, Object?>>()
        .map(_sessionFrom)
        .nonNulls
        .toList();
  }

  static RuntimeSession? _sessionFrom(Map<String, Object?> json) {
    final id = json['id'];
    final signedInAt = _dateFrom(json['createdAt']);
    final lastActiveAt = _dateFrom(json['lastUsedAt']);
    if (id is! String || signedInAt == null || lastActiveAt == null) {
      return null;
    }
    return RuntimeSession(
      id: RuntimeSessionId(id),
      isCurrent: json['current'] == true,
      signedInAt: signedInAt,
      lastActiveAt: lastActiveAt,
      device: _deviceFrom(json['device']),
    );
  }

  static SessionDevice _deviceFrom(Object? json) {
    if (json is! Map<String, Object?>) {
      return const SessionDevice(app: '', os: DeviceOs.unknown);
    }
    final browser = json['browser'];
    return SessionDevice(
      app: json['app'] as String? ?? '',
      os: DeviceOs.values.asNameMap()[json['os']] ?? DeviceOs.unknown,
      browser: browser is String && browser.isNotEmpty ? browser : null,
    );
  }

  static DateTime? _dateFrom(Object? raw) =>
      raw is String ? DateTime.tryParse(raw)?.toLocal() : null;
}
