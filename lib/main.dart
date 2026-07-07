import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/di/service_locator.dart';
import 'core/firebase/firebase_emulator_config.dart';
import 'core/routing/app_router.dart';
import 'core/theme/syscat_theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (FirebaseEmulatorConfig.enabled) {
    await const FirebaseEmulatorConfig().connect();
  }
  configureDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Syscat',
      debugShowCheckedModeBanner: false,
      theme: SyscatTheme.lightTheme,
      routerConfig: serviceLocator<AppRouter>().router,
    );
  }
}
