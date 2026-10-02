# Lokale Runtime

## Ziel

novooa soll später vollständig lokal laufen können: Aufgaben, Ausführungen,
Aktivitäten, Dateien, Wissensbasis und Trigger-Zustand liegen lokal. Cloud-
Provider wie Twilio bleiben optional über einen dünnen novooa-Relay nutzbar.

## Runtime-Schichten

```text
Feature Domain
  Entities, Repository-Ports und Use Cases

Feature Infrastructure
  Task Runner und Node Executors
  Firebase-, Genkit- und Twilio-Adapter
  Lokale SQLite- und Dateisystem-Adapter
  Callable-, Scheduler- und Webhook-Handler
```

## Deployment

Die lokale Variante wird über Docker Compose betrieben. Docker Desktop ist
auf macOS und Windows eine explizite Voraussetzung; auf Linux wird eine
kompatible Docker Engine benötigt. novooa bündelt Docker nicht und startet
keine Container Engine selbst.

Die Flutter-Desktop-App verwendet für Fach- und Nutzdaten ausschließlich den
lokalen Runtime-Endpunkt. Sie benötigt weder ein Firebase-Konto noch eine
Internetverbindung im laufenden Betrieb. Für die einmalige Aktivierung benötigt
die Runtime eine HTTPS-Verbindung zum novooa-Lizenz-Gateway.
Benachrichtigungen und externe Trigger werden später über einen novooa-Relay
vermittelt, nicht über den Client. Die App verwaltet weder SQLite-Dateien noch
Docker-Volumes direkt. Das automatische
Prüfen, Starten und Überwachen des versionierten Compose-Stacks gehört zur
auslieferbaren Desktop-App und ist noch nicht implementiert.

```text
Flutter-Desktop-App
  -> Docker Desktop / Docker Engine
      -> novooa-runtime (Node)
          lokale API, Scheduler, Task-Worker, SQLite-Adapter, Relay-Client
      -> novooa-ml (Python)
          Tensor-Transformationen und ONNX-Inferenz
```

