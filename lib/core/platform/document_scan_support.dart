import 'package:flutter/foundation.dart';

/// Android und iOS scannen mit einem nativen Plugin (Android: ML Kit, iOS:
/// VisionKit über `cunning_document_scanner`), der Browser mit dem eigenen
/// Scanner aus `features/document_scan`. Von Task-Builder (Anzeige der Option)
/// und Activity (tatsächliche Aufnahme) gemeinsam genutzt, damit
/// Builder-Sichtbarkeit und Laufzeit-Verhalten nie auseinanderlaufen.
///
/// Bewusst über `defaultTargetPlatform` statt `dart:io Platform`, weil Letzteres
/// einen Konditionalimport für Web bräuchte — `defaultTargetPlatform` löst
/// Flutter selbst plattformneutral auf (siehe auch
/// `RuntimeProfile.fromEnvironment()` für dasselbe `kIsWeb`-Muster).
bool nativeDocumentScanSupportedOnThisPlatform() {
  return !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
}

bool webDocumentScanSupportedOnThisPlatform() => kIsWeb;

bool documentScanSupportedOnThisPlatform() {
  return nativeDocumentScanSupportedOnThisPlatform() ||
      webDocumentScanSupportedOnThisPlatform();
}
