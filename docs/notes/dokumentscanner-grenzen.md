# Grenzen des Dokumentenscanners

> Der Browser-Scanner braucht eine sichere Verbindung, scannt eine Seite und erkennt nur Blätter mit Kontrast zum Untergrund.

Gehört zu: [Dokumentenscanner](../index/dokumentscanner.md)

- Kamera nur über `https` oder `localhost`; auf `http` fehlt
  `navigator.mediaDevices` und der Scanner meldet das.
- Eine Seite, Datei heißt immer `scan.jpg`.
- Weißes Papier auf weißem Tisch wird oft nicht erkannt (dann ganzes Bild);
  Ecken lassen sich nicht von Hand nachziehen.
- Das Blatt muss ganz im Bild liegen; ragt es über den Bildrand, gibt es keine
  Kontur. Eine umgeknickte Ecke ragt etwas aus der Kontur heraus.
- Nicht automatisiert getestet: echte Kamera. Von Hand in Chrome mit
  Testkamera (`--use-fake-device-for-media-stream`, Video eines schrägen
  Blatts) geprüft: Erkennung auf ~0,6 % genau, Aufnahme, Vorschau, Übernehmen,
  verweigerte Berechtigung, keine Kamera, unsichere Seite. Die Erkennung lief
  außerdem auf zwei Bildern eines iPhones (Kassenbon auf dunklem Holz).
  Ein vollständiger Durchlauf auf echten Handys, in Safari und Firefox steht
  aus.

## Siehe auch

- [Erkennung des Dokumentenscanners](./dokumentscanner-erkennung.md)
- [Adresse und Schema der Runtime](./runtime-adresse-schema.md) — `http` im LAN
