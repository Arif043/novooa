# Tag-Vokabular der Modelle

> Modell-Tags sind Schlüssel aus einem kontrollierten Vokabular mit Bezeichnungen (en/de/tr), Synonymen und optionalem Obertag; gesucht wird nach fachlichen Themen, nicht nach Modellart.

Gehört zu: [ML-Modelle](../index/ml-modelle.md)

```json
// models/tags.json
{"tags": [
  {"key": "documents", "labels": {"en": "Documents", "de": "Dokumente", "tr": "Belgeler"}},
  {"key": "invoices", "parent": "documents",
   "labels": {"en": "Invoices", "de": "Rechnungen", "tr": "Faturalar"},
   "synonyms": {"de": ["Rechnung"], "en": ["invoice", "bill"]}}
]}
```

Ein Manifest nennt nur Schlüssel: `"tags": ["invoices", "lightweight"]`.

- **Regeln:** Schlüssel in ASCII-Kebab-Schreibweise, eindeutig; `labels.en`
  ist Pflicht; ein Obertag muss existieren und darf selbst keinen haben
  (höchstens zwei Ebenen). Tags ohne Kinder sind erlaubt, auch für
  Eigenschaften wie `lightweight` oder `high-quality`. Der Test
  `shipped-model-manifests.test.ts` verlangt Bezeichnungen in allen
  App-Sprachen und prüft jedes mitgelieferte Manifest.
- **Allgemeine Ebene:** Bereich und Aufgabe kommen aus `task` und sind
  ohne eigenen Tag durchsuchbar; Tags tragen nur Fachthemen und Merkmale.
- **Vererbung:** Ein Modell mit `invoices` gehört auch zu `documents`; die
  Suche nach „Dokumente“ oder dem Synonym „Rechnung“ findet es.
- **Quelle und Verteilung:** `models/tags.json` im Repo →
  `models:tags:publish` → Firestore `modelTags/{key}` (anlegen und
  aktualisieren, nie löschen). Die Runtime liest es nach der
  Firebase-Anmeldung und spiegelt es in SQLite (`model_tags`,
  `CachedModelTagVocabulary`); offline gilt der letzte Spiegel.
- **Prüfung:** Veröffentlichung, lokale Installation und Import eigener
  Modelle lehnen unbekannte Tags ab, der Import schon vor dem Upload.
  Gespeicherte Einträge mit alten Freitext-Tags bleiben lesbar und gelten
  als Text.
- **App:** `GET /v1/ml-models/tags` liefert das Vokabular; der Suchdialog
  zeigt Tag-Bezeichnungen in der Sprache der Oberfläche und Chips „Themen“
  (Obertags mit Trefferzahl).

Warum kontrolliert und im globalen Katalog: Freie Tags zerfallen in
Schreibweisen und Sprachen; ein Vokabular übersetzt jeden Tag einmal, und
neue Themen gehen ohne App-Release live.

## Siehe auch

- [Modellaufgaben, Sprachen und Tags](./modellaufgaben-und-sprachen.md)
- [Modellsuche](./modellsuche.md)
- [Modelle veröffentlichen](./modelle-veroeffentlichen.md)
