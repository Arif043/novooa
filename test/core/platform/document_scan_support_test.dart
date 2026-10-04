import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/platform/document_scan_support.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('Android und iOS scannen nativ', () {
    for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
      debugDefaultTargetPlatformOverride = platform;
      expect(nativeDocumentScanSupportedOnThisPlatform(), isTrue);
      expect(documentScanSupportedOnThisPlatform(), isTrue);
    }
  });

  test('macOS und Windows scannen weder nativ noch im Browser', () {
    for (final platform in [TargetPlatform.macOS, TargetPlatform.windows]) {
      debugDefaultTargetPlatformOverride = platform;
      expect(nativeDocumentScanSupportedOnThisPlatform(), isFalse);
      expect(webDocumentScanSupportedOnThisPlatform(), isFalse);
      expect(documentScanSupportedOnThisPlatform(), isFalse);
    }
  });
}
