# Transformationskatalog

> Alle Transformationen des Python-ML-Dienstes mit Parametern und Wirkung; die Richtung (Ein- oder Ausgang) ergibt sich allein aus der Position in der Pipeline.

Gehört zu: [ML-Modelle](../index/ml-modelle.md)

„Eingang“/„Ausgang“ nennt nur den typischen Einsatz; jede Transformation ist
nutzbar, wo ihre [Wertart](./ml-wertarten-und-ketten.md) passt.
`local-runtime/python/tests/test_transformation_architecture.py` liest diese
Tabelle und verlangt jeden Typ mit allen Parametern.

| Transformation | Parameter | Wirkung |
| --- | --- | --- |
| `image.decode` | `colorSpace`: `rgb`, `rgba`, `grayscale` | Dekodiert und setzt den Farbraum. |
| `image.resize` | `width`, `height`, optional `colorSpace` | Skaliert mit LANCZOS. |
| `image.resizePad` | `width`, `height`, optional `alignment` (`topLeft` oder `center`), `background`, `colorSpace` | Erhält das Seitenverhältnis und füllt bis zur Zielgröße auf. |
| `image.resizeHeightPad` | `height`, optional `width` oder `widthMultiple`, optional `alignment`, `background`, `colorSpace` | Skaliert auf die Zielhöhe. Mit `width` wird bis zur festen Breite aufgefüllt bzw. abgeschnitten; ohne `width` bleibt die Breite dynamisch und kann auf ein Vielfaches aufgefüllt werden. |
| `image.padToMultiple` | `multiple`, optional `background`, `colorSpace` | Füllt rechts und unten bis zu einem Vielfachen auf; Bildkoordinaten bleiben erhalten. |
| `image.crop` | `left`, `top`, `width`, `height` | Schneidet einen achsenparallelen Bildbereich aus. |
| `image.perspectiveCrop` | `points` (`[x1, y1, … x4, y4]`), `width`, `height` | Richtet ein Viereck perspektivisch zu einem Bild aus. |
| `tensor.channelOrder` | `order`, etwa `[2, 1, 0]` | Ordnet Farbkanäle über eine vollständige Indexpermutation um. |
| `tensor.layout` | `order`: `channelsFirst`, `channelsLast` | Ordnet HWC und CHW um. |
| `tensor.normalize` | `mean`, `std` | Normalisiert jeden Farbkanal. |
| `tensor.softmax` | optional `axis` (nur `-1`) | Normalisiert Werte entlang der letzten Tensorachse. |
| `tensor.sigmoid` | keine | Wandelt Logits elementweise in Wahrscheinlichkeiten. |
| `tensor.threshold` | optional `value` (Standard `0.5`) | Wandelt numerische Werte in eine boolesche Maske. |
| `mask.connectedComponents` | optional `minimumPixels` | Liefert Regionen als `{bounds, pixelCount}`; `bounds` enthält `left`, `top`, `width`, `height`. |
| `mask.textRegions` | `threshold`, `minimumPixels`, `minimumScore`, `dilationWidth`, `dilationHeight`, `padding` | Leitet aus einer Wahrscheinlichkeitsmaske bewertete Textregionen ab. |
| `geometry.mergeRows` | `minimumVerticalOverlap` | Fasst horizontale Textregionen mit ausreichender vertikaler Überlappung zu einer Zeile zusammen. |
| `geometry.scaleBounds` | `scaleX`, `scaleY`, optional `offsetX`, `offsetY` | Rechnet eine Regionsliste vom Maskenraster in Bildkoordinaten zurück. |
| `tensor.nonMaximumSuppression` | `box` (Spalten als Ecken `left/top/right/bottom` oder Mittelpunkt `centerX/centerY/width/height`), `scoreIndex` oder `classScores` (`{start, end?}`), optional `objectnessIndex`, `classAware` (Standard `true`), `boxScale` (`{x, y}`, z. B. für normierte 0…1-Koordinaten), `scoreThreshold`, `iouThreshold`, `maxDetections` | Liest Erkennungen aus Zeilen und unterdrückt Überlappungen. Mit `classScores` gilt die beste Klasse (`classIndex`) und je Klasse wird unterdrückt; mit `objectnessIndex` wird deren Wert mit dem Score multipliziert (YOLOv5-Stil). Ergebnis `{index, score, box, classIndex?}`, `box` immer als Ecken. |
| `sequence.ctcGreedyDecode` | `labels`, `blankIndex`, optional `applySoftmax`, `collapseRepeated`, `allowedCharacters` | Dekodiert CTC-Logits in `{text, confidence}`; `allowedCharacters` begrenzt die Auswahl auf ein fachlich zulässiges Alphabet. |
| `tensor.topK` | `k` (Zahl oder Setting-Bindung wie `"$anzahl"`), optional `result`; veraltet `parameter` (wird beim Lesen zu einem Setting) | Liefert die `k` größten Werte als Paare aus Index und Wert. |
| `datetime.features` | `features` (Liste aus `year`, `month`, `day`, `weekday`, `hour`, `minute`, `second`, `dayOfYear`, `epochSeconds`), optional `cyclic`, `timeZone` | Eingang (Datum/Uhrzeit). Zerlegt einen Zeitpunkt in Zahlenmerkmale; `weekday` zählt ab Montag = 0. Mit `cyclic: true` werden Monat, Wochentag, Stunde, Minute und Jahrestag als sin/cos-Paar kodiert, sodass z. B. 23 Uhr und 0 Uhr nah beieinander liegen. `timeZone` (IANA, z. B. `Europe/Berlin`) wählt die Zählzeitzone, Standard UTC. |
| `image.exifTranspose` | keine | Eingang. Dreht Fotos gemäß EXIF-Ausrichtung (z. B. Handyaufnahmen); vor anderen Bildtransformationen einsetzen. |
| `image.resizeShorterSide` | `size` | Eingang. Skaliert die kürzere Seite auf `size`, das Seitenverhältnis bleibt. |
| `image.centerCrop` | `width`, `height` | Eingang. Schneidet einen Ausschnitt aus der Bildmitte; größer als das Bild ist ein Fehler. Mit `image.resizeShorterSide` die übliche Vorverarbeitung vieler Bildmodelle. |
| `number.toTensor` | keine | Eingang. Macht aus einer Zahl oder Zahlenliste einen eindimensionalen `float32`-Tensor. |
| `tensor.scale` | optional `factor` (Standard `1`), `offset` (Standard `0`) | Ein- und Ausgang. Berechnet `wert × factor + offset`, z. B. `1/255` für Pixel oder zum Zurückrechnen normierter Ausgaben. |
| `tensor.clip` | `min` und/oder `max` | Ein- und Ausgang. Begrenzt Werte auf einen Bereich. |
| `tensor.reshape` | `shape` (positive Zahlen, höchstens einmal `-1`) | Ein- und Ausgang. Formt den Tensor um; die Anzahl der Werte muss passen. |
| `tensor.transpose` | `axes` (vollständige Permutation) | Ein- und Ausgang. Ordnet Achsen um. Für Farbkanäle von Bildern bleibt `tensor.layout` vorzuziehen, weil `tensor.normalize` dessen Layout kennt. |
| `tensor.argmax` | optional `axis` (Standard `-1`) | Ausgang. Index des größten Werts, z. B. die wahrscheinlichste Klasse. |
| `tensor.squeeze` | keine | Ausgang. Entfernt Dimensionen der Größe 1 (etwa die Batch-Dimension). |
| `tensor.reduce` | `operation` (`mean`, `sum`, `max`, `min`), optional `axis` | Ausgang. Verdichtet eine Achse, z. B. Token-Embeddings per Mittelwert zu einem Satzvektor. |
| `tensor.l2Normalize` | optional `axis` | Ausgang. Skaliert Vektoren auf Länge 1 für Ähnlichkeitsvergleiche; Nullvektoren bleiben unverändert. |
| `tensor.slice` | `start`, optional `end`, `axis` | Ausgang. Wählt einen Bereich entlang einer Achse; ein leerer Bereich ist ein Fehler. |
| `tensor.round` | optional `decimals` (Standard `0`) | Ausgang. Rundet auf Nachkommastellen. |
| `tensor.fitLength` | `length`, optional `axis` (Standard `-1`), `value` (Standard `0`), `keep` (`start` oder `end`) | Ein- und Ausgang. Füllt eine Achse auf oder kürzt sie; `keep: end` behält die jüngsten Werte (Zeitreihen-Fenster). |
| `audio.mono` | keine | Eingang (Audio). Mischt alle Kanäle zu einem. |
| `audio.resample` | `sampleRate` | Eingang (Audio). Ändert die Abtastrate per Fourier-Resampling, z. B. auf 16 kHz. |
| `audio.normalize` | optional `mode` (`peak` oder `rms`), `target` (Standard `1` bzw. `0.1`) | Eingang (Audio). Gleicht die Lautstärke an; Stille bleibt unverändert. |
| `audio.fitDuration` | `seconds`, optional `keep` | Eingang (Audio). Füllt mit Stille auf oder kürzt auf eine feste Dauer. |
| `audio.melSpectrogram` | optional `frameLength` (400), `hopLength` (160), `melBins` (80), `minFrequency`, `maxFrequency`, `power` (2), `scale` (`power`, `log`, `log10`, `db`), `dynamicRange`, `melScale` (`slaney`, `htk`), `filterNormalization` (`slaney`, `none`), `center` (`true`) | Eingang (Audio). Liefert ein Mel-Spektrogramm `[melBins, Frames]` aus Mono-Audio. `db` ist relativ zum Maximum; `dynamicRange` begrenzt den Abstand zum Maximum in der gewählten Einheit. Voreinstellungen entsprechen librosa. |
| `json.toTensor` | keine | Eingang (JSON/Boolean). Zahlen und Wahrheitswerte → `float32`-Tensor, Texte → String-Tensor, jeweils auch als gleich lange (verschachtelte) Listen. Gemischte Listen sind ein Fehler. |
| `text.piperPhonemes` | `language`, `phonemeIdMap` | Eingang (Text). Text → Piper-Phonem-IDs mit Start- und Endsymbol (espeak). |
| `text.piperPhonemeLength` | `language`, `phonemeIdMap` | Eingang (Text). Anzahl der Piper-Phonem-IDs, für den zweiten Modelleingang. |
| `text.kokoroTokens` | `language`, `tokenIdMap` | Eingang (Text). Text → Kokoro-Token-IDs, eingerahmt von Füll-Tokens. |
| `text.kokoroStyle` | `language`, `tokenIdMap`, `voice`, `resource` | Eingang (Text). Stilvektor der Stimme `voice` aus der Modellressource `resource`, passend zur Tokenanzahl. |
| `tensor.constant` | `values` | Ersetzt den Wert durch einen festen Zahlentensor, z. B. für Hilfseingänge mit Inferenzparametern. |
| `geometry.toSource` | `input`, optional `clip` (Standard `true`) | Ausgang (Regionen/Erkennungen). Rechnet `bounds` bzw. `box` mit der Geometrie des Bildeingangs `input` in Koordinaten des Originalbildes zurück; `clip` begrenzt auf das Bild. |
| `mask.toSource` | `input`, optional `layout` (`channelsFirst`, `channelsLast`), `fill` (Standard `0`) | Ausgang. Bildet eine Maske oder Karte `[H, W]`, `[C, H, W]` bzw. `[H, W, C]` per Nearest-Neighbour auf die Originalgröße ab; Rand des Modellbildes wird zu `fill`. |
| `image.encode` | optional `format` (`png`, `jpeg`), `fileName`, `layout` (Standard `channelsLast`), `palette` (Liste von `[r, g, b]`) | Ausgang. Kodiert einen Tensor als Bilddatei (Werte auf 0…255 begrenzt); mit `palette` werden Klassenindizes eingefärbt. Workflow-Typ `image`. |
| `resource.lookup` | `resource`, optional `format` (`lines` oder `json`), `key` (Standard `index`), `field` (Standard `label`) | Ausgang (Top-K-Treffer, Erkennungen). Ergänzt jeden Eintrag um seinen Namen aus einer Label-Datei des Modells (`artifactReference.resources`): eine Zeile je Label oder eine JSON-Liste. Große Label-Listen stehen so nicht im Manifest. |
| `audio.wav` | `sampleRate`, optional `fileName` (Standard `sprach-ausgabe.wav`) | Ausgang. Kodiert Samples als WAV-Datei (16 Bit, mono); Werte außerhalb von -1…1 werden begrenzt. |
| `text.toTensor` | keine | Eingang (Text). Text → String-Tensor `[1]`, z. B. für Pipelines mit eingebauter Textverarbeitung (TF-IDF). |
| `json.features` | `features` (Liste aus `{field, kind?, mean?, std?, default?, categories?, unknown?}`) | Eingang (JSON). Datensatz → Merkmalsvektor in fester Reihenfolge; `field` als Punktpfad, `kind` `number` (standardisiert mit `mean`/`std`), `boolean` oder `category` (One-Hot, unbekannte Werte `zero` oder `error`). Eine Liste von Datensätzen ergibt eine Zeile je Datensatz. |
| `sequence.segments` | `frameDuration` oder `hopLength` + `sampleRate`, optional `threshold`, `labels`, `backgroundIndex`, `mergeGap`, `minDuration` | Ausgang. Frame-Scores → Zeitabschnitte `{start, end, score}`; Klassenscores (Frames × Klassen) → `{start, end, index, label?, score}` je wahrscheinlichster Klasse. Zeiten in Sekunden, Werte auf 6 Stellen gerundet. |
| `workflowOutput.mapping.$map` | `from`, `item` | Formt ein Transformations-Ergebnis zu einer Liste. |
| `workflowOutput.mapping.$lookup` | `values` (Liste oder Referenz wie `"$classes"`), `key` | Liest einen Wert aus einer indizierten Tabelle. |
| `workflowOutput.mapping.$outputs` | `$outputs.<ausgang>.<wert>` | Liest den Endwert (`tensor`) oder ein benanntes Ergebnis eines anderen Ausgangs. |

## Siehe auch

- [Deklarative Transformationen](./transformationen-deklarativ.md)
- [Bildgeometrie und Originalkoordinaten](./bildgeometrie-originalkoordinaten.md)
- [Vertragsprüfung](./ml-vertragspruefung.md)
