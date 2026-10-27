# Modellkatalog

> Übersicht aller Modelle, die in den Katalog aufgenommen werden oder wurden; jede Zeile verlinkt den Journal-Eintrag mit Herkunft, Lizenz, Prüfungen und Verlauf.

- [Modell-Journal](../notes/modell-journal.md) — Ablauf beim Import und Vorlage

## Modelle

| Modell | Version | Aufgabe | Lizenz | Status | Stand |
| --- | --- | --- | --- | --- | --- |
| [PP-OCRv3 Texterkennung](../../models/pp-ocr-v3/detector/JOURNAL.md) | `rapidocr-3.9.2` | `optical-character-recognition` | Apache 2.0 | geprüft | 2026-10-26 |
| [PP-OCRv3 Latin Texterkennung](../../models/pp-ocr-v3/recognizer/JOURNAL.md) | `rapidocr-3.9.2` | `optical-character-recognition` | Apache 2.0 | geprüft | 2026-10-26 |
| [PP-OCRv5 Server Texterkennung](../../models/pp-ocr-v5/server-recognizer/JOURNAL.md) | `paddleocr-v5-server-onnx` | `optical-character-recognition` | Apache 2.0 | geprüft | 2026-10-26 |
| [PP-OCRv6 Small Texterkennung (Detektor)](../../models/pp-ocr-v6/detector/JOURNAL.md) | `rapidocr-3.9.2` | `optical-character-recognition` | Apache 2.0 | veröffentlicht | 2026-10-27 |
| [PP-OCRv6 Small Texterkennung (Recognizer)](../../models/pp-ocr-v6/recognizer/JOURNAL.md) | `rapidocr-3.9.2` | `optical-character-recognition` | Apache 2.0 | veröffentlicht | 2026-10-27 |
| [SqueezeNet 1.1](../../models/squeezenet-1.1/JOURNAL.md) | `1.1-7` | `image-classification` | BSD; ImageNet offen | in Prüfung | 2026-10-26 |
| [Piper Deutsch – Eva](../../models/piper-de-eva-x-low/JOURNAL.md) | `c10ece1a…` | `text-to-speech` | MIT; M-AILABS offen | in Prüfung | 2026-10-26 |
| [Piper Deutsch – Thorsten (mittel)](../../models/piper-de-thorsten-medium/JOURNAL.md) | `c10ece1a…` | `text-to-speech` | MIT; CC0 | in Prüfung | 2026-10-26 |
| [Piper Deutsch – Thorsten Emotional](../../models/piper-de-thorsten-emotional-medium/JOURNAL.md) | `375a0fe6…` | `text-to-speech` | MIT; CC0 | in Prüfung | 2026-10-26 |

## Offene Punkte

- Fachliche Referenztests für die übrigen Modelle; umgesetzt für PP-OCRv6 Small
  (siehe [Regeln für Transformationen](../notes/regeln-fuer-transformationen.md)).
- Lizenz von ImageNet-Gewichten (SqueezeNet) und M-AILABS (Eva) rechtlich klären.
- Prüfsummen und Trockenläufe für Modelle, deren Dateien nicht im Repo liegen.

## Verwandt

- [ML-Modelle](./ml-modelle.md)
- [Transformationen](./transformationen.md)
