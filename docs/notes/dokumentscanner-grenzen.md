# Grenzen des Dokumentenscanners

> Der Browser-Scanner braucht eine sichere Verbindung, scannt eine Seite und erkennt nur Blätter mit Kontrast zum Untergrund.

Gehört zu: [Dokumentenscanner](../index/dokumentscanner.md)

- Kamera nur über `https` oder `localhost`; auf `http` fehlt
  `navigator.mediaDevices` und der Scanner meldet das.
- Eine Seite, Datei heißt immer `scan.jpg`.
- Weißes Papier auf weißem Tisch wird oft nicht erkannt (dann ganzes Bild);
  Ecken lassen sich nicht von Hand nachziehen.
- Gesucht wird die größte Kante; ohne klaren Rand oder teilweise außerhalb
  kann die Kontur danebenliegen.
- Nicht automatisiert getestet: echte Kamera. Einmal von Hand in Chrome mit
  Testkamera (`--use-fake-device-for-media-stream`, Video eines schrägen
  Blatts) geprüft: Erkennung auf ~0,6 % genau, Aufnahme, Vorschau, Übernehmen,
  verweigerte Berechtigung, keine Kamera, unsichere Seite. Nicht geprüft: echte
  Handys, Safari, Firefox.

## Siehe auch

- [Erkennung des Dokumentenscanners](./dokumentscanner-erkennung.md)
- [Adresse und Schema der Runtime](./runtime-adresse-schema.md) — `http` im LAN
