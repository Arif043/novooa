# Erkennung des Dokumentenscanners

> Die Web-Erkennung sucht das Blatt mit eigener OpenCV.js-Logik als geprüftes Viereck; jscanify begradigt nur noch. Beides ist lokal mitgeliefert und lädt erst beim ersten Scan.

Gehört zu: [Dokumentenscanner](../index/dokumentscanner.md)

- [OpenCV.js](https://opencv.org) (Apache-2.0) und
  [jscanify](https://github.com/puffinsoft/jscanify) (MIT) liegen unverändert
  unter `web/document_scanner/`, **nicht vom CDN**; Herkunft in
  `web/document_scanner/NOTICE.md`.
- `opencv.js` (~9 MB) lädt erst beim ersten Scan; beim Start wird nur
  `document_scanner_bridge.js` eingebunden. Lokal gemessen ~0,25 s Ladezeit.
- Die Erkennung steckt in `document_quad_detector.js` (eigener Code, ohne DOM):
  1. Graustufen und Weichzeichnen, dann Kanten (Canny mit Schwellen aus dem
     Median der Helligkeit, Lücken geschlossen); findet das nichts, eine
     Otsu-Schwelle für helles Papier auf dunklem Grund.
  2. Die zehn größten Konturen werden über konvexe Hülle und `approxPolyDP`
     zu Vierecken. Angenommen wird nur ein konvexes Viereck mit 15 bis 97 %
     der Bildfläche und Innenwinkeln zwischen 30° und 150°. Jede Seite muss
     zu mindestens 45 % auf der Kontur liegen (Abstand bis 4 % der
     Seitenlänge, damit eingerissene Kassenbons und gewelltes Papier
     durchgehen); das verwirft Muster im Untergrund und verschmolzene
     Konturen. Liegt eine Seite auf dem Bildrand, ist es eine angeschnittene
     Fläche (Boden, Tisch) und wird verworfen: Das Blatt muss ganz im Bild
     sein.
  3. Durch die Mitte jeder Seite wird eine Gerade gelegt; die Ecken sind ihre
     Schnittpunkte. Abgerundete Ecken und Finger am Rand verschieben sie so
     kaum.
- Das alte Verfahren (jscanify `findPaperContour`) nahm die größte Kontur
  ohne Viereckprüfung und rutschte auf gemustertem Untergrund auf den Tisch.
- Erkannt wird auf 640 px Breite (5–20 ms je Bild). Bei der Aufnahme wird auf
  dem aufgenommenen Bild in 1280 px Breite neu gesucht; weicht das um höchstens
  4 % von der angezeigten Kontur ab, gilt die neue, sonst die angezeigte.
- Beim Begradigen werden die Ecken um 0,6 % nach innen gezogen, damit kein
  Streifen Untergrund bleibt.
- Ergebnis: JPEG Qualität 0,92, längste Seite höchstens 2400 px.
- Test: `node --test test/web/*.mjs` prüft die Erkennung auf künstlichen
  Bildern (gedreht, verzerrt, Finger, gestreifter und heller Untergrund,
  eingerissener Bon mit umgeknickter Ecke, angeschnittene Fläche am Rand).

## Siehe auch

- [Aufbau des Dokumentenscanners](./dokumentscanner-aufbau.md) — Glättung der Kontur
- [Grenzen des Dokumentenscanners](./dokumentscanner-grenzen.md)
