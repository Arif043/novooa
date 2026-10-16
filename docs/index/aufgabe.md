# Aufgabe

> Im Aufgabenstudio bauen Nutzer:innen Automatisierungen (Aufgaben) aus Bausteinen; ein Graph-Runner führt sie in der Cloud oder in der lokalen Runtime aus.

## Modell

- [Aufgabe als Aggregat](../notes/aufgabe-aggregat.md)
- [Bausteinkatalog](../notes/bausteinkatalog.md)
- [Bausteine von Plugins](../notes/plugin-bausteine.md)
- [Standardnamen neuer Bausteine](../notes/standardnamen-neuer-bausteine.md)
- [Flacher Namensraum der Werte](../notes/flacher-werte-namensraum.md)
- [Arbeitspläne (geplant)](../notes/arbeitsplaene-geplant.md)

## Aufgabenstudio

- [Layout des Aufgabenstudios](../notes/aufgabenstudio-layout.md)
- [Anschlüsse auf der Leinwand](../notes/leinwand-anschluesse.md)
- [Werte im Panel und auf der Leinwand](../notes/werte-panel-und-leinwand.md)
- [Darstellung der Ausgabetypen](../notes/ausgabetyp-darstellung.md)
- [Entscheidungs-Prompt und Zweige](../notes/entscheidungs-prompt-zweige.md)
- [Script-Editor](../notes/script-editor.md)

## Ausführung

- [Run starten](../notes/run-start.md)
- [Laufzeitgrenzen der Ausführung](../notes/ausfuehrung-laufzeitgrenzen.md)
- [Ergebnisvertrag eines Bausteins](../notes/node-ergebnisvertrag.md)
- [Registrierte Executor-Outputs](../notes/executor-outputs.md)
- [Anhänge und Workspace](../notes/anhaenge-workspace.md)
- [Freigaben und Pausen](../notes/freigaben-und-pausen.md)
- [Lokale Ausführung](../notes/lokale-ausfuehrung.md)
- [Task-Run-Warteschlange](../notes/task-run-warteschlange.md)
- [Schritt-Journal (Checkpointing)](../notes/schritt-journal.md)
- [Fehlgeschlagene Bausteine in den Aktivitäten](../notes/baustein-fehler-aktivitaeten.md)

## Bausteine im Detail

- [Modellprovider für Prompt-Bausteine](../notes/modellprovider-prompt.md)
- [Prompt-Executor](../notes/prompt-executor.md)
- [Iterative Verfeinerung](../notes/iterative-verfeinerung.md)
- [Script-Executor](../notes/script-executor.md)
- [Script: Workflow-Ausgabewerte](../notes/script-workflow-output.md)
- [Bedingter Ablauf: Auswertung](../notes/bedingter-ablauf-auswertung.md)
- [Baustein „Für jedes Element“](../notes/foreach-baustein.md)
- [Formulareingabe](../notes/formulareingabe-baustein.md)
- [Bild anfordern](../notes/bild-anfordern-baustein.md)
- [Datensatz-Bausteine](../notes/datensatz-bausteine.md)
- [Sammlung als Tabelle](../notes/sammlung-als-tabelle.md)
- [Datei-Bausteine](../notes/datei-bausteine.md)
- [Kanal-Bausteine](../notes/kanal-bausteine.md)
- [Push-Benachrichtigung senden](../notes/push-baustein.md)
- [Modelleingaben im Baustein](../notes/modelleingaben-im-baustein.md) (Modell ausführen)

## Offene Punkte

- `toolCall` und `validation` haben keinen Executor: Welche Werkzeuge kommen
  zuerst, welche Validierungsregeln braucht das MVP?
- Gmail als Mail-Connector fehlt.
- Definition of Done des Aufgabenstudios: ziehen, verbinden, selektieren,
  verschieben, löschen; Panel speichert sofort; Titel und Ziel editierbar;
  neuer immutable State nach jeder Mutation; Leer- und Fehlerzustände
  lokalisiert.

## Verwandt

- [Zeitplan](./zeitplan.md)
- [ML-Modelle](./ml-modelle.md)
- [Lokale Runtime](./lokale-runtime.md)
- [KI-Agent](./ki-agent.md)
- [Aktivitäten](../features/aktivitaeten.md)
- [Dateien](./dateien.md)
- [Daten](../features/daten.md)
