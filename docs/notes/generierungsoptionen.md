# Generierungsoptionen

> Ein Prompt-Baustein kann Temperatur, Antwortlänge, Kontextfenster und Nachdenken festlegen; die Domain beschreibt sie anbieterneutral, je Anbieter übersetzt eine Genkit-Strategie sie.

Gehört zu: [Aufgabe](../index/aufgabe.md)

- **Gespeichert** als `generationOptions` in der Prompt-Konfiguration; nur
  gesetzte Werte, fehlende bedeuten Modellstandard.
- **Domain:** `generation-options.ts` mit Value Objects `Temperature` (0–2),
  `TokenLimit` (ganzzahlig > 0) und `ThinkingMode`
  (`modelDefault | off | low | medium | high`). `generationOptionsFrom` lehnt
  ungültige Werte ab.
- **Strategie je Anbieter** (`GenkitGenerationConfig`, geliefert vom
  `CatalogGenkitLanguageModelResolver`, fürs Standardmodell von
  `textModelGenerationConfig`):

| Option | Ollama | Google | OpenAI-kompatibel |
| --- | --- | --- | --- |
| Temperatur | `temperature` | `temperature` | `temperature` |
| Antwortlänge | `num_predict` | `maxOutputTokens` | `max_tokens` |
| Kontextfenster | `num_ctx` | – (fest) | – (fest) |
| Nachdenken aus | `think: false` | 2.5: Budget 0, 3: `MINIMAL` (Pro: `LOW`) | – |
| Stufen | `think: "low"…` | 2.5: Budget 1024/8192/24576, 3: `thinkingLevel` | `reasoning_effort` |

- Das compat-oai-Plugin verwirft `maxOutputTokens`, reicht unbekannte Felder
  aber durch; daher `max_tokens` direkt.
- Gemini 2.5 und 3 dürfen Budget und Stufe nicht gemeinsam bekommen (400).
- **Ollama:** Ohne `num_ctx` wählt Ollama das Fenster selbst; mit Bildern und
  Nachdenken reicht es oft nicht (`done_reason: length`) oder es scheitert am
  Speicher. Für Bildmodelle 16384 eintragen. `think: false` ignoriert
  `qwen3-vl` in Ollama 0.40.5; das Modell denkt trotzdem.
- **Client:** eingeklappt unter „Erweitert“; das Kontextfenster erscheint nur
  bei einem Ollama-Modell (oder wenn schon gesetzt). Bild-Ausgaben ignorieren
  die Optionen.

## Siehe auch

- [Prompt-Executor](./prompt-executor.md)
- [Fehlerschichtung eines Modellaufrufs](./fehlerschichtung-modellaufruf.md)
- [Sprachmodell-Anbieter](./sprachmodell-anbieter.md)
