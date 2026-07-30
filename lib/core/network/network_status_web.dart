import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

class NetworkStatus {
  Stream<bool> watch() {
    return Stream.multi((controller) {
      controller.add(web.window.navigator.onLine);
      final onlineListener = ((web.Event _) => controller.add(true)).toJS;
      final offlineListener = ((web.Event _) => controller.add(false)).toJS;
      web.window
        ..addEventListener('online', onlineListener)
        ..addEventListener('offline', offlineListener);
      controller.onCancel = () {
        web.window
          ..removeEventListener('online', onlineListener)
          ..removeEventListener('offline', offlineListener);
      };
    }, isBroadcast: true);
  }
}
