import 'package:get_it/get_it.dart';

import '../network/preview/in_memory_workspace_api_client.dart';
import '../network/preview/in_memory_workspace_store.dart';
import '../network/preview/in_memory_workspace_transport.dart';
import '../network/workspace_api_client.dart';
import '../network/workspace_binary_client.dart';
import '../network/workspace_realtime_channel.dart';
import '../runtime/runtime_profile.dart';
import '../runtime/runtime_session_events.dart';
import 'standalone_transport_registration.dart';

/// Transportwege der UI-Vorschau: alles läuft im Speicher, es gibt weder
/// Runtime noch Lizenz oder Anmeldung.
void registerPreviewWorkspaceTransport(GetIt locator, RuntimeProfile profile) {
  final store = InMemoryWorkspaceStore();
  locator
    ..registerLazySingleton<InMemoryWorkspaceStore>(
      () => store,
      dispose: (store) => store.close(),
    )
    ..registerLazySingleton<WorkspaceApiClient>(
      () => InMemoryWorkspaceApiClient(store),
    )
    ..registerLazySingleton<WorkspaceBinaryClient>(
      () => const InMemoryWorkspaceBinaryClient(),
    )
    ..registerLazySingleton<WorkspaceRealtimeChannel>(
      () => InMemoryWorkspaceRealtimeChannel(store),
    );
}

/// Vom Einstiegspunkt der Vorschau an `configureDependencies` übergeben.
const StandaloneTransportRegistration previewTransport =
    registerPreviewWorkspaceTransport;

/// Die Sitzungsereignisse gehören sonst dem Verbindungs-Gate.
void registerPreviewSessionEvents(GetIt locator) {
  if (locator.isRegistered<RuntimeSessionEvents>()) return;
  locator.registerSingleton<RuntimeSessionEvents>(RuntimeSessionEvents());
}
