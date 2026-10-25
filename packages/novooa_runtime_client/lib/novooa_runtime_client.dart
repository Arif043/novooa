/// Verbindung, Anmeldung, HTTP- und Echtzeit-Zugriff auf eine novooa-Runtime.
///
/// Headless: keine Oberfläche und keine Texte. Fehler kommen als
/// [RuntimeAccessFailure]; jede App formuliert sie in ihrer Sprache.
library;

export 'src/access/runtime_access_failure.dart';
export 'src/access/runtime_credential_store.dart';
export 'src/access/runtime_credential_store_factory.dart';
export 'src/access/runtime_login_client.dart';
export 'src/access/runtime_onboarding_client.dart';
export 'src/access/runtime_session_events.dart';
export 'src/access/tab_session_credential_store.dart';
export 'src/connection/runtime_connection_cubit.dart';
export 'src/connection/runtime_connection_failure.dart';
export 'src/connection/runtime_connection_state.dart';
export 'src/device/browser_name_from_user_agent.dart';
export 'src/device/runtime_device.dart';
export 'src/endpoint/http_runtime_availability.dart';
export 'src/endpoint/runtime_availability.dart';
export 'src/endpoint/runtime_endpoint.dart';
export 'src/endpoint/runtime_endpoint_preferences.dart';
export 'src/endpoint/runtime_endpoint_store.dart';
export 'src/endpoint/runtime_profile.dart';
export 'src/transport/network_status.dart';
export 'src/transport/session_aware_workspace_api_client.dart';
export 'src/transport/workspace_api_client.dart';
export 'src/transport/workspace_binary_client.dart';
export 'src/transport/workspace_realtime_channel.dart';
