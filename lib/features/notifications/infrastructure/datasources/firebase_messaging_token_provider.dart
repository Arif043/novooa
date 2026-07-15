import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FirebaseMessagingTokenProvider {
  const FirebaseMessagingTokenProvider(this._messaging);

  static const webVapidKey = String.fromEnvironment('FCM_WEB_VAPID_KEY');

  final FirebaseMessaging _messaging;

  Stream<String> get tokenRefreshes => _messaging.onTokenRefresh;

  Future<String?> currentToken() async {
    final settings = await _messaging.requestPermission(provisional: true);
    if (!_isAllowed(settings.authorizationStatus)) return null;
    if (kIsWeb && webVapidKey.isEmpty) return null;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final apnsToken = await _messaging.getAPNSToken();
      if (apnsToken == null) return null;
    }
    return _messaging.getToken(vapidKey: kIsWeb ? webVapidKey : null);
  }

  Future<void> deleteToken() {
    return _messaging.deleteToken();
  }

  String get platform {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform.name;
  }

  bool _isAllowed(AuthorizationStatus status) {
    return status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional;
  }
}
