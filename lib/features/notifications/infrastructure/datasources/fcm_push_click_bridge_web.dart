import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'fcm_push_click_payload.dart';

typedef FcmPushClickCallback = void Function(Map<String, dynamic> data);

class FcmPushClickBridge {
  const FcmPushClickBridge();

  void start(FcmPushClickCallback onPushClick) {
    web.window.navigator.serviceWorker.addEventListener(
      'message',
      ((web.Event event) => _forwardClick(event, onPushClick)).toJS,
    );
  }

  void _forwardClick(web.Event event, FcmPushClickCallback onPushClick) {
    final payload = (event as web.MessageEvent).data.dartify();
    final data = fcmPushClickData(payload);
    if (data != null) onPushClick(data);
  }
}
