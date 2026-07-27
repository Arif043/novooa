import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

abstract interface class FcmTokenProvider {
  Stream<String> get tokenRefreshes;

  Future<String?> currentToken();

  Future<void> deleteToken();

  String get platform;
}

class FirebaseMessagingTokenProvider implements FcmTokenProvider {
  const FirebaseMessagingTokenProvider(this._messaging);

  static const webVapidKey =
      "BE4RdSC6jI9sQaW4qQCpXcco55YdbLEyPjf3WTyLe2R7aUU0vr4SMC7JaZ-nespbAuoZbCqWQov_5yLXfaw4X8M";

  final FirebaseMessaging _messaging;

  @override
  Stream<String> get tokenRefreshes => _messaging.onTokenRefresh;

  @override
  Future<String?> currentToken() async {
    final settings = await _messaging.requestPermission(provisional: true);
    if (!_isAllowed(settings.authorizationStatus)) return null;
    if (kIsWeb && webVapidKey.isEmpty) return null;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final apnsToken = await _messaging.getAPNSToken();
      if (apnsToken == null) return null;
    }
    final current = await _messaging.getToken(
      vapidKey: kIsWeb ? webVapidKey : null,
    );
    debugPrint("FCM Token: $current");
    return current;
  }

  @override
  Future<void> deleteToken() {
    return _messaging.deleteToken();
  }

  @override
  String get platform {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform.name;
  }

  bool _isAllowed(AuthorizationStatus status) {
    return status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional;
  }
}
