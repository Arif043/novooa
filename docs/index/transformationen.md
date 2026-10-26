# Transformationen

> Alle Transformationen des Python-ML-Dienstes, je eine Notiz mit Wertart, Parametern, Beispiel und fachlichen Tests; die Richtung (Ein- oder Ausgang) ergibt sich allein aus der Position in der Pipeline.

## Grundlagen

- [Regeln für Transformationen](../notes/regeln-fuer-transformationen.md) — allgemein statt modellspezifisch, fachliche Testfälle
- [Deklarative Transformationen](../notes/transformationen-deklarativ.md)
- [Wertarten und Kettenregeln](../notes/ml-wertarten-und-ketten.md)
- [Vertragsprüfung](../notes/ml-vertragspruefung.md)
- [Aufbau des Python-ML-Dienstes](../notes/python-ml-dienst-aufbau.md)
- [Workflow-Output-Mapping](../notes/workflow-output-mapping.md) — `$map`, `$lookup` und `$outputs` sind keine Transformationen, sondern formen den Workflow-Wert

## Bild

- [`image.centerCrop`](../notes/transformation-image-center-crop.md) — Schneidet einen Ausschnitt aus der Bildmitte; größer als das Bild ist ein Fehler.
- [`image.crop`](../notes/transformation-image-crop.md) — Schneidet einen achsenparallelen Bildbereich aus.
- [`image.decode`](../notes/transformation-image-decode.md) — Dekodiert eine Bilddatei und setzt den Farbraum (`rgb`, `rgba` oder `grayscale`).
- [`image.encode`](../notes/transformation-image-encode.md) — Kodiert einen Tensor als Bilddatei (Werte auf 0…255 begrenzt); mit `palette` werden Klassenindizes eingefärbt.
- [`image.exifTranspose`](../notes/transformation-image-exif-transpose.md) — Dreht Fotos gemäß EXIF-Ausrichtung (z. B. Handyaufnahmen); vor anderen Bildtransformationen einsetzen.
- [`image.padToMultiple`](../notes/transformation-image-pad-to-multiple.md) — Füllt rechts und unten bis zu einem Vielfachen auf; Bildkoordinaten bleiben erhalten.
- [`image.perspectiveCrop`](../notes/transformation-image-perspective-crop.md) — Richtet ein Viereck perspektivisch zu einem Bild aus.
- [`image.resize`](../notes/transformation-image-resize.md) — Skaliert ein Bild auf feste Breite und Höhe (LANCZOS); das Seitenverhältnis kann sich dabei ändern.
- [`image.resizeHeightPad`](../notes/transformation-image-resize-height-pad.md) — Skaliert ein Bild auf die Zielhöhe und füllt die Breite auf, schneidet sie ab oder lässt sie dynamisch.
- [`image.resizePad`](../notes/transformation-image-resize-pad.md) — Skaliert ein Bild unter Erhalt des Seitenverhältnisses und füllt bis zur Zielgröße auf (Letterbox).
- [`image.resizeShorterSide`](../notes/transformation-image-resize-shorter-side.md) — Skaliert die kürzere Seite auf `size`, das Seitenverhältnis bleibt.

## Tensor

