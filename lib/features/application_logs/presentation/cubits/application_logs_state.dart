import '../../domain/entities/application_log.dart';

sealed class ApplicationLogsState {
  const ApplicationLogsState();
}

class ApplicationLogsLoading extends ApplicationLogsState {
  const ApplicationLogsLoading();
}

class ApplicationLogsReady extends ApplicationLogsState {
  const ApplicationLogsReady(this.logs);

  final List<ApplicationLog> logs;
}

class ApplicationLogsFailure extends ApplicationLogsState {
  const ApplicationLogsFailure();
}
