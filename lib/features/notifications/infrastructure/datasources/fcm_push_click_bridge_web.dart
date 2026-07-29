import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'fcm_push_click_payload.dart';

typedef FcmPushClickCallback = void Function(Map<String, dynamic> data);

@JS('__novooaTakeFcmPushClicks')
external JSArray<JSAny?> _takeQueuedPushClicks();

class FcmPushClickBridge {
  const FcmPushClickBridge();

  void start(FcmPushClickCallback onPushClick) {
    web.window.navigator.serviceWorker.addEventListener(
      'message',
      ((web.Event event) => _forwardClick(event, onPushClick)).toJS,
    );
    for (final payload in _takeQueuedPushClicks().toDart) {
      _forwardPayload(payload.dartify(), onPushClick);
    }
  }

  void _forwardClick(web.Event event, FcmPushClickCallback onPushClick) {
    final payload = (event as web.MessageEvent).data.dartify();
    _forwardPayload(payload, onPushClick);
  }

  void _forwardPayload(Object? payload, FcmPushClickCallback onPushClick) {
    final data = fcmPushClickData(payload);
    if (data != null) onPushClick(data);
  }
}
