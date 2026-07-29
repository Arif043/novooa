import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class FcmForegroundNotificationListener extends StatefulWidget {
  const FcmForegroundNotificationListener({
    super.key,
    required this.child,
    required this.onNotificationOpened,
    required this.onForegroundNotificationAction,
  });

  final Widget child;
  final ValueChanged<RemoteMessage> onNotificationOpened;
  final ValueChanged<RemoteMessage> onForegroundNotificationAction;

  @override
  State<FcmForegroundNotificationListener> createState() =>
      _FcmForegroundNotificationListenerState();
}

class _FcmForegroundNotificationListenerState
    extends State<FcmForegroundNotificationListener> {
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;

  @override
  void initState() {
    super.initState();
    _foregroundSubscription = FirebaseMessaging.onMessage.listen(_showMessage);
    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      widget.onNotificationOpened,
    );
    unawaited(_openInitialMessage());
  }

  @override
  void dispose() {
    _foregroundSubscription?.cancel();
    _openedSubscription?.cancel();
    super.dispose();
  }

  Future<void> _openInitialMessage() async {
    final message = await FirebaseMessaging.instance.getInitialMessage();
    if (mounted && message != null) widget.onNotificationOpened(message);
  }

  void _showMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null || !mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            notification.body ?? notification.title ?? 'Neue Benachrichtigung',
          ),
          action: SnackBarAction(
            label: 'Öffnen',
            onPressed: () => widget.onForegroundNotificationAction(message),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
