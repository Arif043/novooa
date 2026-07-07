import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebaseEmulatorConfig {
  const FirebaseEmulatorConfig({
    this.authPort = 9099,
    this.firestorePort = 8080,
  });

  static const enabled = bool.fromEnvironment('USE_FIREBASE_EMULATORS');

  static const configuredHost = String.fromEnvironment(
    'FIREBASE_EMULATOR_HOST',
  );

  final int authPort;
  final int firestorePort;

  Future<void> connect() async {
    final host = configuredHost.isEmpty ? _defaultHost : configuredHost;
    await FirebaseAuth.instance.useAuthEmulator(host, authPort);
    FirebaseFirestore.instance.useFirestoreEmulator(host, firestorePort);
  }

  String get _defaultHost {
    if (kIsWeb) {
      return 'localhost';
    }

    return defaultTargetPlatform == TargetPlatform.android
        ? '10.0.2.2'
        : 'localhost';
  }
}