- [`tensor.argmax`](../notes/transformation-tensor-argmax.md) — Index des größten Werts, z. B. die wahrscheinlichste Klasse.
- [`tensor.channelOrder`](../notes/transformation-tensor-channel-order.md) — Ordnet Farbkanäle über eine vollständige Indexpermutation um.
- [`tensor.clip`](../notes/transformation-tensor-clip.md) — Begrenzt Werte auf den Bereich zwischen `min` und `max`.
- [`tensor.constant`](../notes/transformation-tensor-constant.md) — Ersetzt den Wert durch einen festen Zahlentensor, z. B. für Hilfseingänge mit Inferenzparametern.
- [`tensor.fitLength`](../notes/transformation-tensor-fit-length.md) — Füllt eine Achse auf oder kürzt sie; `keep: end` behält die jüngsten Werte (Zeitreihen-Fenster).
- [`tensor.l2Normalize`](../notes/transformation-tensor-l2-normalize.md) — Skaliert Vektoren auf Länge 1 für Ähnlichkeitsvergleiche; Nullvektoren bleiben unverändert.
- [`tensor.layout`](../notes/transformation-tensor-layout.md) — Ordnet Bildtensoren zwischen HWC (`channelsLast`) und CHW (`channelsFirst`) um.
- [`tensor.normalize`](../notes/transformation-tensor-normalize.md) — Normalisiert jeden Farbkanal mit `(wert − mean) / std`.
- [`tensor.reduce`](../notes/transformation-tensor-reduce.md) — Verdichtet eine Achse, z. B. Token-Embeddings per Mittelwert zu einem Satzvektor.
- [`tensor.reshape`](../notes/transformation-tensor-reshape.md) — Formt den Tensor um; die Anzahl der Werte muss passen.
- [`tensor.round`](../notes/transformation-tensor-round.md) — Rundet Werte auf eine feste Zahl von Nachkommastellen.
- [`tensor.scale`](../notes/transformation-tensor-scale.md) — Berechnet `wert × factor + offset`, z. B. `1/255` für Pixel oder zum Zurückrechnen normierter Ausgaben.
- [`tensor.sigmoid`](../notes/transformation-tensor-sigmoid.md) — Wandelt Logits elementweise in Wahrscheinlichkeiten.
- [`tensor.slice`](../notes/transformation-tensor-slice.md) — Wählt einen Bereich entlang einer Achse; ein leerer Bereich ist ein Fehler.
- [`tensor.softmax`](../notes/transformation-tensor-softmax.md) — Normalisiert Werte entlang der letzten Tensorachse.
- [`tensor.squeeze`](../notes/transformation-tensor-squeeze.md) — Entfernt Dimensionen der Größe 1 (etwa die Batch-Dimension).
- [`tensor.threshold`](../notes/transformation-tensor-threshold.md) — Wandelt numerische Werte in eine boolesche Maske.
- [`tensor.topK`](../notes/transformation-tensor-top-k.md) — Liefert die `k` größten Werte als Paare aus Index und Wert.
- [`tensor.transpose`](../notes/transformation-tensor-transpose.md) — Ordnet die Achsen eines Tensors nach einer vollständigen Permutation um.

## Masken, Regionen und Erkennungen

- [`geometry.mergeRows`](../notes/transformation-geometry-merge-rows.md) — Fasst horizontale Textregionen mit ausreichender vertikaler Überlappung zu einer Zeile zusammen.
- [`geometry.scaleBounds`](../notes/transformation-geometry-scale-bounds.md) — Rechnet eine Regionsliste vom Maskenraster in Bildkoordinaten zurück.
- [`geometry.toSource`](../notes/transformation-geometry-to-source.md) — Rechnet `bounds` bzw. `box` mit der Geometrie des Bildeingangs `input` in Koordinaten des Originalbildes zurück; `clip` begrenzt auf das Bild.
- [`mask.connectedComponents`](../notes/transformation-mask-connected-components.md) — Liefert Regionen als `{bounds, pixelCount}`; `bounds` enthält `left`, `top`, `width`, `height`.
- [`mask.textRegions`](../notes/transformation-mask-text-regions.md) — Leitet aus einer Wahrscheinlichkeitsmaske bewertete Textregionen ab.
- [`mask.toSource`](../notes/transformation-mask-to-source.md) — Bildet eine Maske oder Karte `[H, W]`, `[C, H, W]` bzw. `[H, W, C]` per Nearest-Neighbour auf die Originalgröße ab; Rand des Modellbildes wird zu `fill`.
- [`tensor.nonMaximumSuppression`](../notes/transformation-tensor-non-maximum-suppression.md) — Liest Erkennungen aus den Zeilen eines Tensors und unterdrückt überlappende Boxen.

## Sequenzen

- [`sequence.ctcGreedyDecode`](../notes/transformation-sequence-ctc-greedy-decode.md) — Dekodiert CTC-Logits in `{text, confidence}`; `allowedCharacters` begrenzt die Auswahl auf ein fachlich zulässiges Alphabet.
- [`sequence.segments`](../notes/transformation-sequence-segments.md) — Frame-Scores → Zeitabschnitte `{start, end, score}`; Klassenscores (Frames × Klassen) → `{start, end, index, label?, score}` je wahrscheinlichster Klasse.

## Audio

