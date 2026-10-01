import 'package:flutter/painting.dart';

/// Farbpalette für Workflow-Ausgabetypen. Jede Farbe erreicht mit weißer
/// Schrift mindestens AA-Kontrast und bleibt in Hell- und Dunkelmodus lesbar.
class OutputTypeColors {
  static const Color string = Color(0xFF1E6FD9);
  static const Color datetime = Color(0xFF00838F);
  static const Color number = Color(0xFF7B3FC4);
  static const Color boolean = Color(0xFF2E7D32);
  static const Color json = Color(0xFF8D5524);
  static const Color file = Color(0xFF546E7A);
  static const Color media = Color(0xFFC2185B);
  static const Color table = Color(0xFF3949AB);
}
