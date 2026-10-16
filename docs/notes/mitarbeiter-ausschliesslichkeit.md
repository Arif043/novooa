# Ausschließlichkeit von Mitarbeiter und Fähigkeiten

> Ein Baustein hat entweder einen Mitarbeiter (dessen Fähigkeiten er bekommt) oder eigene Fähigkeiten, nie beides; die Regel gilt in Config, Oberfläche und Backend.

Gehört zu: [Mitarbeiter](../index/mitarbeiter.md) · [Fähigkeiten](../index/faehigkeiten.md)

- **Config (Flutter):** `resolveNodeDelegation` — wer zuletzt etwas Konkretes
  setzt, gewinnt. `assignEmployee` leert die Fähigkeiten, `attachSkill`
  entfernt den Mitarbeiter; eine leere Fähigkeitenliste lässt den Mitarbeiter
  bestehen. Der Mapper bereinigt Dokumente mit beidem (Mitarbeiter gewinnt).
- **Oberfläche:** Das gemeinsame Auswahlfeld (Segmente *Fähigkeiten |
  Mitarbeiter*) räumt beim Wechsel die andere Seite auf und weist darauf hin.
- **Backend:** `assertExclusiveDelegation` lehnt Bausteine mit beidem ab („Ein
  Baustein kann nicht zugleich einen Mitarbeiter und Fähigkeiten haben …“),
  bevor etwas angelegt wird.

## Siehe auch

- [Mitarbeiter](./mitarbeiter.md)
- [Fähigkeiten an Bausteinen](./skills-an-bausteinen.md)
