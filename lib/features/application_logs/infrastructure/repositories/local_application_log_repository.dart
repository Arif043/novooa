import 'package:novooa_runtime_client/novooa_runtime_client.dart';

import '../../../../core/entities/unique_id.dart';
import '../../domain/entities/application_log.dart';
import '../../domain/repositories/application_log_repository.dart';

class LocalApplicationLogRepository implements ApplicationLogRepository {
  const LocalApplicationLogRepository(this._client, this._channel);

  final WorkspaceApiClient _client;
  final WorkspaceRealtimeChannel _channel;

  @override
  Stream<List<ApplicationLog>> watchRecent() =>
      watchWorkspaceChannel('application-logs', _load, _channel);

  Future<List<ApplicationLog>> _load() async {
    final response = await _client.get('/v1/application-logs');
    final items = response['items'];
    if (items is! List) {
      throw const FormatException(
        'Das lokale Anwendungsprotokoll ist ungültig.',
      );
    }
    return items.whereType<Map>().map(_logFrom).toList(growable: false);
  }

  ApplicationLog _logFrom(Map<dynamic, dynamic> value) {
    final data = {
      for (final entry in value.entries) entry.key.toString(): entry.value,
    };
    return ApplicationLog(
      id: UniqueId(_string(data['id'])),
      level: _levelFrom(data['level']),
      source: _sourceFrom(data['source']),
      event: _string(data['event']),
      message: _nullableString(data['message']),
      data: _dataFrom(data['data']),
      occurredAt: _dateFrom(data['occurredAt']),
    );
  }

  ApplicationLogLevel _levelFrom(Object? value) =>
      ApplicationLogLevel.values.firstWhere(
        (level) => level.name == value,
        orElse: () => ApplicationLogLevel.info,
      );

  ApplicationLogSource _sourceFrom(Object? value) =>
      ApplicationLogSource.values.firstWhere(
        (source) => source.name == value,
        orElse: () => ApplicationLogSource.runtime,
      );

  Map<String, Object?> _dataFrom(Object? value) => value is Map
      ? {for (final entry in value.entries) entry.key.toString(): entry.value}
      : const {};

  DateTime _dateFrom(Object? value) => value is String
      ? DateTime.tryParse(value)?.toLocal() ??
            DateTime.fromMillisecondsSinceEpoch(0)
      : DateTime.fromMillisecondsSinceEpoch(0);

  String _string(Object? value) => value is String ? value : '';
  String? _nullableString(Object? value) =>
      value is String && value.isNotEmpty ? value : null;
}
