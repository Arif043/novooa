import 'package:get_it/get_it.dart';

import '../../features/integrations/integration_nodes.dart';
import '../runtime/runtime_profile.dart';
import 'connection_dependency_registration.dart';
import 'google_account_dependency_registration.dart';
import 'password_settings_dependencies.dart';
import 'standalone_dependency_configuration.dart';
import 'standalone_transport_registration.dart';

final serviceLocator = GetIt.instance;

Future<void> configureDependencies({
  RuntimeProfile? runtimeProfile,
  StandaloneTransportRegistration? standaloneTransport,
}) async {
  await configureStandaloneDependencies(
    serviceLocator,
    runtimeProfile ?? RuntimeProfile.fromEnvironment(),
    registerTransport: standaloneTransport ?? registerHttpWorkspaceTransport,
  );
  registerConnectionDependencies(serviceLocator);
  registerGoogleAccountDependencies(serviceLocator);
  registerPasswordSettingsDependencies(serviceLocator);
  registerIntegrationNodes();
}

/// Leert den Container, damit [configureDependencies] nach dem Abmelden
/// erneut laufen kann; ohne Reset kollidierte die zweite Registrierung.
Future<void> resetDependencies() => serviceLocator.reset();
