# Datei-Ereignisse lösen Aufgaben aus

> Jede Schreib- und Löschoperation im Dateispeicher wird als `FileEvent` gemeldet; `DispatchFileEvent` startet die passenden Auslöser.

Gehört zu: [Zeitplan](../index/zeitplan.md)

Ereignisse: `fileCreated`, `fileVersionCreated`, `fileDeleted`.

`DispatchFileEvent` lädt die aktiven Ereignis-Auslöser, löst die
Verzeichniskette der Datei auf und startet jede Aufgabe, deren Quelle, Ziel,
Dateikategorie und Filter passen. Die Aufgabe erhält das Ereignis als
`input.event`.

Fehler eines Auslösers stoppen weder die Dateioperation noch andere Auslöser.

Verdrahtet ist das bisher nur in der lokalen Runtime: Upload, Baustein
„Datei schreiben“ und Löschen.

## Siehe auch

- [Ereignisziel eines Auslösers](./ausloeser-ereignisziel.md)
- [Schleifenschutz zur Laufzeit](./schleifenschutz-laufzeit.md)
- [Dateien](../index/dateien.md)
