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

`novooa-runtime` ist der einzige Dienst mit veröffentlichten Host-Ports:
`8090` auf allen Schnittstellen für die reguläre API und `127.0.0.1:8091` für
das einmalige Setzen des Betreiber-Passworts. Clients im LAN geben die private
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

> **Sicherheitsgrenze:** Über eine IP-Adresse läuft der Verkehr
> unverschlüsselt — Passwort und Session-Token gehen im Klartext über das
> Netz. Das ist innerhalb eines vertrauenswürdigen LAN vertretbar, aber
> **niemals aus dem Internet**. Port `8090` darf nicht per Portweiterleitung
> oder Firewallregel öffentlich erreichbar gemacht werden. Für externen
> Zugriff gehört zwingend ein Reverse Proxy mit Domain und Zertifikat davor;
> der Client verwendet dann automatisch HTTPS.

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

Die Runtime veröffentlicht dafür einen zweiten HTTP-Port (Standard `8091`),
der auf dem Docker-Host ausschließlich an `127.0.0.1` gebunden ist
(`docker-compose.local.yaml`, Port-Mapping `127.0.0.1:8091:8091`) — das wird
vom Docker-Host selbst durchgesetzt, nicht durch eine IP-Prüfung im
Anwendungscode (die wäre hinter Docker-NAT unzuverlässig, da der Container je
nach Docker-Implementierung nie die echte `127.0.0.1` des Hosts als
Absenderadresse sieht). `POST /v1/setup` funktioniert genau einmal und sperrt
sich danach dauerhaft (`409`), egal von wo aus er später aufgerufen wird.

- **LAN/lokal**: direkt erreichbar unter `http://127.0.0.1:8091/v1/setup`.
- **VPS**: nur per SSH-Portweiterleitung erreichbar, z.B.
  `ssh -L 8091:127.0.0.1:8091 nutzer@vps-adresse`, danach lokal
  `http://127.0.0.1:8091/v1/setup` aufrufen.

Nach dem Setzen des Passworts meldet sich der Client über
`POST /v1/auth/login` an und erhält ein Session-Token, das er fortan als
`Authorization: Bearer <token>` mitschickt. `/healthz` und `/v1/license/*`
bleiben unverändert außerhalb dieser Passwort-Pflicht — die Lizenzaktivierung
ist bereits durch den Lizenz-Token selbst geschützt.

Der native novooa-Client führt die Einrichtung in dieser Reihenfolge: Runtime-
Adresse, gegebenenfalls Lizenzaktivierung und anschließend das Betreiber-
Passwort. Das Passwort kann nur in einem Client gesetzt werden, der auf dem
Runtime-Rechner selbst läuft, weil der Setup-Port nicht im LAN veröffentlicht
wird.

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

Anwendungsprotokolle liegen getrennt von Workflow-Aktivitäten in
`application_logs`. Der lokale `ApplicationLogger` speichert strukturierte
Info- und Fehlerereignisse dort und gibt sie zusätzlich als JSON nach Docker-
Stdout aus. Der native Flutter-Client sendet seine eigenen Ereignisse per
`POST /v1/application-logs` an die Runtime; diese vergibt ID und
Zeitstempel und markiert die Quelle als `client`. `GET /v1/application-logs`
liefert die jüngsten Einträge an den Client; dieser zeigt sie im Tab
**Aktivitäten → Protokoll**. Der gleiche Port wird in der Cloud durch den
`FirebaseApplicationLogger` auf Firebase/Cloud Logging abgebildet.

Die erste Migration liegt in
[`local-runtime/migrations/001_initial.sql`](../local-runtime/migrations/001_initial.sql).
Sie legt diese Tabellen an:

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

Die Migration
[`004_model_catalog.sql`](../local-runtime/migrations/004_model_catalog.sql)
ergänzt den ONNX-Modellkatalog in der Tabelle `model_catalog`.

[`005_language_models.sql`](../local-runtime/migrations/005_language_models.sql)
ergänzt Provider-Verbindungen und Sprachmodellprofile. Lokale API-Keys liegen
nicht im Klartext in SQLite. Die Migration
[`011_language_model_secrets.sql`](../local-runtime/migrations/011_language_model_secrets.sql)
speichert sie AES-256-GCM-verschlüsselt; `secret_ref` verweist auf den
jeweiligen Eintrag. Der Master-Key liegt separat außerhalb des Daten-Volumes.
Die Flutter-Einstellungen bieten **Google AI**, **xAI (Grok)**, **Mistral AI**,
**OpenRouter**, **Ollama (lokal)** und frei konfigurierbare
OpenAI-kompatible Anbieter an und verbinden sie über `POST
/v1/language-model-connections`. Die Runtime lädt dessen Modellkatalog und
speichert alle verfügbaren Textmodelle unter einer gemeinsamen Verbindung. Die
Modellauswahl findet anschließend im TaskBuilder statt; dort liest der Client
den Katalog über `GET /v1/language-models`. API-Keys werden in keiner Antwort
ausgegeben und ausschließlich im verschlüsselten lokalen Secret Store abgelegt.
xAI, Mistral und OpenRouter verwenden festgelegte HTTPS-Endpunkte und jeweils
den API-Key der Kundschaft; ihre API-Adresse ist nicht frei überschreibbar.
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
Node-Container enthält keinen Python-Interpreter und keine ML-Abhängigkeiten.

