# Mehrsprachige Manifeste

> `title` und `description` sind englisch und Rückfallsprache; `translations` ergänzt weitere Sprachen je BCP-47-Code.

Gehört zu: [ML-Modelle](../index/ml-modelle.md)

```json
"translations": {
  "de": {"title": "SqueezeNet 1.1", "description": "Klassifiziert ein Bild.", "tags": ["bild"]}
}
```

- Ohne `tags` gelten die Tags der Rückfallsprache; übersetzte Tags folgen
  denselben Regeln (nicht leer, eindeutig).
- Auflösung: exakter Code, dann reine Sprache (`pt-BR` → `pt`), sonst
  Englisch.
- Persistiert in Firestore, SQLite (`model_catalog.translations_json`) und
  den lokalen Dateien.
- Labels von Einstellungen sind noch nicht übersetzbar.

## Siehe auch

- [ML-Katalogeintrag](./ml-katalogeintrag.md)
- [Modell-Settings](./modell-settings.md)
