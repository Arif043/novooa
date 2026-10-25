import 'package:get_it/get_it.dart';
import 'package:novooa_runtime_client/novooa_runtime_client.dart';

import '../features/runs/domain/repositories/run_repository.dart';
import '../features/runs/infrastructure/runtime_run_repository.dart';
import '../features/tasks/domain/repositories/task_catalog.dart';
import '../features/tasks/infrastructure/runtime_task_catalog.dart';

/// Kompositionswurzel: verbindet die Schnittstellen der Features mit der
/// Runtime. Wird nach jeder Anmeldung neu aufgebaut und beim Abmelden
/// verworfen, damit nichts ein altes Token weiterverwendet.
class DashboardDependencies {
  DashboardDependencies({
    required RuntimeEndpoint endpoint,
    required RuntimeCredentialStore credentials,
    required RuntimeSessionEvents sessionEvents,
  }) {
    Future<String?> authHeader() async {
      final token = await credentials.sessionToken(endpoint.address);
      return token == null ? null : 'Bearer $token';
    }

    final api = SessionAwareWorkspaceApiClient(
      HttpWorkspaceApiClient(
        baseUri: endpoint.apiUri,
        authHeaderProvider: authHeader,
      ),
      sessionEvents,
    );
    _register(api, WorkspaceRealtimeChannel(endpoint.apiUri, api));
  }

  final GetIt _locator = GetIt.asNewInstance();

  T call<T extends Object>() => _locator<T>();

  void _register(WorkspaceApiClient api, WorkspaceRealtimeChannel realtime) {
    _locator
      ..registerSingleton<WorkspaceApiClient>(api)
      ..registerSingleton<WorkspaceRealtimeChannel>(realtime)
      ..registerLazySingleton<TaskCatalog>(
        () => RuntimeTaskCatalog(api, realtime),
      )
      ..registerLazySingleton<RunRepository>(
        () => RuntimeRunRepository(api, realtime),
      );
  }

  /// Schließt die Echtzeit-Verbindung und verwirft alle Registrierungen.
  Future<void> dispose() async {
    await _locator<WorkspaceRealtimeChannel>().close();
    await _locator.reset();
  }
}
