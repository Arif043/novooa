import '../entities/application_log.dart';

abstract interface class ApplicationLogRepository {
  Stream<List<ApplicationLog>> watchRecent();
}
