import 'dart:async';
import '../../../../core/logging/syscat_log.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/notification_device_token.dart';
import '../../domain/usecases/register_notification_device.dart';
import '../../domain/usecases/unregister_notification_device.dart';
import '../datasources/firebase_messaging_token_provider.dart';

class FcmBootstrapper {
  FcmBootstrapper(
    this._authRepository,
    this._tokenProvider,
    this._registerDevice,
    this._unregisterDevice,
  );

  final AuthRepository _authRepository;
  final FirebaseMessagingTokenProvider _tokenProvider;
  final RegisterNotificationDevice _registerDevice;
  final UnregisterNotificationDevice _unregisterDevice;
  StreamSubscription<AuthUser?>? _authSubscription;
  StreamSubscription<String>? _tokenSubscription;
  AuthUser? _currentUser;
  String? _currentToken;

  Future<void> start() async {
    await _registerFor(_authRepository.currentUser());
    _authSubscription = _authRepository.authStateChanges().listen(_registerFor);
    _tokenSubscription = _tokenProvider.tokenRefreshes.listen(
      _saveRefreshedToken,
    );
  }

  Future<void> dispose() async {
    await _authSubscription?.cancel();
    await _tokenSubscription?.cancel();
  }

  Future<void> _registerFor(AuthUser? user) async {
    try {
      if (user == null) return _clearCurrentRegistration();
      _currentUser = user;
      final token = await _tokenProvider.currentToken();
      if (token == null) {
        logSyscatInfo('FCM-Token ist nicht verfügbar.', name: 'fcm');
        return;
      }
      await _saveToken(user, token);
    } catch (error, stackTrace) {
      logSyscatException(
        message: 'FCM-Registrierung fehlgeschlagen.',
        error: error,
        stackTrace: stackTrace,
        name: 'fcm',
      );
    }
  }

  Future<void> _saveRefreshedToken(String token) async {
    try {
      final user = _currentUser;
      if (user == null) return;
      await _saveToken(user, token);
    } catch (error, stackTrace) {
      logSyscatException(
        message: 'FCM-Token-Refresh konnte nicht gespeichert werden.',
        error: error,
        stackTrace: stackTrace,
        name: 'fcm',
      );
    }
  }

  Future<void> _saveToken(AuthUser user, String token) async {
    _currentToken = token;
    await _registerDevice(
      NotificationDeviceToken(
        userId: user.id.value,
        token: token,
        platform: _tokenProvider.platform,
      ),
    );
    logSyscatInfo('FCM-Token registriert.', name: 'fcm');
  }

  Future<void> _clearCurrentRegistration() async {
    final user = _currentUser;
    final token = _currentToken;
    _currentUser = null;
    _currentToken = null;
    try {
      if (user != null && token != null) {
        await _unregisterDevice(userId: user.id.value, token: token);
      }
      await _tokenProvider.deleteToken();
    } catch (error, stackTrace) {
      logSyscatException(
        message: 'FCM-Token konnte nicht entfernt werden.',
        error: error,
        stackTrace: stackTrace,
        name: 'fcm',
      );
    }
  }
}