- [`audio.fitDuration`](../notes/transformation-audio-fit-duration.md) — Füllt mit Stille auf oder kürzt auf eine feste Dauer.
- [`audio.melSpectrogram`](../notes/transformation-audio-mel-spectrogram.md) — Liefert ein Mel-Spektrogramm `[melBins, Frames]` aus Mono-Audio.
- [`audio.mono`](../notes/transformation-audio-mono.md) — Mischt alle Kanäle eines Audiosignals zu einem.
- [`audio.normalize`](../notes/transformation-audio-normalize.md) — Gleicht die Lautstärke an; Stille bleibt unverändert.
- [`audio.resample`](../notes/transformation-audio-resample.md) — Ändert die Abtastrate per Fourier-Resampling, z. B. auf 16 kHz.
- [`audio.wav`](../notes/transformation-audio-wav.md) — Kodiert Samples als WAV-Datei (16 Bit, mono); Werte außerhalb von -1…1 werden begrenzt.

## Text

- [`text.kokoroStyle`](../notes/transformation-text-kokoro-style.md) — Liefert den Stilvektor der Kokoro-Stimme `voice` aus der Modellressource `resource`, passend zur Tokenanzahl.
- [`text.kokoroTokens`](../notes/transformation-text-kokoro-tokens.md) — Text → Kokoro-Token-IDs, eingerahmt von Füll-Tokens.
- [`text.piperPhonemeLength`](../notes/transformation-text-piper-phoneme-length.md) — Liefert die Anzahl der Piper-Phonem-IDs als Tensor für den zweiten Modelleingang.
- [`text.piperPhonemes`](../notes/transformation-text-piper-phonemes.md) — Text → Piper-Phonem-IDs mit Start- und Endsymbol (espeak).
- [`text.toTensor`](../notes/transformation-text-to-tensor.md) — Text → String-Tensor `[1]`, z. B. für Pipelines mit eingebauter Textverarbeitung (TF-IDF).

## Daten

- [`json.features`](../notes/transformation-json-features.md) — Datensatz → Merkmalsvektor in fester Reihenfolge; `field` als Punktpfad, `kind` `number` (standardisiert mit `mean`/`std`), `boolean` oder `category` (One-Hot, unbekannte Werte `zero` oder `error`).
- [`json.toTensor`](../notes/transformation-json-to-tensor.md) — Zahlen und Wahrheitswerte → `float32`-Tensor, Texte → String-Tensor, jeweils auch als gleich lange (verschachtelte) Listen.
- [`number.toTensor`](../notes/transformation-number-to-tensor.md) — Macht aus einer Zahl oder Zahlenliste einen eindimensionalen `float32`-Tensor.

## Datum und Uhrzeit

- [`datetime.features`](../notes/transformation-datetime-features.md) — Zerlegt einen Zeitpunkt in Zahlenmerkmale; `weekday` zählt ab Montag = 0.

## Modellressourcen

- [`resource.lookup`](../notes/transformation-resource-lookup.md) — Ergänzt jeden Eintrag um seinen Namen aus einer Label-Datei des Modells (`artifactReference.resources`): eine Zeile je Label oder eine JSON-Liste.

## Offene Punkte

Allgemeine Transformationen, die weitere Modellfamilien ohne neuen Code
importierbar machen (alle **geplant**):

- Ausgänge übergreifend lesen (z. B. `tensor.concat` mit Verweis auf einen
  anderen Ausgang) — getrennte Boxen-, Score- und Label-Ausgänge (RT-DETR,
  D-FINE, DETR).
- Bildgröße als Hilfstensor für Eingänge wie `im_shape`, `scale_factor`,
  `orig_target_sizes` (Paddle-Detektoren, RT-DETR).
- Erkennungszeilen mit Klassenspalte und ohne erneute Unterdrückung
  (PP-DocLayout, Exporte mit eingebauter NMS).
- Raster- und Ankerdekodierung (YOLOX ohne Dekodierung, YuNet, SSD).
- Min-Max-Skalierung (Tiefen- und Saliency-Karten).
- Keypoints: Rückrechnung ins Originalbild, Dekodierung aus Heatmaps und
  SimCC (MoveNet, RTMPose).
- In Fenster oder Kacheln teilen und als Batch rechnen (lange Audiosignale,
  große Bilder).
- Maske als Alphakanal aufs Quellbild anwenden (Freistellen).
- Audio standardisieren (Mittelwert und Standardabweichung).

## Verwandt

- [ML-Modelle](./ml-modelle.md)
- [Sprachausgabe](./sprachausgabe.md)
