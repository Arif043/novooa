# Dokumentenscanner im Browser

> Im Browser öffnet „Als Dokument scannen“ eine Vollbild-Seite, die das Blatt live erkennt, beim Aufnehmen begradigt und ein JPEG zurückgibt.

Gehört zu: [Dokumentenscanner](../index/dokumentscanner.md)

1. `pickMediaSubmission`: Option an, Quelle Kamera, Plattform Browser →
   `DocumentScanPage` (sonst `ActivityCubit` und natives Plugin).
2. Rückkamera per `getUserMedia`; die Erkennung wird beim ersten Mal
   nachgeladen.
3. Etwa fünfmal pro Sekunde wird das Dokument gesucht; die Kontur erscheint
   als farbiges Viereck.
4. „Aufnehmen“: Bild in voller Auflösung, entlang der Kontur begradigt; ohne
   Erkennung das ganze Bild.
5. Vorschau: „Wiederholen“ zurück zur Kamera, „Übernehmen“ gibt das JPEG an
   den Dialog.

Zustände: Kamera startet, Kamerabild mit Erkennung, Vorschau, Fehler mit
„Erneut versuchen“ und „Schließen“ (Kamera verweigert, keine Kamera oder keine
sichere Verbindung, Erkennung nicht ladbar, Aufnahme fehlgeschlagen).

## Siehe auch

- [Erkennung des Dokumentenscanners](./dokumentscanner-erkennung.md)
- [Aufbau des Dokumentenscanners](./dokumentscanner-aufbau.md)
- [Grenzen des Dokumentenscanners](./dokumentscanner-grenzen.md)
