# Erkennung des Dokumentenscanners

> Die Web-Erkennung nutzt jscanify auf OpenCV.js, beide lokal mitgeliefert und erst beim ersten Scan nachgeladen.

Gehört zu: [Dokumentenscanner](../index/dokumentscanner.md)

- [jscanify](https://github.com/puffinsoft/jscanify) (MIT) auf
  [OpenCV.js](https://opencv.org) (Apache-2.0), unverändert unter
  `web/document_scanner/`, **nicht vom CDN**; Herkunft in
  `web/document_scanner/NOTICE.md`.
- `opencv.js` (~9 MB) lädt erst beim ersten Scan; beim Start wird nur
  `document_scanner_bridge.js` eingebunden. Lokal gemessen ~0,25 s Ladezeit.
- Die Brücke verkleinert für die Erkennung auf 480 px Breite (erste Erkennung
  bis 0,3 s, danach 5–20 ms), verwirft Konturen unter 15 % und über 97 % der
  Bildfläche und zieht die Ecken beim Begradigen um 0,6 % nach innen, damit
  kein Streifen Untergrund bleibt.
- Ergebnis: JPEG Qualität 0,92, längste Seite höchstens 2400 px.

## Siehe auch

- [Grenzen des Dokumentenscanners](./dokumentscanner-grenzen.md)
