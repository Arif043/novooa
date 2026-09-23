import 'package:flutter/foundation.dart';

/// Erkennt, ob die aktuelle Plattform einen nativen Dokumentenscanner
/// unterstützt (Android: ML Kit, iOS: VisionKit über
/// `cunning_document_scanner`). Von Task-Builder (Anzeige der Option) und
/// Activity (tatsächliche Aufnahme) gemeinsam genutzt, damit Builder-
/// Sichtbarkeit und Laufzeit-Verhalten nie auseinanderlaufen.
///
/// Bewadbusst über `defaultTargetPlatform` statt `dart:io Platform`, weil
/// Letzteres einen Konditionalimport für Web bräuchte — `defaultTargetPlatform`
/// löst Flutter selbst plattformneutral auf (siehe auch
/// `RuntimeProfile.fromEnvironment()` für dasselbe `kIsWeb`-Muster).
bool documentScanSupportedOnThisPlatform() {
  return !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
}
