# Mehrsprachige Manifeste

> `title` und `description` sind englisch und Rückfallsprache; `translations` ergänzt weitere Sprachen je BCP-47-Code.

Gehört zu: [ML-Modelle](../index/ml-modelle.md)

```json
"translations": {
  "de": {"title": "SqueezeNet 1.1", "description": "Klassifiziert ein Bild."}
}
```

- Tags werden nicht je Manifest übersetzt; ihre Bezeichnungen stehen einmal
  im [Tag-Vokabular](./modell-tag-vokabular.md). Früher übersetzte `tags`
  werden beim Lesen ignoriert.
- Auflösung: exakter Code, dann reine Sprache (`pt-BR` → `pt`), sonst
  Englisch.
- Persistiert in Firestore, SQLite (`model_catalog.translations_json`) und
  den lokalen Dateien.
- Labels von Einstellungen sind noch nicht übersetzbar.

## Siehe auch

- [ML-Katalogeintrag](./ml-katalogeintrag.md)
- [Modell-Settings](./modell-settings.md)
