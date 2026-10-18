import 'package:syscat2/core/di/service_locator.dart';

import 'workspace_capabilities.dart';

/// Lassen sich in dieser Betriebsvariante Python-Pakete für Scripts
/// installieren? Ohne registrierte [WorkspaceCapabilities] (z. B. in
/// Widget-Tests) gilt: nein.
bool scriptPackagesAvailable() =>
    serviceLocator.isRegistered<WorkspaceCapabilities>() &&
    serviceLocator<WorkspaceCapabilities>().scriptPackages;
