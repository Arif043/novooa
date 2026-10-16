# Schleifenschutz zur Entwurfszeit

> `findTriggerCycles` sucht Zyklen zwischen Aufgaben und Auslösern; nur eine sichere Selbstschleife wird abgelehnt, alles andere ist eine Warnung.

Gehört zu: [Zeitplan](../index/zeitplan.md)

## Graph

Nach dem Muster des Betriebsmittelbelegungsgraphen:

- Aufgabe → Auslöser: „schreibt etwas, das den Auslöser auslöst“ (Matrix `W`).
- Auslöser → Aufgabe: „startet“ (Matrix `T`).

Reduziert auf Aufgaben ergibt sich das Boolesche Matrixprodukt
`E = W ⊗ T`. Ein Zyklus liegt vor, wo die transitive Hülle `E⁺` (Warshall)
auf der Diagonale eine 1 hat.

Die Schreibstellen einer Aufgabe (`fileWriteSitesOf`: Datei schreiben,
Bild-Prompt, Sprachausgabe — auch in Verzweigungen und Schleifen) werden
gegen Quelle, Ziel, Dateityp und Filter geprüft (`writeMatch`). Jede Kante ist
`certain` oder `possible`, weil Laufzeitwerte unbekannt sind.

## Folgen

- **Selbstschleife mit sicherer Kante:** HTTP 400 beim Anlegen oder Aktivieren
  eines Auslösers und beim Speichern einer Aufgabe.
- **Alle anderen Zyklen:** Warnung. `POST /v1/task-triggers/analysis` liefert
  `blocked` und Warnungen vorab; der Dialog verlangt eine bewusste
  Bestätigung. Beim Speichern einer Aufgabe stehen Warnungen in `warnings` und
  erscheinen im Aufgabenstudio; eine Ablehnung als „Nicht gespeichert: …“.

Warum so tolerant: Die Prüfung ist eine Überapproximation ohne
Verzweigungsentscheidungen. Ein bedingter Zweig, der nie läuft, ist statisch
nicht vom Normalfall zu unterscheiden. Was sie übersieht, fängt die Laufzeit ab.

## Siehe auch

- [Schleifenschutz zur Laufzeit](./schleifenschutz-laufzeit.md)
- [Dialog „Auslöser hinzufügen“](./ausloeser-dialog.md)
