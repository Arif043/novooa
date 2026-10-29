# Seite „Ergebnisse“

> „Ergebnisse“ zeigt die jüngsten Läufe; ein Lauf öffnet seine Ergebnisansicht mit Ergebnis, Folgen und dem Ablauf als Graph mit echten Werten.

Gehört zu: [Aktivitäten](../index/aktivitaeten.md)

Code: `lib/features/results/` (`ResultsPage`, `RunResultPage`).

- **Aufbau wie ein Mail-Programm:** Ab 900 px links die Läufe, rechts der
  gewählte (anfangs der neueste); auf dem Handy öffnet ein Lauf seine eigene
  Seite. Ohne Läufe eine Einladung „Zu den Aufgaben“.
- **Liste:** nach Tagen gruppiert („Heute“, „Gestern“, Datum); je Lauf eine
  kompakte Zeile mit Status-Symbol, Aufgabe, Uhrzeit und dem Ergebnis in
  einem Satz (Fehler, Endausgabe oder Status, dazu die Dauer ab einer
  Sekunde). Filter nach vorkommenden Status über das Kontextmenü.
- **Lauf:** Kopf mit Status und Herkunft; eine Karte mit **Ergebnis**
  (Endausgabe bzw. Fehler) und **Folgen** als Chips (Dateien öffnen die
  Datei); darunter der **Ablauf**.
- **Ergebnisgraph:** derselbe Graph wie im Aufgabenstudio aus dem
  [Schnappschuss](./lauf-graph-schnappschuss.md) — Layout, Rahmen und Kanten
  stammen aus dem Aufgabenstudio, Karten und Chips sind eigene. Jede Karte
  zeigt, was der Baustein erlebt hat (ausgeführt, fehlgeschlagen,
  übersprungen, wartet, nicht ausgeführt — Letzteres blass, etwa der nicht
  genommene Zweig), den ersten Wert und die Zahl seiner Folgen. Pfeile
  zeigen statt des Ausgabenamens den echten Wert. Schleifen tragen eine
  Rundenwahl; innere Bausteine zeigen die gewählte Runde
  ([innere Ergebnisse](./lauf-innere-ergebnisse.md)).
- **Details** eines Bausteins: am Desktop neben dem Graphen, auf dem Handy
  als Sheet — Werte, Folgen, bei Teamarbeit das Gespräch.
- Läufe ohne Schnappschuss (älter als die Ansicht) zeigen die Bausteine als
  knappe Schrittfolge: je Baustein sein letzter Stand und seine Werte in
  einer Zeile, ohne das Sammelfeld `value` doppelt.
- In **Aktivitäten → Historie** führt „Ergebnis ansehen“ in einem Durchlauf
  hierher.

## Siehe auch

- [Aktivitäten-Seite](./aktivitaeten-seite.md)
- [Innere Ergebnisse eines Laufs](./lauf-innere-ergebnisse.md)
