# Modellquellen im Worker

> Der Python-Worker nimmt `image`, `audio`, `text`, `number`, `json`, `boolean` und `datetime` an, in Cloud und Standalone gleichermaßen.

Gehört zu: [ML-Modelle](../index/ml-modelle.md)

- **`image`:** beim Empfang mit Pillow geöffnet.
- **`audio`:** WAV beim Empfang dekodiert (PCM 8/16/24/32 Bit, Float 32/64,
  WAVE_EXTENSIBLE); andere Formate wie MP3 werden mit Meldung abgelehnt.
  Intern Samples `(Frames, Kanäle)`; Audio-Transformationen stehen vor
  Tensoroperationen. Ohne Spektrogramm wird daraus `[Samples]` (mono) bzw.
  `[Kanäle, Samples]`.
- **`datetime`:** ISO-8601, ohne Versatz als UTC.
- **`tensor`:** unverändert durchgereicht.
- **`file`:** lehnt die Runtime schon beim Import ab.

Bei einer Eingabeform wie `["dynamic", 3, 224, 224]` fügt der Worker den
Batch-Index hinzu, wenn das Bild als `[3, 224, 224]` vorliegt. Vor der
Rückgabe prüft er Form, Datentyp und Byte-Länge.

## Siehe auch

- [Modelleingaben im Baustein](./modelleingaben-im-baustein.md)
- [Typebenen eines Modellvertrags](./modell-typebenen.md)
