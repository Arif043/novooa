# Regeln für Transformationen

> Neue Transformationen sind allgemein statt modellspezifisch und kommen mit fachlichen Testfällen, die zeigen, dass ein Modell mit ihnen richtig rechnet.

Gehört zu: [Transformationen](../index/transformationen.md) · [ML-Modelle](../index/ml-modelle.md)

Ziel ist ein Sättigungspunkt: Neue Modelle lassen sich allein über ein
Manifest importieren, ohne neuen Code im ML-Dienst.

## Allgemein statt modellspezifisch

- Eine Transformation beschreibt ein **Verfahren** (skalieren, dekodieren,
  zusammenführen), nicht ein Modell. Name nach Bereich und Wirkung
  (`image.resizePad`, `tensor.nonMaximumSuppression`), nie nach einem Modell.
- Modellabhängiges steht in den **Parametern**: Spaltenindizes, Normwerte,
  Labels, Strides. So deckt eine Strategie viele Modellfamilien ab.
- Vor einer neuen Transformation prüfen: Reicht ein **neuer Parameter** an
  einer bestehenden oder eine **Kette** bestehender Transformationen?
- **Ausnahme nur im Worst Case:** wenn ein Verfahren untrennbar an die
  Vorverarbeitung eines Modells gebunden ist und sich ohne Verlust nicht
  allgemein fassen lässt — bisher `text.piperPhonemes`,
  `text.piperPhonemeLength`, `text.kokoroTokens` und `text.kokoroStyle`.
  Die Notiz der Transformation nennt die Ausnahme und ihren Grund.

## Fachliche Testfälle

Eine Transformation ist erst fertig, wenn Tests zeigen, dass sie **fachlich**
dasselbe rechnet wie die Referenz — nicht nur, dass sie läuft:

1. **Referenzwerte:** Ergebnis gegen eine unabhängige Quelle prüfen — die
   Vorverarbeitung der Originalimplementierung des Modells (z. B. ein
   Feature-Extractor), eine etablierte Bibliothek (librosa, Pillow, NumPy)
   oder von Hand nachgerechnete Werte; mit Toleranz bei Gleitkommazahlen.
2. **Jeder Parameter:** mindestens einmal mit einem anderen Wert als dem
   Standard; Wechselwirkungen (etwa `min ≤ max`) eigens.
3. **Grenzfälle:** leere oder einelementige Eingaben, Ränder, Batch-Achsen,
   dynamische Formen.
4. **Fehlerfälle:** falsche Wertart, falsche Form, ungültige Parameter —
   jeweils mit verständlicher Meldung.
5. **Ende zu Ende**, wenn die Transformation für ein Modell eingeführt wird:
   Kette aus Eingang, ONNX-Modell (echt oder verkleinert als Fixture unter
   `local-runtime/python/tests/fixtures/`) und Ausgang gegen eine
   gespeicherte Referenzausgabe.

Referenztests je Katalogmodell — Referenzeingabe und erwartete Ausgabe aus
der Originalimplementierung, bei jeder Änderung am ML-Dienst geprüft — sind
**geplant**.

## Pflichten beim Hinzufügen

- Strategie als eigene Datei im Bereichsordner, mit `accepts`, `produces` und
  Parameterschema ([Aufbau des Python-ML-Dienstes](./python-ml-dienst-aufbau.md)).
- Eigene Notiz `transformation-<typ>.md` nach dem Muster der bestehenden
  (Wertart, Parameter, Beispiel, **Fachliche Tests**, Siehe auch) und ein
  Eintrag im Inhaltsverzeichnis [Transformationen](../index/transformationen.md).
- `tests/test_transformation_architecture.py` prüft: eine Notiz je Typ, jeder
  Parameter genannt, Eintrag im Inhaltsverzeichnis, genannte Testdateien
  existieren und enthalten den Typ.

## Siehe auch

- [Deklarative Transformationen](./transformationen-deklarativ.md)
- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
- [Vertragsprüfung](./ml-vertragspruefung.md)
