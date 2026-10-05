import 'package:syscat2/core/di/service_locator.dart';

import 'workspace_capabilities.dart';

/// Gibt es in dieser Betriebsvariante Plugins? Ohne registrierte
/// [WorkspaceCapabilities] (z. B. in Widget-Tests) gilt: nein.
bool pluginsAvailable() =>
    serviceLocator.isRegistered<WorkspaceCapabilities>() &&
    serviceLocator<WorkspaceCapabilities>().plugins;
