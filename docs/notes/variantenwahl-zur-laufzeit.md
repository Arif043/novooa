# Variantenwahl zur Laufzeit

> Nativ wählen Nutzer:innen Cloud oder Standalone vor der Anmeldung; die Wahl wird gespeichert und gilt ab dem nächsten Start. `NOVOOA_RUNTIME` ist nur noch Vorgabe.

Gehört zu: [Betriebsvarianten](../index/betriebsvarianten.md)

- `lib/core/runtime/runtime_profile.dart`: `RuntimeProfile.forKind(kind)`,
  `defaultKind`, `configuredKind`, `runtimeKindOrNull(name)`,
  `supports(kind)`/`supportedKinds`.
- Gespeichert unter `novooa.runtime.kind`
  (`runtime_kind_store.dart`, `runtime_kind_preferences.dart`). Unbekannte
  oder hier nicht unterstützte Werte werden verworfen und entfernt.
- `main.dart` löst die Variante **vor** der Firebase-Initialisierung auf
  (`_resolveRuntimeProfile()`); ein Fehler im Speicher fällt auf die Vorgabe
  zurück.
- Umschalten nur vor der Anmeldung im Auth-Formular
  (`runtime_variant_switch_hint.dart`), weil die Einstellungen hinter dem Login
  liegen; ausgeblendet, wenn es nur eine Variante gibt (im Web immer).
- **Kein Wechsel im laufenden Prozess:** Firebase, DI-Graph und Anmeldung
  hängen an der Variante; ein Neustart ist ehrlicher als ein halb umgebauter
  Zustand. `resetDependencies()` existiert für Tests.
- **Kein erzwungener Auswahldialog beim Erststart:** Die Vorgabe greift, damit
  Builds, CI und Erstlauf unverändert bleiben.

## Siehe auch

- [Web-Herkunftsregel](./web-herkunftsregel.md)
- [Betriebsvarianten-Matrix](./betriebsvarianten-matrix.md)
