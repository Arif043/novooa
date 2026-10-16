# Adaptive Datums- und Zeitauswahl

> Unter 600 px öffnet die Datums-/Zeitauswahl ein Bottom Sheet mit Drehrad, darüber den Material-Dialog.

Gehört zu: [Zeitplan](../index/zeitplan.md)

Die Regel kommt von `showAdaptiveSheet`:

- **Handy bzw. Fenster unter 600 px:** Bottom Sheet mit Drehrad und den
  Aktionen „Abbrechen“ / „Fertig“.
- **Desktop ab 600 px** (macOS, Windows, Linux): Kalender- bzw.
  Uhrzeit-Dialog von Material.

Die Picker folgen der App-Sprache über `context.localizationDelegates`
(easy_localization, inklusive `flutter_localizations`).

## Siehe auch

- [Dialog „Auslöser hinzufügen“](./ausloeser-dialog.md)
