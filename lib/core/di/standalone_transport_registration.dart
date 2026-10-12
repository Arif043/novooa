import 'package:get_it/get_it.dart';

import '../network/session_aware_workspace_api_client.dart';
import '../network/workspace_api_client.dart';
import '../network/workspace_binary_client.dart';
import '../network/workspace_realtime_channel.dart';
import '../runtime/runtime_credential_store.dart';
import '../runtime/runtime_endpoint.dart';
import '../runtime/runtime_profile.dart';
import '../runtime/runtime_session_events.dart';

/// Registriert die drei Transportwege zur Runtime (JSON, Binär, Realtime).
///
/// Alle Standalone-Repositories hängen nur an diesen Schnittstellen. Wer sie
/// austauscht (siehe `preview_dependency_configuration.dart`), betreibt die
/// komplette Oberfläche ohne Runtime.
typedef StandaloneTransportRegistration =
    void Function(GetIt locator, RuntimeProfile profile);

void registerHttpWorkspaceTransport(GetIt locator, RuntimeProfile profile) {
  final credentials = SecureRuntimeCredentialStore();
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
