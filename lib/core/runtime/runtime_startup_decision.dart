import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'runtime_kind_preferences.dart';
import 'runtime_kind_store.dart';
import 'runtime_profile.dart';

/// Welche Betriebsvariante beim Start gilt.
///
/// Im Web bestimmt die Herkunft (nie eine Wahl). Nativ zählt zuerst eine
/// gespeicherte Wahl, danach ein `--dart-define=NOVOOA_RUNTIME`-Vorgabewert
/// (etwa für feste CI-/Dev-Builds); ist beides nicht gesetzt, startet die
/// App mit Cloud — die eigene Runtime bleibt über den Wechsel-Hinweis im
/// Login-Formular erreichbar (`RuntimeVariantSwitchHint` in
/// `AuthFormFooter`), ein eigener Auswahlbildschirm ist dafür nicht nötig.
/// Dieser Vorgabewert wird bewusst nicht gespeichert — er bleibt ein reiner
/// Fallback, keine getroffene Wahl.
Future<RuntimeKind> resolveStartupRuntimeKind({RuntimeKindStore? store}) async {
  if (kIsWeb) return RuntimeProfile.defaultKind;
  final kindStore = store ?? RuntimeKindPreferences(SharedPreferencesAsync());
  final persisted = await kindStore.load();
  return persisted ?? RuntimeProfile.configuredKind ?? RuntimeKind.cloud;
}