Workflow-Werte werden vor der lokalen Inferenz gemäß Manifest in Tensoren
transformiert. `input_transform_worker.py` verwendet für Bildquellen eine
erweiterbare Registry für Dekodierung, Skalierung, Layout und Normalisierung.
Weitere Quelltypen erhalten eigene Strategien; weder die Pipeline noch der
Modell-Baustein sind an Firebase Storage oder Bilder gekoppelt.

## Lizenz und lokale Identität

Die Runtime ist ohne gültigen Lizenzschlüssel nicht nutzbar. Beim Kauf stellt
novooa einen zwölfstelligen Token aus dem Alphabet `A-H`, `J-N`, `P-Z` und
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
speichert Lizenz und Geheimnis verschlüsselt mit ihrem lokalen Master-Key. Damit
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
Die Ausgabe ist der einmalig an den Kunden zu übergebende zwölfstellige Token. Der
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
  Dateiordner hängen nur an `LocalSqlDatabase`.
- Alle Backend-Assistenten verwenden denselben `GenkitAssistantResponder` und
  denselben Laufzeitkontext für Cloud und lokal. Ein lokaler Composition Root
  kann den Wissensbasis-Agenten mit `SQLiteKnowledgeBaseAssistantNoteStore`,
  `SQLiteTeamContextStore` und dem öffentlichen HTTP/HTML-Adapter verdrahten;
  der TaskBuilder-Agent benötigt außer Modell und Prompt keinen Fachadapter.
  Firebase verwendet für den Wissensbasis-Adapter Firestore und Firebase Auth.
- `LocalTeamFileStore` schreibt Dateien in ein lokales Root-Verzeichnis und
  persistiert Datei-/Versions-Metadaten über `LocalSqlDatabase`.
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
- `SqlMigrationRunner` wendet Migrationen treiberneutral über
  `LocalSqlDatabase` an.
- `SqliteLocalSqlDatabase` verwendet die Node-24-Standardbibliothek
  `node:sqlite`, aktiviert Fremdschlüssel, WAL und einen Busy-Timeout. Es
  serialisiert lokale Datenbankzugriffe und normalisiert Zeilen in gewöhnliche
  Records für die lokalen Adapter.
- `openLocalRuntimeDatabase` lädt alle versionierten SQL-Migrationen beim
  Start und schließt die Datenbank wieder, falls eine Migration fehlschlägt.
- `docker-compose.local.yaml` startet `runtime` und `novooa-ml`. Nur
  `runtime` veröffentlicht Host-Ports: `8090` für die API auf allen
  Schnittstellen und den an `127.0.0.1` gebundenen Setup-Port `8091`.
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
docker compose -f docker-compose.local.yaml up --build --detach
curl http://127.0.0.1:8090/healthz
docker compose -f docker-compose.local.yaml ps
flutter run -d macos --dart-define=NOVOOA_RUNTIME=standalone
```

Vor dem ersten fachlichen Zugriff muss einmalig ein Betreiber-Passwort
gesetzt werden (siehe
[Erstmaliges Setzen des Passworts](#erstmaliges-setzen-des-passworts)).

Der Stack legt das benannte Volume `novooa-local_novooa-data` an. Ein
`docker compose down` entfernt weder dieses Volume noch SQLite, Dateien oder
Modellartefakte. Beim ersten Befehl entsteht ein zufälliger 32-Byte-Master-Key
in `.novooa/runtime-master-key`; das Verzeichnis ist ignoriert. Compose bindet
ihn nur für den Node-Dienst als `/run/secrets/novooa_runtime_master_key` ein.
Eine auslieferbare Desktop-App erzeugt dieselbe Datei bei der Installation im
betriebssystemspezifischen Novooa-Datenverzeichnis und setzt
`NOVOOA_LOCAL_SECRETS_DIRECTORY` darauf. Der Master-Key darf weder im Docker-
Image noch im SQLite-Volume liegen. Bei dessen Verlust müssen gespeicherte
Provider-Keys erneut hinterlegt werden.

## Nächste Schritte

1. Docker-Engine- und Stack-Status in der Desktop-App anzeigen sowie den Stack
   kontrolliert starten und stoppen.
2. Das Lizenz-Gateway mit Firebase-Secret und Produktions-Compose ausrollen.
3. Freigabe-Ereignisse über den Cloud-Gateway in Firestore/FCM spiegeln.
4. SQLite-Backups und versionierte Images für die auslieferbare Desktop-App
   umsetzen.
