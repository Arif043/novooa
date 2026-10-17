# Architektur

> Übergreifende Regeln für Client und Backend: Schichten, Feature-First-Struktur, Persistenz in SQLite und Firestore, Lokalisierung, Sicherheit und Grenzen der Cloud.

## Schichten und Struktur

- [Schichtenregel](../notes/schichtenregel.md)
- [Backend: Feature-First-Struktur](../notes/backend-feature-first.md)
- [Backend: Schichtregeln](../notes/backend-schichtregeln.md)
- [Fehlerschichtung eines Modellaufrufs](../notes/fehlerschichtung-modellaufruf.md)
- [Kern-Entitäten](../notes/kern-entitaeten.md)
- [Lokalisierung](../notes/lokalisierung.md)
- [Genkit-Flow-Konventionen](../notes/genkit-flow-konventionen.md)

## Persistenz

- [SQLite und Firebase: fünf Regeln](../notes/sqlite-und-firebase-regeln.md)
- [SQLite-Prüfstand (3NF)](../notes/sqlite-3nf-pruefstand.md)
- [Firestore-Pfade](../notes/firestore-pfade.md)
- [Firestore im Client](../notes/firestore-client-persistenz.md)
- [Team-Kontext und Einladungen](../notes/team-kontext.md)
- [Sprachmodelle in der Cloud](../notes/sprachmodelle-cloud-persistenz.md)

## Cloud-Betrieb

- [Lebenszyklus eines Runs in der Cloud](../notes/cloud-run-lebenszyklus.md)
- [Grenzen von Cloud Functions](../notes/cloud-functions-grenzen.md)
- [Benachrichtigungen und Push](../notes/benachrichtigungen-und-push.md)

## Sicherheit

- [Auth, App Check und Telemetrie](../notes/auth-appcheck-telemetrie.md)
- [Firestore-Regeln für Nutzerdaten](../notes/firestore-regeln-nutzerdaten.md)
- [Regelprüfung der Runtime-Wake-ups](../notes/runtime-wakeup-regelpruefung.md)

## Entwicklung

- [UI-Vorschau](../notes/ui-vorschau.md)
- [Designsystem](../DESIGN.md)

## Offene Punkte

- App Check und Telemetrie aktivieren.
- Budgets je Task (Bytes, Laufzeit, Modellaufrufe, Kosten) und Chunking der
  Wissensbasis.
- Restliche Features und Domain-Texte lokalisieren.
- Keine Synchronisierung zwischen Cloud und Standalone (bräuchte eigenen
  Vertrag mit Konfliktregeln).

## Verwandt

- [Betriebsvarianten](./betriebsvarianten.md)
- [Lokale Runtime](./lokale-runtime.md)
- [Aufgabe](./aufgabe.md)