`novooa-runtime` ist der einzige Dienst mit einem veröffentlichten Host-Port:
`8090` auf allen Schnittstellen, sowohl für die reguläre API als auch für das
einmalige Setzen des Betreiber-Passworts (siehe unten). Clients im LAN geben die private
IPv4-Adresse des Hosts ein und sprechen die Runtime unverschlüsselt über HTTP
an. **novooa terminiert selbst kein TLS und verwaltet keine Zertifikate** —
das ist Infrastruktur und gehört nicht zur Fachlogik des Produkts. Wer die
Runtime aus dem Internet erreichbar machen will, stellt einen eigenen Reverse
Proxy mit Domain und Zertifikat davor; der Client erkennt eine Domain und
verwendet dann HTTPS. Details dazu und zur zwingenden
Passwort-Authentifizierung unter
[Zugriff und Authentifizierung](#zugriff-und-authentifizierung). `novooa-ml`
ist nicht vom Host erreichbar und kommuniziert nur über das interne
Compose-Netzwerk mit `novooa-runtime`.

Das benannte Volume `novooa-data` enthält SQLite, Dateien, Wissensbasis und
lokale Modellartefakte. Es ist nur in `novooa-runtime` schreibbar eingehängt.
Der Python-Dienst erhält keine Datenbank und kein schreibbares Daten-Volume;
er verarbeitet ausschließlich geprüfte Modellbytes und Tensoren über sein
Protokoll. Container erhalten weder den Docker-Socket noch Docker-Credentials.

Das aktuelle Entwicklungs-Compose baut die Images aus dem Checkout. Die
auslieferbare Desktop-App wird stattdessen Images auf konkrete novooa-Versionen
referenzieren, niemals auf `latest`. Vor einem Update muss `novooa-runtime`
ein SQLite-Backup anlegen. Ausschließlich die Runtime führt idempotente
Migrationen aus und meldet ihren Health-Status. Für Runtime und ML-Dienst gilt
`restart: unless-stopped`, damit Zeitpläne und gepufferte Relay-Ereignisse auch
ohne geöffnete Desktop-App verarbeitet werden.

Der private Signaturschlüssel bleibt außerhalb des Daten-Volumes. Die Runtime
speichert unter `credentials/license-state.json` die signierte Lizenz und ein
verschlüsseltes Aktivierungsgeheimnis mit restriktiven Dateirechten. Das Geheimnis
ist mit dem bei der Installation erzeugten Runtime-Master-Key geschützt. Die Datei
enthält weder den Kunden-Token, einen privaten Signaturschlüssel noch
Firebase-Credentials. Die Runtime darf ausgehend den novooa-Relay und konfigurierte
Modellprovider erreichen; der ML-Dienst erhält keinen direkten Internetzugang.

## Zugriff und Authentifizierung

**Jede** Verbindung — auch im LAN, auch rein lokal auf demselben Rechner —
verlangt ein selbst gewähltes Betreiber-Passwort. Das ist ein bewusster
Breaking Change: bestehende Installationen müssen nach einem Update einmalig
ein Passwort setzen (siehe unten), bevor der native Client sich wieder
verbinden kann.

### Transportverschlüsselung ist Infrastruktur, nicht Produktlogik

novooa unterscheidet zwei Belange bewusst:

- **Authentifizierung** (Passwort, Session-Token) beantwortet die fachliche
  Frage „wer darf diesen Arbeitsbereich benutzen“ und liegt deshalb in der
  Runtime. Sie wirkt unabhängig vom Transport.
- **Transportverschlüsselung** ist Infrastruktur. novooa liefert dafür
  **keinen Reverse Proxy mit und verwaltet keine Zertifikate**. Andernfalls
  kollidierte es mit Hosts, die bereits einen Reverse Proxy betreiben oder
  deren Domain längst ein Zertifikat besitzt — und belegte Port 443, der dort
  schon vergeben ist.

Daraus ergeben sich zwei Betriebsarten, die der Client an der Adresse
erkennt:

| Adresse | Schema | Standardport | Einsatz |
| --- | --- | --- | --- |
| IP-Adresse (`192.168.1.42`) | `http` | `8090` | Direkter Zugriff im vertrauenswürdigen Netz |
| Domain (`novooa.example.de`) | `https` | `443` | Über einen selbst betriebenen Reverse Proxy mit Zertifikat |

Ein abweichender Port lässt sich in beiden Fällen anhängen
(`192.168.1.42:9000`, `novooa.example.de:8443`).

Beide Vorgaben lassen sich durch ein ausdrücklich angegebenes Schema
überschreiben — nötig für **interne Hostnamen ohne Zertifikat**
(`http://novooa.fritz.box`, `http://raspberrypi.local`), die sonst als Domain
gälten und an der Zertifikatsprüfung scheiterten. Umgekehrt ist
`https://192.168.1.42` möglich, wenn ein Proxy ein Zertifikat für eine
IP-Adresse ausliefert. Eine Domain fällt dabei **niemals von selbst** auf
HTTP zurück: Ein stiller Downgrade würde die Verschlüsselung durch einen
bloßen Konfigurationsfehler unbemerkt abschalten. Hat eine Domain kein
gültiges Zertifikat (abgelaufen, selbstsigniert, auf einen anderen Namen
ausgestellt), meldet der Client das ausdrücklich als Zertifikatsproblem und
nicht als Netzwerkfehler.

> **Sicherheitsgrenze:** Über `http` (IP-Adresse oder interner Hostname)
> ist die **JSON-API** seit dem verschlüsselten Transport gegen passives
> Mitlesen geschützt (siehe unten): Passwort, Session-Token, Pfade und Inhalte
> sind für Beobachter im LAN nicht lesbar. Nicht geschützt bleiben ein aktiver
> Man-in-the-Middle, Datei-Uploads/-Downloads außerhalb der JSON-API, der
> WebSocket-Kanal und die ausgelieferte Web-App selbst. Der Port `8090` darf
> deshalb **niemals aus dem Internet** erreichbar sein. Für externen Zugriff
> gehört zwingend ein Reverse Proxy mit Domain und Zertifikat davor; der
> Client verwendet dann automatisch HTTPS und braucht den Tunnel nicht.

### Verschlüsselter Transport (JSON-API über http)

Der Client schickt über `http` jede Anfrage an `/v1/…` verschlüsselt durch
einen Tunnel; die Routen der Runtime bleiben unverändert.

1. **Handshake** `POST /v1/secure/handshake`: Client und Runtime tauschen
   ephemere X25519-Schlüssel und je eine 16-Byte-Nonce aus. Beide leiten
   daraus per HKDF-SHA256 (Salt = Client-Nonce ‖ Server-Nonce, Info
   `novooa-transport-v1`) zwei Schlüssel ab, je Richtung einen. Die Runtime
   hält den Kanal im Speicher (Leerlauf 12 h, höchstens 512 Kanäle); nach einem
   Neustart handelt der Client automatisch neu aus.
2. **Austausch** `POST /v1/secure/exchange`: Methode, Pfad samt Query,
   `Authorization`, `Content-Type` und Body werden als JSON mit AES-256-GCM
   verschlüsselt (Umschlag = Base64(IV ‖ Chiffretext ‖ Tag), Zusatzdaten
   `novooa/1|<Kanal>|<req|res>|<Zähler>`). Die Runtime entschlüsselt, führt die
   Anfrage intern gegen die normalen Routen aus (inklusive Lizenz- und
   Session-Prüfung) und verschlüsselt die Antwort.
3. **Wiedereinspielen:** Jede Anfrage trägt einen Zähler; er wird nur einmal
   akzeptiert und muss in einem Fenster der letzten 128 Zähler liegen, damit
   parallele Anfragen sich überholen dürfen. Ein Zähler wird erst nach
   erfolgreicher Entschlüsselung verbraucht.
4. **Erreichbar** sind nur `GET/POST/PUT/DELETE` auf `/v1/…` (nicht
   `/v1/secure/…`) mit JSON-Antwort. Alles andere, etwa `/healthz`, läuft im
   Klartext.

Es gibt **keinen stillen Rückfall auf Klartext**: Unterstützt die Runtime den
Handshake nicht (zu alte Version), meldet der Client eine Verbindungsstörung
mit dem Hinweis, die Runtime zu aktualisieren. Der Client nutzt den Tunnel nur
bei `http`; bei `https` entfällt er. Die Gegenstücke liegen in
`functions/src/shared/local/secure-transport-*.ts` und
`lib/core/network/secure_transport/`; ein gemeinsamer Testvektor und
gegenseitig erzeugte Umschläge sichern die Kompatibilität beider Seiten.

**Bekannte Grenzen:** Der Handshake ist nicht authentifiziert — ein aktiver
Man-in-the-Middle, der ihn manipuliert, kann mitlesen. Abhilfe wäre ein
Server-Schlüssel, den der Client beim ersten Kontakt merkt (Trust on First
Use), oder TLS. Außerdem akzeptiert die Runtime weiterhin unverschlüsselte
Anfragen und kann so einen im Klartext mitgeschnittenen Token (etwa aus einem
Datei-Upload) nicht von einem Tunnel-Token unterscheiden.

Für den externen Zugriff terminiert der eigene Proxy TLS und leitet an
`127.0.0.1:8090` weiter. Ein minimales nginx-Beispiel:

```nginx
server {
    listen 443 ssl;
    server_name novooa.example.de;

    ssl_certificate     /etc/letsencrypt/live/novooa.example.de/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/novooa.example.de/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:8090;
        proxy_set_header Host $host;
    }
}
```

Damit die Runtime in diesem Fall nicht zusätzlich direkt erreichbar bleibt,
wird das Port-Mapping in `docker-compose.local.yaml` auf den Host beschränkt:
`"127.0.0.1:8090:8080"` statt `"8090:8080"`.

### Erstmaliges Setzen des Passworts

Von **jedem** Client, über den regulären Port `8090` — auch für headless
installierte Runtimes ohne Browser auf dem Host, auch aus dem LAN oder aus
dem Browser. Die Einrichtung hat zwei Schritte:

1. **Lizenz:** `POST /v1/license/activate {activationToken}` löst den
   16-stelligen Lizenz-Token beim Lizenz-Gateway ein. Die Runtime speichert
   dabei zusätzlich den SHA-256-Hash des Tokens in
   `credentials/license-state.json`.
2. **Passwort:** `POST /v1/setup {activationToken, password}` setzt das
   Betreiber-Passwort — nur wenn der Token zum gespeicherten Hash passt
   (sonst `403`). Die App schickt dafür den Token aus Schritt 1 mit; kennt
   sie ihn nicht mehr (etwa nach einem Neustart zwischen den Schritten),
   fragt das Passwort-Formular ihn zusätzlich ab.

Der Vertrauensanker ist **Besitz des Lizenz-Tokens**, nicht Netzwerkposition:
Wer die Runtime zufällig zuerst erreicht, kann ohne Token kein Passwort
setzen. Ein zusätzlicher Code aus dem Start-Log ist deshalb nicht nötig.
`GET /v1/setup` meldet `needsSetup`, `requiresLicenseToken` (nur im
Entwicklungsmodus ohne echte Lizenz `false`) und die erreichbaren Adressen.
`POST /v1/setup` funktioniert genau einmal und sperrt sich danach dauerhaft
(`409`).

Ein Token ist beim Gateway nur einmal einlösbar. Gibt man ihn auf einer
bereits lizenzierten Runtime erneut ein — etwa weil die Antwort der ersten
Aktivierung den Client nicht erreicht hat —, bestätigt die Runtime die
bestehende Lizenz ohne Gateway-Anfrage; ein fremder Token wird mit `409`
(`already_activated`) abgewiesen. Lizenzen, die vor Einführung des
Token-Nachweises aktiviert wurden, haben keinen gespeicherten Hash: Für die
Ersteinrichtung muss die Lizenz dann über `POST /v1/license/release`
freigegeben und mit demselben Token erneut aktiviert werden.

Fehlgeschlagene Aktivierungen meldet die Runtime unterscheidbar
(`400 invalid_token`, `401 license_rejected`, `409 already_activated`,
`502 gateway_unavailable`, `500 activation_failed`) und protokolliert sie als
`local_runtime.license_activation_failed` im Container-Log.

Nach dem Setzen des Passworts meldet sich der Client über
`POST /v1/auth/login` an und erhält ein Session-Token, das er fortan als
`Authorization: Bearer <token>` mitschickt. `/healthz` und `/v1/license/*`
bleiben unverändert außerhalb dieser Passwort-Pflicht — die Lizenzaktivierung
ist bereits durch den Lizenz-Token selbst geschützt.

Der HTTP-Server verwendet native Fastify-5-Routen: Routing, Pfadparameter,
JSON-Parsing und Body-Limit (1 MiB), Schema-Validierung und Fehlerantworten
liegen bei Fastify. Jedes Feature ist ein **Fastify-Plugin**
(`local-<feature>-routes.ts`, z. B. `dataRoutes`, `fileResourceRoutes`), das
beim Start einmal mit seinen stabilen Abhängigkeiten (Stores, Relay-Clients)
als Plugin-Optionen registriert wird (`local-runtime-routes.ts`,
`local-runtime-route-services.ts`). Fachliche Use-Cases bleiben unabhängig davon.
Die lokalen SQLite-Repositories verwenden Drizzle ORM für typisierte CRUD-
Abfragen und gebundene SQL-Templates für komplexere SQLite-Abfragen.

**Route-Schemas:** Jede Route deklariert `params`, `querystring`, `body` und
`response` als TypeBox-Schema (`@fastify/type-provider-typebox`); die
Request-Typen ergeben sich daraus. Fastify validiert mit Ajv und serialisiert
mit fast-json-stringify — nicht deklarierte Felder erscheinen deshalb nie in
einer Antwort (z. B. kein API-Key). Pfad-, Query- und Header-Werte werden in
den Schema-Typ umgewandelt, JSON-Bodies bewusst nicht (`local-runtime-validation.ts`):
`{"blockModelId": 42}` ist ein Fehler, keine Zeichenkette. Schema-Verletzungen
ergeben `400 {error: "Ungültige Anfrage.", code: "invalid_request", field}`;
fachliche Prüfungen (z. B. gültiger Zeitplan, Anbieter-URL) liefern weiterhin
eigene deutsche Meldungen. Task-Runs behalten ihren mit der Cloud geteilten
Vertrag `{failure: {code, message}}` (`attachValidation`).

`@fastify/cors` erzeugt CORS-Header und Preflight-Antworten;
`@fastify/static` liefert das Web-Build mit SPA-Fallback aus, ohne API-Pfade
zu überdecken. ONNX- und ZIP-Uploads verwenden native Streaming-Content-Parser.
JSON-Anfragen benötigen `Content-Type: application/json`; erfolgreiche
`204`-Antworten enthalten entsprechend dem HTTP-Standard keinen Body.
Healthcheck und statisches Web-Build haben eigene Routen außerhalb der
API-Zugriffsprüfung. Fremde Browser-Herkünfte werden auch bei Preflight-Anfragen
abgewiesen. Beim Shutdown werden offene WebSocket-Verbindungen
beendet und Fastify vollständig geschlossen, bevor Worker und Datenbank stoppen.

Lizenz- und Session-Prüfung sind native `onRequest`-Hooks in einem gekapselten
Fastify-API-Plugin: **Lizenz → Session → Route**. Es gibt keine eigene
Middleware-Kette. Alles, was vom aktiven Arbeitsbereich abhängt (Team, Nutzer,
team-gebundener Logger, Task-Workflow, globaler Modellkatalog), lesen die Routen
pro Anfrage aus `request.workspace` — einem Getter-Decorator
(`local-runtime-workspace-context.ts`), den `LocalRuntimeApplication` bedient.
Ein Arbeitsbereichswechsel ersetzt nur Worker und diesen Kontext; Routen und
Plugins bleiben unverändert. Realtime-Notifier und Ticket-Store sind
prozessweit, damit Abonnements einen Wechsel überdauern.
Login und Auth-Prüfung erhalten denselben prozessweiten
Session-Store per Dependency Injection, aber nur mit der jeweils benötigten
Fähigkeit: Login erhält `createSession`, Auth erhält `verifySession`.
Status, Aktivierung und Freigabe sind eigene öffentliche Fastify-Routen.
Die Aktivierung wird per JSON-Schema validiert und anschließend durch den
frameworkfreien `ActivateRuntime`-Use-Case ausgeführt; dieser aktiviert
Lizenz und Workspace. Login und Setup
überspringen nur die Session-Prüfung, nicht die Lizenzprüfung. Healthcheck,
CORS und statische Dateien bleiben im HTTP-Server, WebSockets sind separat
durch Einmaltickets geschützt.

Der Client führt die Einrichtung in dieser Reihenfolge: Runtime-Adresse,
gegebenenfalls Lizenzaktivierung und anschließend das Betreiber-Passwort.
Diese Reihenfolge ist nicht willkürlich: Vor der Aktivierung existiert der
Setup-Handler noch gar nicht, weil er an der erst dann erzeugten Datenbank
hängt.

### Client-Voraussetzungen

Das Session-Token liegt verschlüsselt im plattformeigenen
Credential-Speicher (`flutter_secure_storage`), nicht in `SharedPreferences`.

- **macOS**: `keychain-access-groups` ist als Entitlement gesetzt
  (`macos/Runner/{Debug,Release}.entitlements`) — `flutter_secure_storage`
  verlangt es laut eigener Dokumentation, sonst scheitert jeder
  Schreibzugriff zur Laufzeit mit
  `PlatformException(-34018, A required entitlement isn't present.)`.
  Sichtbar wird das erst bei der Anmeldung: Das Session-Token lässt sich
  nicht speichern.

  Dieses Entitlement verlangt eine **Development-Signing-Identität**; ohne
  sie bricht bereits der Build mit `"Runner" has entitlements that require
  signing with a development certificate` ab. Ein ad-hoc signierter Build
  (`Signature=adhoc`, `TeamIdentifier=not set`) genügt nicht. Einmalige
  Einrichtung — ein kostenloses Personal Team reicht, kein bezahlter
  Apple-Developer-Account nötig:

  1. Xcode → Settings → Accounts → Apple-ID hinzufügen.
  2. `macos/Runner.xcworkspace` öffnen, Target **Runner** → Signing &
     Capabilities → „Automatically manage signing“ aktivieren und das Team
     auswählen. Dadurch wird `DEVELOPMENT_TEAM` in `project.pbxproj`
     gesetzt.

  Fehlt beim Flutter-Start trotzdem das Profil (`No profiles for
  'de.novooa.desktop' were found`), das Profil einmal aus dem Projektverzeichnis
  mit Xcode erzeugen lassen. Der macOS-Build von Flutter übergibt selbst kein
  `-allowProvisioningUpdates`:

  ```bash
  xcodebuild -workspace macos/Runner.xcworkspace -scheme Runner \
    -configuration Debug -derivedDataPath build/macos \
    -destination 'platform=macOS' -allowProvisioningUpdates build
  flutter run -d macos
  ```

  Dafür muss der ausgewählte Account in Xcode angemeldet sein und ein gültiges
  Development-Zertifikat besitzen. Die Keychain-Entitlements nicht entfernen
  und die Signierung nicht deaktivieren: Sonst scheitert die Token-Speicherung.

  Dieser Schritt ist **pro Entwicklungsrechner** nötig: Die beiden
  `.entitlements`-Dateien sind versioniert, das Xcode-Projekt selbst ist es
  laut `.gitignore` nicht (`macos/*` mit Ausnahme genau dieser Dateien).
  `DEVELOPMENT_TEAM` und das zugehörige Zertifikat sind damit
  maschinenlokal und werden nicht mitverteilt.
- **Windows**: `flutter_secure_storage` benötigt die C++-ATL-Bibliotheken der
  Visual Studio Build Tools.

### Nicht Teil dieser Erweiterung

- Kein Rate-Limiting/Brute-Force-Schutz auf `POST /v1/auth/login`.
- Keine mitgelieferte Reverse-Proxy-Konfiguration. novooa prüft nicht, ob vor
  der Runtime tatsächlich TLS terminiert wird — die Zusicherung „nicht
  unverschlüsselt aus dem Internet erreichbar“ liegt beim Betreiber.
- Kein automatisches Erkennen einer falsch gesetzten Portfreigabe: Wird
  Port `8090` versehentlich öffentlich geroutet, meldet die Runtime das
  nicht.

## Lokale Datenhaltung

SQLite ist der Default für strukturierte lokale Daten. Es braucht keinen Server,
ist transaktional und eignet sich für Aufgaben, Runs, Aktivitäten, Trigger,
Teams, Kanäle, Wissensbasis-Metadaten und Modellkataloge.

Dateien, Daten-Collections, Wissensbasis und Aufgaben lassen sich in den
Runtime-Einstellungen unter **Import/Export** als ZIP-Datei sichern und wieder
einspielen (Zusammenführen per ID, Trigger ausgenommen). Gestagte Importe
liegen bis zu 30 Minuten unter `transfer-imports/` im Runtime-Verzeichnis.
Details: [`features/import-export.md`](./features/import-export.md).

Anwendungsprotokolle liegen getrennt von Workflow-Aktivitäten in
`application_logs`. Der lokale `ApplicationLogger` speichert strukturierte
Info- und Fehlerereignisse dort und gibt sie zusätzlich als JSON nach Docker-
Stdout aus. Der native Flutter-Client sendet seine eigenen Ereignisse per
`POST /v1/application-logs` an die Runtime; diese vergibt ID und
Zeitstempel und markiert die Quelle als `client`. `GET /v1/application-logs`
liefert die jüngsten Einträge an den Client; dieser zeigt sie im Tab
**Aktivitäten → Protokoll**. Der gleiche Port wird in der Cloud durch den
`FirebaseApplicationLogger` auf Firebase/Cloud Logging abgebildet.

Die Tabellen-Models liegen unter [`functions/src/db/models`](../functions/src/db/models)
und werden über [`schema.ts`](../functions/src/db/schema.ts) exportiert. Die von
Drizzle Kit erzeugte Initialmigration liegt in
[`functions/drizzle/0000_initial_runtime.sql`](../functions/drizzle/0000_initial_runtime.sql).
Sie legt unter anderem diese Tabellen an:

```text
teams
team_members
tasks
task_runs
activities
application_logs
task_triggers
communication_channels
knowledge_notes
files
file_versions
file_folders
document_collections
documents
```

Die Initialmigration enthält außerdem den ONNX-Modellkatalog `model_catalog`,
Provider-Verbindungen, Sprachmodellprofile und `language_model_secrets`.
Lokale API-Keys liegen nicht im Klartext in SQLite. Das Secret-Repository
speichert sie als AES-256-GCM-Envelope mit eigenem Datenschlüssel; `secret_ref`
verweist auf den jeweiligen Eintrag. Der Master-Key-Schlüsselbund liegt separat
außerhalb des Daten-Volumes.
Die Flutter-Einstellungen bieten **Google AI**, **xAI (Grok)**, **Mistral AI**,
**OpenRouter**, **Abacus.AI (RouteLLM)**, **Hugging Face**, **ElevenLabs**
(nur Sprachausgabe, API-Key genügt, `GET /v1/language-models/:id/voices` liefert
die Stimmen), **Ollama (lokal)** und frei konfigurierbare
OpenAI-kompatible Anbieter an und verbinden sie über `POST
/v1/language-model-connections`. Die Runtime lädt dessen Modellkatalog und
speichert alle verfügbaren Textmodelle unter einer gemeinsamen Verbindung. Die
Modellauswahl findet anschließend im TaskBuilder statt; dort liest der Client
den Katalog über `GET /v1/language-models`. API-Keys werden in keiner Antwort
ausgegeben und ausschließlich im verschlüsselten lokalen Secret Store abgelegt.
xAI, Mistral, OpenRouter, Abacus.AI und Hugging Face verwenden festgelegte
HTTPS-Endpunkte und jeweils den API-Key der Kundschaft; ihre API-Adresse ist
nicht frei überschreibbar. Abacus.AI und Hugging Face sprechen zwar das
OpenAI-Protokoll, erscheinen aber bewusst als eigene Anbieter (Abacus:
`https://routellm.abacus.ai/v1`, dazu das Pseudo-Modell `route-llm` für die
automatische Modellwahl; Hugging Face: `https://router.huggingface.co/v1`,
Modelle und deren Fähigkeiten — Werkzeugaufrufe, strukturierte Ausgabe,
Bildeingabe — aus `GET /v1/models` der Inference Providers). Abacus-Enterprise-
Arbeitsbereiche mit eigener Adresse (`https://<arbeitsbereich>.abacus.ai/v1`)
verbindet man über den generischen OpenAI-kompatiblen Anbieter.
Ollama verwendet ohne weitere Eingabe
`http://host.docker.internal:11434/v1`. Die Runtime registriert Ollama als lokales Genkit-Modell. Genkit steuert Prompt-Bausteine fuer Text, Bildanalyse und strukturierte Ausgabe und delegiert den Provider-Transport an die native `/api/chat`-API; JSON-Schemas werden dabei als Ollama-`format` uebergeben.
Für einen abweichenden OpenAI-kompatiblen Dienst wird als Base-URL
`http://host.docker.internal:<port>/v1` verwendet. Externe Anbieter benötigen
beim frei konfigurierbaren OpenAI-kompatiblen Anbieter eine HTTPS-URL und einen
API-Key. Für Ollama verwendet die Runtime intern einen
nicht geheimen Platzhalter.

Dateien liegen im lokalen Dateisystem:

```text
.novooa/
  files/{teamId}/{fileId}/versions/{versionId}/{fileName}
  model-artifacts/{artifactId}/versions/{versionId}/model.onnx
  knowledge/{teamId}/...
```

ONNX-Inferenz läuft lokal im dedizierten Python-Sidecar. Dieser erhält keine
Speicherpfade, sondern verifizierte Modellbytes und Tensoren über das
standardisierte HTTP-Protokoll. Die Abhängigkeiten liegen in
[`local-runtime/python/requirements.txt`](../local-runtime/python/requirements.txt);
die Compose-Definition startet daraus den `novooa-ml`-Container. Der
Node-Container enthält einen minimalen Python-Interpreter für isolierte
Script-Bausteine, aber keine Python-ML-Abhängigkeiten.

Workflow-Werte werden vor der lokalen Inferenz gemäß Manifest in Tensoren
transformiert. `input_transform_worker.py` verwendet für Bildquellen eine
erweiterbare Registry für Dekodierung, Skalierung, Layout und Normalisierung.
Weitere Quelltypen erhalten eigene Strategien; weder die Pipeline noch der
Modell-Baustein sind an Firebase Storage oder Bilder gekoppelt.

## Skills-Ordner (Fähigkeiten)

Fähigkeiten nach [agentskills.io](https://agentskills.io/specification) liegen **nicht** in SQLite, sondern als
Ordner im Dateisystem: `<Runtime-Verzeichnis>/skills/<skill-name>/SKILL.md` (+ `scripts/`, `references/`, `assets/`).
Der Pfad lässt sich mit `NOVOOA_SKILLS_DIR` ändern. `docker-compose.local.yaml` bindet ihn als
`${NOVOOA_SKILLS_DIR:-./novooa-skills}` auf den Host; der Einmal-Dienst `skills-init` legt den Ordner an und übergibt
ihn dem Benutzer `node`, damit Importe schreiben können. Ordner, die der Nutzer dort anlegt, sind sofort Fähigkeiten.

Der Import (GitHub, ZIP, Ordner, skills.sh) läuft über `POST /v1/skills/imports…` als Vorschau mit anschließendem
`commit`; der skills.sh-Katalog braucht `SKILLS_SH_BASE_URL` (Proxy, siehe `relay/skills-sh-proxy`) und
`SKILLS_SH_TOKEN`. Routen, Grenzen, Rate-Limits und Sicherheit stehen in
[`features/skills.md`](features/skills.md). Das Thema `skills` des Realtime-Kanals meldet Änderungen.

## Lizenz und lokale Identität

Die Runtime ist ohne gültigen Lizenzschlüssel nicht nutzbar. Beim Kauf stellt
novooa einen sechzehnstelligen Token aus dem Alphabet `A-H`, `J-N`, `P-Z` und
`2-9` aus. Der Kunde gibt ihn auf der nativen Aktivierungsseite ein. Der Client
sendet ihn ausschließlich an `POST /v1/license/activate`; die Runtime löst ihn
per HTTPS am novooa-Lizenz-Gateway ein.

Firestore speichert den SHA-256-Hash des Tokens als Dokument-ID, niemals den
Roh-Token. Das Dokument enthält mindestens `licenseId`, `name`,
`workspaceId`, `expiresAt` und `inUse`. Die Aktivierung läuft atomar ab: Ist
`inUse` false und die Lizenz nicht abgelaufen, erzeugt das Gateway eine neue
`activationId` und ein zufälliges Aktivierungsgeheimnis. Es speichert nur dessen
Hash, setzt `inUse` auf true und liefert der Runtime eine Ed25519-signierte Lizenz
plus Aktivierungsgeheimnis.

Die Runtime prüft die Signatur mit ihrem öffentlichen Verifikationsschlüssel und
speichert die signierte Lizenz und ihr Aktivierungsgeheimnis. Nur das Geheimnis
wird per Envelope Encryption mit eigenem Datenschlüssel verschlüsselt. Damit
kann eine Lizenz immer nur durch diese konkrete Aktivierung verwendet werden, ohne
einen Gerätefingerabdruck zu benötigen. Fachliche Runtime-Endpunkte liefern ohne
gültige Lizenz `423`; Task- und Trigger-Worker starten dann keine Jobs. Bis zum
signierten Ablaufdatum ist keine ständige Internetverbindung nötig.

In den Runtime-Einstellungen kann der Kunde die Lizenz entfernen. Dies ruft
`POST /v1/license/release` auf. Die Runtime übergibt die signierte
`activationId` sowie ihr Aktivierungsgeheimnis; das Gateway vergleicht dessen
Hash, setzt `inUse` atomar auf false und löscht die lokale Aktivierung. Danach
kann derselbe Token eine andere Runtime aktivieren. Eine alte signierte Lizenz
wird vom Push-Relay über ihre nicht mehr aktive `activationId` abgelehnt.

Der Produktiv-Container benötigt diese Variablen:

```text
LOCAL_RUNTIME_LICENSE_GATEWAY_URL=https://<region>-<projekt>.cloudfunctions.net/issueLocalRuntimeLicense
LOCAL_RUNTIME_LICENSE_PUBLIC_KEY_FILE=/run/secrets/novooa_runtime_license_public_key
LOCAL_RUNTIME_PUSH_RELAY_URL=https://<region>-<projekt>.cloudfunctions.net/localRuntimePushRelay
LOCAL_RUNTIME_MAIL_RELAY_URL=https://<region>-<projekt>.cloudfunctions.net/localRuntimeMailRelay
LOCAL_RUNTIME_FIREBASE_API_KEY=<Firebase-Web-API-Key>
LOCAL_RUNTIME_FIREBASE_PROJECT_ID=<Firebase-Projekt-ID>
LOCAL_RUNTIME_FIREBASE_TOKEN_URL=https://<region>-<projekt>.cloudfunctions.net/issueLocalRuntimeFirebaseToken
```

Der Verifikationsschlüssel ist kein Kundengeheimnis und dient ausschließlich dazu,
die Server-Signatur offline zu prüfen. Im Compose-Betrieb wird er bevorzugt über
`LOCAL_RUNTIME_LICENSE_PUBLIC_KEY_FILE` aus dem Docker-Secret
`novooa_runtime_license_public_key` gelesen. Der zugehörige private
Ed25519-Schlüssel ist als Firebase-Secret `LOCAL_RUNTIME_LICENSE_SIGNING_KEY`
ausschließlich im Lizenz-Gateway verfügbar. Er gehört weder in ein Image,
Compose-File noch in die Desktop-App.

### Firebase-Realtime-Sitzung

Nach der Lizenzaktivierung bzw. bei jedem Runtime-Start fordert die Runtime mit
der signierten Lizenz **und** dem verschlüsselt gespeicherten
Aktivierungsgeheimnis ein kurzlebiges Firebase-Custom-Token an. Damit meldet sie
sich als technischer Runtime-User bei Firebase Auth an und hält einen Firestore-
Listener auf `localRuntimeWakeups/{licenseId}`. Der Relay schreibt dort bei einer
neuen Mail nur eine Revisionsnummer; E-Mail-Inhalte verbleiben in der Relay-Queue.
Die Runtime zieht sie anschließend wie bisher per `pull`, verarbeitet sie lokal
und sendet `ack` oder `reject`. Die Dead-Letter-Queue bleibt unverändert.
Firestore stellt den Listener nach Netzwerkunterbrechungen selbst wieder her und
liefert den aktuellen Dokumentzustand erneut. Da die Wake-up-Revision erhalten
bleibt, gibt es für Mail-Ereignisse kein zeitbasiertes Fallback-Polling.

Der technische User trägt ausschließlich die Claims `localRuntime`,
`runtimeLicenseId`, `runtimeActivationId` sowie die Scopes `communication` und
`pushNotifications`. Firestore-Regeln erlauben ihm nur das Lesen seines eigenen
Wake-up-Dokuments. Das Firebase-Token und die Sitzung sind flüchtig; die Runtime
speichert weder Firebase-Credentials noch einen Admin-Schlüssel.
`LOCAL_RUNTIME_FIREBASE_API_KEY` ist der öffentliche Web-API-Key der Firebase-
Konfiguration, kein Firebase-Admin- oder Kundengeheimnis.

`NOVOOA_LOCAL_DEVELOPMENT=true` ist ausschließlich für isolierte
Entwicklungstests vorgesehen. Der reguläre Compose-Start verwendet den
Lizenzmodus und baut damit auch die Firebase-Sitzung der Runtime auf.

Der Vertriebsprozess benötigt einmalig Application Default Credentials und das
Zielprojekt:
`gcloud auth application-default login` und
`gcloud config set project syscat-90bff`. Anschließend erstellt er einen eindeutigen
Token und den gehashten Firestore-Eintrag mit
`npm --prefix functions run licenses:issue-local -- --name "Kunde GmbH" --expires-at 2027-09-16T00:00:00Z`.
Optional sind `--license-id` und `--workspace-id`; `--expires-at` ist verpflichtend.
Die Ausgabe ist der einmalig an den Kunden zu übergebende sechzehnstellige Token. Der
Prozess benötigt Firebase-Admin-Zugang, aber keinen Signaturschlüssel.

Der lokale SQLite-Arbeitsbereich wird deterministisch aus der signierten
Arbeitsbereich-ID erzeugt. Die lokale Desktop-App verwendet für UI-seitige
Metadaten einen nicht sicherheitsrelevanten lokalen Benutzer; die Runtime bleibt
für die tatsächliche Arbeitsbereichsgrenze maßgeblich.

## Push-Benachrichtigungen

Die Desktop-App registriert ihren FCM-Token über `POST /v1/push-devices` bei
der lokalen Runtime. Diese leitet die Registrierung zusammen mit der
signierten, aktiven Lizenz an `localRuntimePushRelay` weiter. Der Cloud-Relay
prüft Lizenzsignatur, Status und Arbeitsbereich erneut und speichert Tokens
unter der Lizenz-ID. Wartet eine lokale Aufgabe auf eine Freigabe, sendet die
Runtime den Push über denselben Relay. Fehler beim Relay werden protokolliert,
blockieren die lokale Aufgabe aber nicht.

Der Relay verarbeitet transportneutrale Push-Nachrichten mit `title`, `body`
und einem String-zu-String-Datenfeld. `registerDevice` und `removeDevice`
verwalten die Geräte einer Lizenz; `send` stellt jede fachliche
Push-Benachrichtigung an deren registrierte Geräte zu. Freigaben sind damit
ein Anwendungsfall des allgemeinen Push-Vertrags, nicht Teil der Relay-API.

Push ist in der Standalone-Variante optional und standardmäßig deaktiviert.
Dadurch lässt sich der macOS-Client ohne Apple-Entwicklungszertifikat bauen. Die
normalen Runtime-, Datei- und Netzwerkfunktionen sind davon nicht betroffen. Der
Push-Schalter erscheint nur, wenn Firebase dafür initialisiert wurde.

Für eine signierte macOS-Auslieferung kann Push mit
`--dart-define=NOVOOA_PUSH_ENABLED=true` aktiviert werden. Dann müssen zusätzlich
APNs-Credentials und die `aps-environment`-Berechtigung im signierten
App-Bundle eingerichtet werden.

## Twilio und externe Trigger

Twilio wird nicht direkt auf jede lokale Installation zeigen. Stattdessen nutzt
die lokale Runtime einen novooa Cloud Relay:

```text
Twilio
→ novooa Cloud Relay
→ lokale novooa Runtime
→ SQLite task_runs
→ lokaler Worker
```

Ausgehende Nachrichten laufen umgekehrt:

```text
lokale novooa Runtime
→ novooa Cloud Relay
→ Twilio
```

Der Relay verwaltet Twilio-Credentials und Subaccounts zentral. Die lokale
Runtime authentifiziert sich beim Relay über ein Geräte-/Workspace-Token. Wenn
die lokale Runtime offline ist, kann der Relay Events puffern und später
zustellen.

## Mail-Relay und Dead-Letter-Queue

Microsoft-Graph-Connectoren der lokalen Variante werden vollständig durch den
novooa Cloud Relay betrieben: OAuth, Refresh-Tokens, Graph-Aufrufe, Versand und
Webhook-Verarbeitung verbleiben in der Cloud. Die lokale Runtime hält nur eine
ausgehende HTTPS-Verbindung und ruft mit ihrer signierten Lizenz normalisierte
`emailReceived`-Ereignisse ab. Nach erfolgreicher lokaler, idempotenter
Verarbeitung bestätigt sie jedes Ereignis; fehlgeschlagene Zustellungen werden
mit begrenzten Wiederholungen erneut angeboten.

Nach fünf nicht bestätigten oder abgelehnten Zustellversuchen verschiebt der
Relay das Ereignis in die team- und lizenzgebundene Dead-Letter-Queue. Die
lokale Runtime kann diese über `GET /v1/mail-relay/dead-letters` einsehen und
ein Ereignis über `POST /v1/mail-relay/dead-letters/{eventId}/replay` erneut
einstellen. Damit gehen E-Mails bei einer längeren Offline-Phase nicht verloren,
ohne dass die Cloud die lokale Runtime direkt erreichen muss.

### Postfächer im Einstellungs-Tab „Kommunikation"

Der Tab **Kommunikation** erscheint auch in den Einstellungen der lokalen
Runtime, zeigt dort aber ausschließlich E-Mail-Postfächer (Microsoft Outlook):
WhatsApp und SMS laufen über Team-Konten in der Cloud und gibt es hier nicht
(`WorkspaceCapabilities.messagingChannels`). Die Runtime kennt ihre Postfächer
nur über das Cloud Relay: Der Relay-Befehl `listMailConnectors` liefert die
Connectoren dieser Lizenz — nur Anzeigedaten wie ID, Adresse, Name und Status,
nie Zugangsdaten —, die Runtime reicht sie über `GET /v1/mail-connectors` weiter.
Die App fragt dort alle 15 Sekunden nach, solange der Tab offen ist, weil die
Cloud keine Änderungen meldet. „Postfach verbinden" startet die Anmeldung über
`POST /v1/mail-connectors/microsoft/authorization`; ein Postfach mit abgelaufener
Anmeldung bietet „Postfach neu verbinden" an. Dieselbe Liste steht dem Ziel-Sheet
für E-Mail-Auslöser zur Verfügung.

## Aktueller Implementierungsstand

Die Runtime folgt vollständig der Feature-First-Struktur aus
[`backend-struktur.md`](./backend-struktur.md). Ports und Use Cases liegen im
Domain-Bereich ihres Features; Cloud- und Local-Adapter bleiben austauschbar in
dessen Infrastructure-Bereich.

- `task_execution` enthält Task Runner, Node Executors und Ports für
  Definitionen, Runs, Aktivitäten und ausgehende Nachrichten.
- `teams`, `scheduling`, `communication`, `files`, `knowledge_base` und
  `notifications` kapseln jeweils ihre eigenen Domain-Verträge und Adapter.
- Task-Ausführung erhält Dateien, Wissensbasis und Nachrichten ausschließlich
  über injizierte Ports; Function-Handler verdrahten die konkreten Adapter.
- Lokale SQL-Adapter für Tasks, Runs, Aktivitäten, Trigger, Wissensbasis und
  Dateiordner erhalten die native Drizzle-Datenbank per Dependency Injection.
- Alle Backend-Assistenten verwenden denselben `GenkitAssistantResponder` und
  denselben Laufzeitkontext für Cloud und lokal. Ein lokaler Composition Root
  kann den Wissensbasis-Agenten mit `SQLiteKnowledgeBaseAssistantNoteStore`,
  `SQLiteTeamContextStore` und dem öffentlichen HTTP/HTML-Adapter verdrahten;
  der TaskBuilder-Agent benötigt außer Modell und Prompt keinen Fachadapter.
  Firebase verwendet für den Wissensbasis-Adapter Firestore und Firebase Auth.
- `LocalTeamFileStore` schreibt Dateien in ein lokales Root-Verzeichnis und
  persistiert Datei-/Versions-Metadaten mit nativen Drizzle-Abfragen.
- `SQLiteDocumentStore` kapselt lokale, team-scoped Datensammlungen hinter dem
  fachlichen `DocumentStore`-Port. Dokumentfelder liegen intern als JSON, ohne
  diesen Speichermechanismus an Arbeitspläne weiterzugeben. Der lokale
  Task-Worker erhält denselben Port und führt damit die Bausteine
  **Datensatz suchen** und **Datensatz speichern** aus.
- `LocalOnnxInferenceRuntime` und `LocalPythonOnnxWorker` führen ONNX-Modelle
  über `local-runtime/python/onnx_worker.py` aus. Der gemeinsame
  `ModelInferenceRuntime`-Port hält diese lokale Ausführung von einer späteren
  Cloud-Runtime entkoppelt.
- `PrepareModelInputs` und `LocalPythonModelInputTransformer` bereiten
  manifestbasierte Quellen als Tensoren auf. Bild- und unveränderte
  Tensorquellen sind bereits implementiert; weitere Quelltypen folgen als
  Strategien. Die Cloud erhält später einen alternativen Adapter für denselben
  `ModelInputTransformer`-Port.
- `functions/src/db/models/{core,integration,resources}.ts` definiert die
  23 fachlichen Tabellen mit `sqliteTable`, Constraints, Indizes und aus den
  Tabellen abgeleiteten Lese-/Schreib-Models (`$inferSelect`/`$inferInsert`).
  Fachliche Repository-Verträge bleiben frameworkfrei.
- Die Anbindung folgt der offiziellen
  [Drizzle-SQLite-Anleitung](https://orm.drizzle.team/docs/get-started/sqlite-new):
  `@libsql/client` öffnet eine lokale SQLite-Datei, `drizzle({client, schema})`
  erzeugt die native Drizzle-Datenbank. Es gibt keinen eigenen SQL-Treiber,
  SQLite-Proxy oder `get/all/run`-Wrapper mehr.
- Repositories verwenden `select`, `insert`, `update`, `delete`, Joins und
  Upserts direkt. `sql` wird nur für SQLite-Ausdrücke eingesetzt. Transaktionen
  verwenden explizit `tx`; verschachtelte Transaktionen nutzen Savepoints.
  Job-Leases werden atomar mit `UPDATE … RETURNING` beansprucht.
- `drizzle.config.ts` konfiguriert Schema und Ausgabeordner. Nach einer
  Model-Änderung erzeugt `npm --prefix functions run db:generate` die nächste
  Migration samt Snapshot. `DB_FILE_NAME=file:/absoluter/pfad/novooa.sqlite`
  bestimmt die Datenbank für `npm --prefix functions run db:migrate`.
- `openLocalRuntimeDatabase` aktiviert Fremdschlüssel, WAL und Busy-Timeout
  und führt den nativen Drizzle-Migrator beim Start aus. Drizzle verwaltet die
  Historie in `__drizzle_migrations`; es gibt keinen automatischen Schema-Push.
- Die alten Migrationen und `schema_migrations` sind abgelöst. Diese neue
  Initialmigration ist für eine frisch aufgesetzte Runtime vorgesehen; eine
  bestehende Datenbank wird weder automatisch gelöscht noch zurückgesetzt.
- `docker-compose.local.yaml` startet `runtime` und `novooa-ml`. Nur
  `runtime` veröffentlicht einen Host-Port: `8090` für die API auf allen
  Schnittstellen — auch das erstmalige Setzen des Betreiber-Passworts läuft
  darüber (siehe [Erstmaliges Setzen des Passworts](#erstmaliges-setzen-des-passworts)).
  `novooa-ml` hat keinen Host-Port und hängt ausschließlich in
  `novooa-private`.
- Beim Start stellt die Runtime ohne Lizenz nur `/healthz`, `GET /v1/license`
  und `POST /v1/license/activate` und `POST /v1/license/release` bereit. Nach erfolgreicher Aktivierung legt
  sie den durch die signierte Lizenz bestimmten Teamarbeitsbereich idempotent
  an. Erst dann sind Ausführung, Review, Dateien, Wissensbasis und Zeitpläne
  erreichbar.
- Der native Client verwaltet Aufgaben über `GET`, `PUT` und `DELETE
  /v1/tasks`, Runs und Aktivitäten über `GET /v1/task-runs` und
  `GET /v1/activities`, Wissensnotizen über `/v1/knowledge-notes`, Zeitpläne
  über `/v1/task-triggers` sowie Dateien und Ordner über `/v1/files` und
  `/v1/folders`. Dateien werden als Base64-kodierte JSON-Payloads bis zur
  lokalen Runtime übertragen und dort im Volume abgelegt. Diese Endpunkte sind
  Runtime-APIs im lokalen Netzwerk und kein Cloud-HTTP-Vertrag.
- `006_task_run_jobs.sql` ergänzt eine haltbare SQLite-Jobqueue. Der
  `TaskRunQueueWorker` wird nach einem erfolgreichen Enqueue unmittelbar
  benachrichtigt, drainiert verfügbare Jobs seriell und bestätigt erfolgreiche
  Ausführungen. Persistierte Jobs werden beim Runtime-Start einmal drainiert;
  fehlgeschlagene Jobs werden mit 30 bis 300 Sekunden Backoff höchstens dreimal
  erneut versucht. Dazu setzt der Worker ausschließlich einen einmaligen Timer
  auf den gespeicherten Fälligkeitszeitpunkt, kein Intervall-Polling.
- Der `PollingTaskTriggerWorker` wertet fällige Zeitpläne alle 30 Sekunden
  aus, erzeugt Runs über den gemeinsamen Scheduling-Use-Case und schreibt den
  nächsten Ausführungszeitpunkt atomar in SQLite fort.
- `HttpPythonModelInputTransformer` und `SidecarOnnxInferenceRuntime` leiten
  Bildvorverarbeitung und ONNX-Inferenz an `novooa-ml` weiter. Ohne Sidecar
  meldet die Runtime eine klare lokale ML-Fehlermeldung statt Cloud-Fallback.

## Lokaler Start

```bash
npm --prefix functions run local-runtime:prepare -- \
  --secret-file ../.novooa/runtime-master-key
flutter build web            # die Runtime liefert dieses Build selbst aus
docker compose -f docker-compose.local.yaml up --build --detach
curl http://127.0.0.1:8090/healthz
docker compose -f docker-compose.local.yaml ps
flutter run -d macos --dart-define=NOVOOA_RUNTIME=standalone
```

`flutter build web` ist optional: Ohne das Verzeichnis bleibt die Runtime
eine reine API und antwortet auf App-Pfade mit 404. Mit dem Build ist die
Oberfläche unter derselben Adresse erreichbar wie die API — im Browser
genügt dann `http://<adresse>:8090`, ohne installierten Client.

Vor dem ersten fachlichen Zugriff muss einmalig ein Betreiber-Passwort
gesetzt werden (siehe
[Erstmaliges Setzen des Passworts](#erstmaliges-setzen-des-passworts)).

Der Stack legt die benannten Volumes `novooa-local_novooa-data` und
`novooa-local_novooa-keys` an. Ein `docker compose down` entfernt weder diese
Volumes noch SQLite, Dateien, Modellartefakte oder Schlüssel. Beim ersten Befehl entsteht ein versionierter JSON-Schlüsselbund
mit einem zufälligen 32-Byte-Master-Key in `.novooa/runtime-master-key`;
das Verzeichnis ist ignoriert. Der netzwerklose Init-Dienst übernimmt ihn einmalig
in das separate Schlüssel-Volume. Dort liegt der maßgebliche, automatisch rotierende
Schlüsselbund unter `/var/lib/novooa-keys/runtime-master-key`, mit Datei-Rechten
`0600`, Verzeichnis-Rechten `0700` und Eigentümer `node` (UID/GID 1000).
Spätere Starts übernehmen die Setup-Datei nicht erneut. Sie ist nach Rotationen
kein aktuelles Backup des Schlüsselbunds. Beim vollständigen Neuaufsetzen müssen
beide Volumes und die Setup-Datei gemeinsam berücksichtigt werden.
Eine auslieferbare Desktop-App erzeugt dieselbe Datei bei der Installation im
betriebssystemspezifischen Novooa-Datenverzeichnis und setzt
`NOVOOA_LOCAL_SECRETS_DIRECTORY` darauf. Der Master-Key darf weder im Docker-
Image noch im SQLite-Volume liegen. Bei dessen Verlust müssen gespeicherte
Provider-Keys erneut hinterlegt werden.

## Feldverschlüsselung und Master-Key-Rotation

Standalone verschlüsselt ausschließlich sensible Feldwerte, derzeit Provider-API-Keys
und das Lizenz-Aktivierungsgeheimnis. SQLite, allgemeine Dokumente und Dateien werden
nicht vollständig verschlüsselt. Eine zukünftige Enterprise-Vollverschlüsselung
ist eine zusätzliche Speicherebene mit eigenem Schlüssel und Rotationsprozess;
sie ist hier noch nicht implementiert.

Jeder gespeicherte sensible Wert erhält einen zufälligen 256-Bit-Datenschlüssel.
AES-256-GCM verschlüsselt den Wert mit diesem Schlüssel. HKDF-SHA-256 leitet
aus dem aktiven Master-Key, einem zufälligen 32-Byte-Salt und einem eindeutig
JSON-kodierten Feldkontext einen separaten Schlüssel ab, der den Datenschlüssel
mit AES-256-GCM schützt. Der Master-Key wird niemals direkt als AES-Schlüssel verwendet.
Beide Verschlüsselungen verwenden eigene zufällige 12-Byte-IVs und 16-Byte-Tags.
AAD bindet sie an Formatversion, Zweck und erwarteten Feldkontext. Der Kontext
enthält für Provider-Keys die Secret-Referenz einschließlich Workspace und
Verbindungs-ID; für die Lizenz Workspace-, Lizenz- und Aktivierungs-ID.

Die Envelope enthält Version, Master-Key-ID, Salt, verschlüsselten Datenschlüssel
und verschlüsselten Feldwert mit ihren jeweiligen IVs und Tags. Datenschlüssel
werden nicht im Klartext persistiert. Die Kryptografie verwendet `node:crypto`.
Cloud-Credentials behalten ihre separate bestehende Verschlüsselung.
Der Init-Dienst kann eine bestehende 32-Byte-Base64-Setup-Datei übernehmen und
behält dabei das vorhandene Schlüsselmaterial. Beim Start übernimmt die Runtime
vorhandene Geheimnisse im bisherigen AES-GCM-Feldformat einmalig in Envelopes.
Sie authentifiziert dafür die alten Werte mit den verfügbaren Master-Keys und
speichert ausschließlich erfolgreich entschlüsselte Werte im neuen Format.
Ein fehlender oder falscher Schlüssel führt zu einem Startfehler und keiner Löschung.

### Automatische monatliche Rotation

Die Runtime rotiert den Master-Key automatisch im laufenden Betrieb, einen
Kalendermonat nach der Einrichtung bzw. der letzten erfolgreichen Rotation.
Der Schlüsselbund speichert diesen Zeitpunkt als `lastRotatedAt`. Die Berechnung
erfolgt in UTC, mit gleicher Uhrzeit; fehlt der Tag im Folgemonat, wird dessen
letzter Tag verwendet, beispielsweise 31. Januar → 28. Februar.

Beim Start prüft die Runtime sofort, ob eine Rotation fällig oder unterbrochen ist.
Nach längerer Abschaltung wird eine fällige Rotation einmal nachgeholt; ausgefallene
Monate erzeugen keine unnötigen Zwischen-Keys. Ein Timer prüft spätestens nach
24 Stunden erneut und plant die nächste Fälligkeit innerhalb dieses Zeitfensters
genau ein. Der Zeitpunkt bleibt über Neustarts erhalten.

Die Runtime sichert den neuen Key, bevor der gemeinsame Cipher ihn für neue
Schreibvorgänge übernimmt. Bestehende Verbraucher lesen weiterhin ältere Werte
und verwenden sofort den neuen aktiven Key für neue Verschlüsselungen.
SQL-Schreibvorgänge wählen ihren Schlüssel innerhalb der Transaktion; die
Lizenzdatei wird über einen gemeinsamen seriellen Zugriff gespeichert und
umgeschlüsselt, damit parallele Aktivierungen erhalten bleiben.
Ein Neustart oder eine Nutzeraktion ist für die monatliche Rotation nicht erforderlich.

Fehler werden als `local_runtime.master_key_rotation_failed` protokolliert und
nach fünf Minuten erneut versucht. Eine unterbrochene Rotation verwendet den
bereits gesicherten neuen Key weiter. Erfolg wird als
`local_runtime.master_key_rotated` mit der Anzahl umgeschlüsselter Datenschlüssel
protokolliert. Beim Herunterfahren wartet die Runtime auf die laufende Prüfung,
bevor sie die Datenbank schließt. Automatische Rotationen entfernen keine alten
Master-Keys, damit bestehende Backups nutzbar bleiben.

### Zusätzliche manuelle Rotation mit Docker Compose

Vorher Daten- und Schlüssel-Volume gemeinsam sichern. Für eine zusätzliche
manuelle Wartungsrotation muss die Runtime gestoppt sein:

```bash
docker compose -f docker-compose.local.yaml stop runtime
docker compose -f docker-compose.local.yaml --profile maintenance run --rm --build key-rotation
docker compose -f docker-compose.local.yaml up --detach runtime
```

Der Wartungscontainer hat kein Netzwerk und bindet den Schlüsselbund beschreibbar
ein. Er läuft als root, um das geschützte Schlüssel-Volume und das Datenvolume
bearbeiten zu können; beim atomaren Dateiaustausch bleibt der bestehende Eigentümer
erhalten. Der normale Runtime-Container läuft weiterhin als `node` und kann das
separate persistente Schlüssel-Volume selbst beschreiben. Weil ein Verzeichnis
statt einer einzelnen Schlüsseldatei eingebunden ist, bleiben atomar ersetzte
Schlüsseldateien sichtbar.

Für eine Installation ohne Docker:

```bash
npm --prefix functions run local-runtime:rotate-key -- \
  --secret-file /pfad/secrets/runtime-master-key \
  --runtime-root /pfad/runtime-daten
```

Runtime und Wartungsbefehl halten denselben Prozess-Lock im Datenverzeichnis
über `proper-lockfile`. Nach einem harten Abbruch verfällt der Lock nach
30 Sekunden. Jede Runtime benötigt ihren eigenen Schlüsselbund; derselbe
Schlüsselbund darf nicht zwischen unabhängigen Runtime-Datenverzeichnissen geteilt werden.

Die Rotation sichert zuerst den neuen aktiven Master-Key zusammen mit allen alten
Keys und `rotationPending: true`. Erst anschließend werden Datenschlüssel in
SQLite in Batches und das Aktivierungsgeheimnis in der Lizenzdatei umgeschlüsselt.
Der Feld-Ciphertext bleibt erhalten. Einzelne SQLite-Updates sind atomar und
prüfen den bisherigen Wert; Dateien werden mit restriktiven Rechten, Dateisynchronisation
und atomarem Rename ersetzt. Unter Unix wird zusätzlich das Verzeichnis synchronisiert.
Während einer unterbrochenen Rotation darf die Runtime mit beiden Keys lesen und
mit dem neuen Key schreiben. Die Fortsetzung verarbeitet auch solche neuen Werte.

Bei einem Fehler bleibt der neue Key bereits gesichert und alle alten Keys bleiben
verfügbar. Die automatische Rotation oder derselbe Wartungsbefehl setzt die
begonnene Rotation fort, ohne einen weiteren Master-Key zu erzeugen.
Vor Abschluss werden alle aktuellen Feldwerte
authentifiziert und ihre aktive Master-Key-ID geprüft.

### Alte Schlüssel und Backups

Standardmäßig bleiben alte Master-Keys im Schlüsselbund, damit frühere Backups
wiederherstellbar sind. Wenn die betreffenden Backups abgelaufen sind oder ihr
Schlüsselbund separat sicher archiviert wurde, kann eine Rotation die alten Keys
nach erfolgreicher Prüfung entfernen:

```bash
docker compose -f docker-compose.local.yaml stop runtime
docker compose -f docker-compose.local.yaml --profile maintenance run --rm key-rotation \
  node lib/shared/local/local-runtime-key-rotation-cli.js --retire-old-keys
docker compose -f docker-compose.local.yaml up --detach runtime
```

`--retire-old-keys` entfernt alle inaktiven Keys aus dem aktuellen Schlüsselbund.
Alte Backups sind danach nur noch mit einem passenden archivierten Schlüsselbund
entschlüsselbar. Dieser Befehl ist eine reguläre Rotation, keine Sanierung nach
einem kompromittierten Master-Key: Dafür müssen zusätzlich neue Datenschlüssel
erzeugt und die Feldwerte erneut verschlüsselt werden.

## Nächste Schritte

1. Docker-Engine- und Stack-Status in der Desktop-App anzeigen sowie den Stack
   kontrolliert starten und stoppen.
2. Das Lizenz-Gateway mit Firebase-Secret und Produktions-Compose ausrollen.
3. Freigabe-Ereignisse über den Cloud-Gateway in Firestore/FCM spiegeln.
4. SQLite-Backups und versionierte Images für die auslieferbare Desktop-App
   umsetzen.
