import '../../../../core/entities/unique_id.dart';

enum ApplicationLogLevel { info, error }

class ApplicationLog {
  const ApplicationLog({
    required this.id,
    required this.level,
    required this.event,
    required this.data,
    required this.occurredAt,
    this.message,
  });

  final UniqueId id;
  final ApplicationLogLevel level;
  final String event;
  final String? message;
  final Map<String, Object?> data;
  final DateTime occurredAt;
}
