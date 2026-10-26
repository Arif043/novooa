# Modellaufgaben, Sprachen und Tags

> Modelle werden nach dem **Was** gefunden (Aufgabe, Sprache), nicht nach dem **Wie** (SVM, CNN).

Gehört zu: [ML-Modelle](../index/ml-modelle.md)

**`task`** (Pflicht): genau eine Aufgabe aus festem Vokabular
(`domain/entities/model-task.ts`), überwiegend Hugging-Face-Pipeline-Tags;
★ = eigene Ergänzung.

| Bereich | Aufgaben |
| --- | --- |
| Bild & Video | `image-classification`, `object-detection`, `image-segmentation`, `optical-character-recognition` ★, `document-question-answering`, `depth-estimation`, `keypoint-detection`, `zero-shot-image-classification`, `image-to-image`, `video-classification` |
| Audio | `text-to-speech`, `automatic-speech-recognition`, `audio-classification`, `voice-activity-detection`, `speaker-diarization` ★, `audio-to-audio` |
| Text | `text-classification`, `token-classification`, `question-answering`, `zero-shot-classification`, `sentence-similarity`, `feature-extraction` |
| Daten & Zeitreihen | `tabular-classification`, `tabular-regression`, `time-series-forecasting`, `anomaly-detection` ★, `clustering` ★ |
| Sonstige | `other` |

- Unbekannte Werte lehnen Publishing und Import ab. Gespeicherte Einträge ohne,
  mit entfernter oder noch unbekannter Aufgabe lesen Runtime und App als
  „Sonstige“, damit ein einzelner Eintrag den Katalog nicht blockiert.
- Generative Aufgaben (`text-generation`, `translation`, `summarization`,
  `image-to-text`) fehlen bewusst; sie laufen über Sprachmodelle
  ([Entscheidung](./generative-modelle-ueber-sprachmodelle-entscheidung.md)).
- Neue Aufgabe: `model-task.ts` (Runtime), `model_task.dart` und Bezeichnung
  in `model_task_label.dart` (App).

**`languages`** (optional): BCP-47-Codes; leer bei sprachunabhängigen
Modellen. **`tags`**: Schlüssel aus dem
[Tag-Vokabular](./modell-tag-vokabular.md) für Fachthemen und Merkmale
(`invoices`, `animals`, `lightweight`); Aufgabe und Sprache stehen in
`task` und `languages`.

**Mehrere Aufgaben** (z. B. transkribieren und übersetzen) → je Aufgabe ein
eigener Eintrag mit eigenem Vertrag. Alle verweisen auf dieselbe
Artefaktversion; die Datei wird erst entfernt, wenn kein Eintrag sie nutzt.

SQLite: `model_catalog.task`, `model_catalog.languages_json` (Migration
`0021_model_catalog_task.sql`).

## Siehe auch

- [Modellsuche](./modellsuche.md)
- [Mehrsprachige Manifeste](./mehrsprachige-manifeste.md)
