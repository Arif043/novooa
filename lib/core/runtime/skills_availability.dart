import 'package:syscat2/core/di/service_locator.dart';

import 'workspace_capabilities.dart';

/// Gibt es in dieser Betriebsvariante Fähigkeiten? Ohne registrierte
/// [WorkspaceCapabilities] (z. B. in Widget-Tests) gilt: nein.
bool skillsAvailable() =>
    serviceLocator.isRegistered<WorkspaceCapabilities>() &&
    serviceLocator<WorkspaceCapabilities>().skills;
