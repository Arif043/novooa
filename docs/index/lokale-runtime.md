# Lokale Runtime

> novooa läuft vollständig lokal (Standalone): Aufgaben, Läufe, Aktivitäten, Dateien, Wissensbasis und Auslöser liegen in einem Docker-Stack beim Kunden; Cloud-Dienste sind nur über dünne Relays angebunden.

## Aufbau und Betrieb

- [Runtime-Schichten](../notes/runtime-schichten.md)
- [Runtime-Adapterübersicht](../notes/runtime-adapteruebersicht.md)
- [Docker-Stack der Runtime](../notes/runtime-docker-stack.md)
- [Ports und Netze der Runtime](../notes/runtime-ports-und-netze.md)
- [Volumes und Datenablage der Runtime](../notes/runtime-volumes-und-datenablage.md)
- [Images, Updates und Neustarts](../notes/runtime-images-und-updates.md)
- [Lokaler Start der Runtime](../notes/runtime-lokaler-start.md)
- [Entwicklungsmodus ohne Lizenz](../notes/runtime-entwicklungsmodus.md)

## Zugriff und Authentifizierung

- [Betreiber-Passwort-Pflicht](../notes/betreiber-passwort-pflicht.md)
- [Ersteinrichtung der Runtime](../notes/runtime-ersteinrichtung.md)
- [Runtime-Sitzungen](../notes/runtime-sitzungen.md)
- [Passwort ändern](../notes/passwort-aendern.md)
- [Login-Ratenbegrenzung](../notes/login-ratenbegrenzung.md)
- [Sicherer Token-Speicher im Client](../notes/client-token-speicher.md)

## Transport

- [Transportverschlüsselung ist Infrastruktur](../notes/transport-ist-infrastruktur.md)
- [Adresse und Schema der Runtime](../notes/runtime-adresse-schema.md)
- [Verschlüsselter Transport über http](../notes/verschluesselter-transport.md)
- [Reverse Proxy für externen Zugriff](../notes/reverse-proxy-externer-zugriff.md)

## HTTP-Server

- [Fastify-Plugins der Runtime](../notes/runtime-fastify-plugins.md)
- [Route-Schemas mit TypeBox](../notes/runtime-route-schemas.md)
- [Anfrage-Pipeline: Lizenz → Session → Route](../notes/runtime-anfrage-pipeline.md)
- [Runtime-API des nativen Clients](../notes/runtime-client-api.md)
- [Webhooks: Ausnahme von der Sitzungspflicht](../notes/webhook-sitzungsausnahme.md)

## Datenhaltung

- [SQLite-Anbindung mit Drizzle](../notes/sqlite-drizzle-anbindung.md)
- [SQLite-Migrationen](../notes/sqlite-migrationen.md)
- [SQLite-Normalisierungsschritte](../notes/sqlite-normalisierungsschritte.md)
  - [Sprachmodelle ohne eigene Team-ID (0010)](../notes/sqlite-sprachmodelle-normalisiert.md)
  - [Benutzerprofile und Teammitglieder (0011)](../notes/sqlite-teammitglieder-normalisiert.md)
  - [Jobs und Schritte über den Run (0012)](../notes/sqlite-run-abhaengige-normalisiert.md)
  - [Auslöser in der Standalone-Datenbank (0013)](../notes/ausloeser-standalone-aufgabenbezug.md)
  - [Aktivitäten über den Run (0014)](../notes/sqlite-aktivitaeten-normalisiert.md)
  - [Modellkatalog ohne `scope` und `runtime` (0015)](../notes/sqlite-modellkatalog-normalisiert.md)
  - [Datei- und Ordnerablage (0017/0018)](../notes/sqlite-dateiablage-normalisiert.md)
  - [Wissenslinks werden beim Lesen berechnet (0019)](../notes/sqlite-wissenslinks-berechnet.md)
- [Anwendungsprotokoll](../notes/anwendungsprotokoll.md)
- [Sprachmodell-Anbieter](../notes/sprachmodell-anbieter.md)
- [Verbindung](../notes/verbindung.md) (Geheimnisse in `language_model_secrets`)
- [Mitarbeiter](../notes/mitarbeiter.md)
- [Skills-Ordner](../notes/skills-ordner.md)

## Ausführung

- [Task-Run-Warteschlange](../notes/task-run-warteschlange.md)
- [Zeitplan-Worker der Runtime](../notes/runtime-zeitplan-worker.md)
- [Fehlgeschlagene Bausteine in den Aktivitäten](../notes/baustein-fehler-aktivitaeten.md)
- [Script-Dienst: Schnittstelle](../notes/script-dienst-schnittstelle.md)
- [Script-Dienst: Ausführung und Grenzen](../notes/script-dienst-ausfuehrung.md)
- [Script-Ausgabe im Protokoll](../notes/script-ausgabe-protokoll.md)
- [Script-Dienst: Abschottung](../notes/script-dienst-abschottung.md)
- [Script-Dienst: Ressourcengrenzen abstimmen](../notes/script-dienst-ressourcen.md)
- [ONNX-Inferenz über den ML-Dienst](../notes/onnx-inferenz-ml-dienst.md)
- [Wo die KI-Agenten laufen](../notes/ki-agenten-betriebsorte.md)

## Lizenz

- [Lizenz-Token und Aktivierung](../notes/lizenz-aktivierung.md)
- [Lizenz freigeben](../notes/lizenz-freigabe.md)
- [Regelmäßige Lizenzprüfung](../notes/lizenz-regelmaessige-pruefung.md)
- [Lizenz-Signaturschlüssel](../notes/lizenz-signaturschluessel.md)
- [Lizenz ausstellen](../notes/lizenz-ausstellen.md)

## Cloud-Anbindung über Relays

- [Cloud-Endpunkte der Runtime](../notes/runtime-cloud-endpunkte.md)
- [Firebase-Wake-up der Runtime](../notes/runtime-firebase-wakeup.md)
- [Mail-Relay und Dead-Letter-Queue](../notes/mail-relay-dead-letter.md)
- [Postfächer in der Runtime](../notes/runtime-postfaecher.md)
- [Twilio über den Cloud-Relay](../notes/twilio-relay.md)
- [Push-Benachrichtigungen in Standalone](../notes/push-standalone.md)

## Verschlüsselung von Geheimnissen

- [Feldverschlüsselung mit Envelopes](../notes/feldverschluesselung-envelope.md)
- [Master-Key-Schlüsselbund](../notes/master-key-schluesselbund.md)
- [Automatische Master-Key-Rotation](../notes/master-key-automatische-rotation.md)
- [Manuelle Master-Key-Rotation](../notes/master-key-manuelle-rotation.md)
- [Alte Master-Keys entfernen](../notes/master-key-alte-entfernen.md)

## Offene Punkte

1. Docker-Engine- und Stack-Status in der Desktop-App anzeigen, Stack
   kontrolliert starten und stoppen.
2. Lizenz-Gateway mit Firebase-Secret und Produktions-Compose ausrollen.
3. Freigabe-Ereignisse über den Cloud-Gateway in Firestore/FCM spiegeln.
4. SQLite-Backups und versionierte Images für die Desktop-App umsetzen.

## Verwandt

- [Betriebsvarianten](./betriebsvarianten.md)
- [Backend-Struktur](../notes/backend-feature-first.md)
- [SQLite-Normalisierung](../notes/sqlite-3nf-pruefstand.md)
- [Import/Export](./import-export.md)
- [UI-Vorschau](../notes/ui-vorschau.md)
- [Zeitplan](./zeitplan.md)
