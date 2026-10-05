import 'package:syscat2/core/di/service_locator.dart';

import 'workspace_capabilities.dart';

/// Gibt es in dieser Betriebsvariante Verbindungen zu externen Systemen? Ohne
/// registrierte [WorkspaceCapabilities] (z. B. in Widget-Tests) gilt: nein.
bool connectionsAvailable() =>
    serviceLocator.isRegistered<WorkspaceCapabilities>() &&
    serviceLocator<WorkspaceCapabilities>().connections;
