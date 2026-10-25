import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novooa_runtime_client/novooa_runtime_client.dart';

void main() {
  test('browser names come from the user agent, most specific first', () {
    const agents = {
      'Mozilla/5.0 (Macintosh) AppleWebKit/537.36 Chrome/130.0 Safari/537.36':
          'Chrome',
      'Mozilla/5.0 (Windows NT 10.0) Chrome/130.0 Safari/537.36 Edg/130.0':
          'Edge',
      'Mozilla/5.0 (X11; Linux x86_64; rv:131.0) Gecko/20100101 Firefox/131.0':
          'Firefox',
      'Mozilla/5.0 (iPhone) AppleWebKit/605.1.15 Version/18.0 Safari/604.1':
          'Safari',
      'Mozilla/5.0 (iPhone) AppleWebKit/605.1.15 CriOS/130.0 Safari/604.1':
          'Chrome',
    };
    for (final MapEntry(key: agent, value: name) in agents.entries) {
      expect(browserNameFromUserAgent(agent), name, reason: agent);
    }
    expect(browserNameFromUserAgent('curl/8.0'), isNull);
  });

  test('the current device names the app and the platform', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    final device = RuntimeDevice.current(app: 'novooa');

    expect(device.toJson(), {
      'app': 'novooa',
      'os': 'windows',
      'browser': null,
    });
  });
}
