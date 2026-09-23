import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/platform/document_scan_support.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('unterstützt Android', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(documentScanSupportedOnThisPlatform(), isTrue);
  });

  test('unterstützt iOS', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(documentScanSupportedOnThisPlatform(), isTrue);
  });

  test('unterstützt macOS nicht', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    expect(documentScanSupportedOnThisPlatform(), isFalse);
  });

  test('unterstützt Windows nicht', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    expect(documentScanSupportedOnThisPlatform(), isFalse);
  });
}
