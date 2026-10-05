import 'package:syscat2/core/di/service_locator.dart';

import 'workspace_capabilities.dart';

/// Können externe Systeme in dieser Betriebsvariante Auslöser aufrufen? Ohne
/// registrierte [WorkspaceCapabilities] (z. B. in Widget-Tests) gilt: nein.
bool webhooksAvailable() =>
    serviceLocator.isRegistered<WorkspaceCapabilities>() &&
    serviceLocator<WorkspaceCapabilities>().webhooks;
