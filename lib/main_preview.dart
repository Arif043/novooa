import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/preview_dependency_configuration.dart';
import 'core/di/service_locator.dart';
import 'core/localization/localized_app.dart';
import 'core/logging/application_bloc_observer.dart';
import 'core/logging/developer_client_logger.dart';
import 'core/logging/logger.dart';
import 'core/runtime/runtime_profile.dart';
import 'main.dart' show MyApp;

/// Startet die Oberfläche **ohne Backend, Firebase, Lizenz und Anmeldung**.
///
/// Alle Daten liegen flüchtig im Speicher (siehe `docs/notes/ui-vorschau.md`).
/// Aufruf: `flutter run -t lib/main_preview.dart` oder das VS-Code-Profil
/// „novooa UI-Vorschau“.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  configureClientLogger(const DeveloperClientLogger());
  Bloc.observer = ApplicationBlocObserver();
  final profile = RuntimeProfile.forKind(RuntimeKind.standalone);
  registerPreviewSessionEvents(serviceLocator);
  await configureDependencies(
    runtimeProfile: profile,
    standaloneTransport: previewTransport,
  );
  runApp(localizedApp(MyApp(runtimeProfile: profile)));
}
