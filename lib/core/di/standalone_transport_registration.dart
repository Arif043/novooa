import 'package:get_it/get_it.dart';
import 'package:novooa_runtime_client/novooa_runtime_client.dart';

/// Registriert die drei Transportwege zur Runtime (JSON, Binär, Realtime).
///
/// Alle Standalone-Repositories hängen nur an diesen Schnittstellen. Wer sie
/// austauscht (siehe `preview_dependency_configuration.dart`), betreibt die
/// komplette Oberfläche ohne Runtime.
typedef StandaloneTransportRegistration =
    void Function(GetIt locator, RuntimeProfile profile);

void registerHttpWorkspaceTransport(GetIt locator, RuntimeProfile profile) {
  final credentials = createRuntimeCredentialStore();
  final endpoint = RuntimeEndpoint.fromUri(profile.workspaceApiUri);
  Future<String?> authHeader() async {
    final token = await credentials.sessionToken(endpoint.address);
    return token == null ? null : 'Bearer $token';
  }

  locator
    ..registerLazySingleton<WorkspaceApiClient>(
      () => SessionAwareWorkspaceApiClient(
        HttpWorkspaceApiClient(
          baseUri: profile.workspaceApiUri,
          authHeaderProvider: authHeader,
        ),
        locator<RuntimeSessionEvents>(),
      ),
    )
    ..registerLazySingleton<WorkspaceBinaryClient>(
      () => HttpWorkspaceBinaryClient(
        baseUri: profile.workspaceApiUri,
        authHeaderProvider: authHeader,
      ),
    )
    ..registerLazySingleton<WorkspaceRealtimeChannel>(
      () => WorkspaceRealtimeChannel(
        profile.workspaceApiUri,
        locator<WorkspaceApiClient>(),
      ),
      dispose: (channel) => channel.close(),
    );
}
