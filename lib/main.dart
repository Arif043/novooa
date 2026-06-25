import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/routing/app_router.dart';
import 'core/theme/syscat_theme.dart';
import 'features/auth/infrastructure/repositories/firebase_auth_repository.dart';
import 'features/user/infrastructure/repositories/firestore_user_repository.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppRouter _appRouter = AppRouter(
    authRepository: FirebaseAuthRepository(FirebaseAuth.instance),
    userRepository: FirestoreUserRepository(FirebaseFirestore.instance),
  );

  @override
  void dispose() {
    _appRouter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Syscat',
      theme: SyscatTheme.lightTheme,
      routerConfig: _appRouter.router,
    );
  }
}
