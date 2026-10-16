# Architecture

Cross-cutting Themen für novooa. Feature-spezifische Inhalte liegen in
[`features/`](./features/).

## Schichten

```
┌────────────────────────────────────────────────────────┐
│ Presentation   (lib/features/*/presentation/)          │
│   Cubits / Pages / Widgets                             │
├────────────────────────────────────────────────────────┤
│ Domain          (lib/features/*/domain/)               │
│   Entities / Repository-Interfaces / UseCases          │
├────────────────────────────────────────────────────────┤
│ Infrastructure  (lib/features/*/infrastructure/)       │
│   Repository-Implementierungen (in-memory, Firestore)  │
└────────────────────────────────────────────────────────┘
```

Regel: Abhängigkeiten zeigen **nach innen**. Presentation darf Domain
referenzieren, Domain kennt weder Presentation noch Infrastructure, und
Infrastructure implementiert ausschließlich Domain-Interfaces.

Die lokale Runtime folgt demselben Prinzip auf Backend-Seite: Task Runner,
NodeExecutors und Worker hängen an Store-Ports; Firestore und SQLite-
Adapter sind austauschbare Implementierungen. Details stehen in
[`index/lokale-runtime.md`](./index/lokale-runtime.md).

## Lokalisierung

- Paket `easy_localization` (^3.0.8); Sprachen `en` (Standard, Rückfall), `de` und `tr`.
  Ohne gespeicherte Wahl gilt die Gerätesprache, sofern unterstützt; Wechsel unter
  Einstellungen (`LanguageSettingsSection`), gespeichert von easy_localization.
- Texte: `assets/translations/{en,de}.json`; typisierte Schlüssel in
  `lib/core/localization/locale_keys.g.dart` (nach Änderung neu generieren, Befehl
  in `CLAUDE.md` § 4). `translations_test.dart` erzwingt gleiche Schlüsselmengen.
- `domain/` bleibt frei von `easy_localization`. Sprachabhängige Standardtexte kommen
  über Ports (z. B. `NodeTextDefaults`), deren `tr()`-Implementierung in `presentation/` liegt.
- Stand der Migration: gesamte Aufgabenstudio- und Agent-Panel-Oberfläche (`task_builder/presentation`,
  `assistant/presentation`; Texte unter `ui.*` in den JSON-Dateien, Platzhalter `{name}` per `namedArgs`),
  Baustein-Labels und Standardnamen, Einstellungen → Sprache. Übrige Features sowie Texte in Domain und
  Infrastructure sind noch deutsch und folgen feature-weise.
- KI-Agent: Der Client sendet `locale`; das Backend hängt die Antwortsprache an den Prompt
  (siehe [`features/ki-agent.md`](./features/ki-agent.md)).

## Datenmodell (Überblick)

| Entität             | Datei                                                                  | Rolle                            |
| ------------------- | ---------------------------------------------------------------------- | -------------------------------- |
| `TaskDefinition`    | `lib/features/task_builder/domain/entities/task_definition.dart`       | Aggregate Root eines Workflows   |
| `WorkflowNode`      | `lib/features/task_builder/domain/entities/workflow_node.dart`         | Ein Baustein (Primitive-Instanz) |
| `WorkflowEdge`      | `lib/features/task_builder/domain/entities/workflow_edge.dart`         | Gerichtete Kante                 |
| `NodeId`            | `lib/features/task_builder/domain/entities/workflow_node.dart`         | Value Object (`==` + `hashCode`) |
| `WorkflowPrimitive` | `lib/features/task_builder/domain/entities/workflow_node.dart`         | Enum der Bausteintypen           |
| `DocumentStore`     | `functions/src/features/data/domain/repositories/document-store.ts`    | Port für team-scoped Datensätze  |

Detailtiefe pro Feature in [`features/aufgabe.md`](./features/aufgabe.md).

## Persistenz

### Architekturentscheidung: SQLite und Firebase unterstützen

Der Stand aller 28 SQLite-Tabellen, bekannte funktionale Abhängigkeiten und
verbleibende Arbeiten stehen in der
[Normalisierungsprüfung](./architecture/sqlite-normalisierung.md).

Standalone verwendet weiterhin SQLite. Der Cloud-Betrieb verwendet weiterhin
Firebase mit Firestore. Beide Betriebsarten teilen fachliche Modelle und
Verträge; ihre physischen Speicherstrukturen dürfen sich unterscheiden.
Ein Wechsel zu MongoDB ist nicht vorgesehen.

Für beide Backends gelten die folgenden fünf Regeln:

1. **Ein gemeinsames fachliches Modell.** Dateien, Dateiversionen, Mitarbeiter
   und Aufgaben haben in beiden Betriebsarten dieselbe Bedeutung. Domain-
   Entitäten, Use Cases und Repository-/Store-Schnittstellen bleiben unabhängig
   von Datenbank und Framework. SQL-Zeilen und Firestore-Snapshots gehören
   ausschließlich in die Infrastructure.
2. **Eigene Speichermodelle je Backend.** SQLite darf stabile Beziehungen
   normalisiert in Tabellen speichern. Firestore darf Daten in Dokumenten
   einbetten oder auf Collections verteilen. Adapter und Mapper übersetzen
   beide Darstellungen in dieselben fachlichen Objekte. Flexible
   Workflow-Konfigurationen, Snapshots und frei definierbare Dokumente dürfen
   in SQLite weiterhin als JSON gespeichert werden; ein identisches
   physisches Schema ist kein Ziel. Konkrete SQLite-Adapter tragen das Präfix
   `SQLite` im Klassennamen und `sqlite-` im Dateinamen, beispielsweise
   `SQLiteTeamFileStore` in `sqlite-team-file-store.ts`. SQLite-spezifische
   Abfragen, Mapper und Projektionen verwenden ebenfalls `sqlite-`.
   `Local` bezeichnet die lokale Runtime beziehungsweise ihre HTTP-Clients
   und Dateisystemdienste; `Firestore` bezeichnet Firestore-Adapter.
3. **Eine maßgebliche Quelle je Information.** Dateigröße und Speicherpfad
   gehören beispielsweise zur Dateiversion. Zusätzliche Kopien für schnelle
   Listenansichten sind ausdrücklich abgeleitete Daten. Für solche Kopien
   müssen Aktualisierung, Konsistenz und Wiederherstellung definiert sein.
   Historische Snapshots sind eigenständige Fakten und werden von Kopien
   aktueller Werte unterschieden.
4. **Dieselben Konsistenzregeln.** Fachlich zusammengehörige Änderungen wie
   „Dateiversion anlegen und aktuelle Version umstellen“ bilden eine atomare
   Operation im Repository-/Store-Vertrag. Der SQLite-Adapter verwendet eine
   SQL-Transaktion; der Firestore-Adapter verwendet eine Transaktion oder,
   wenn keine vorausgehenden Leseprüfungen nötig sind, einen atomaren Batch.
   Teamgrenzen und fachliche Invarianten gelten in beiden Backends und werden
   zusätzlich durch die jeweils verfügbaren Schutzmechanismen abgesichert.
5. **Gemeinsame Vertragstests.** Beide Adapter werden gegen dieselben
   fachlichen Erwartungen geprüft: Teamgrenzen, Versionierung, Löschverhalten,
   Sortierung, Fehlerfälle und konkurrierende Änderungen. Backend-spezifische
   Tests ergänzen diese Prüfungen für Constraints, Indizes und Transaktionen.

Diese Regeln sind die Zielvorgaben für weitere Änderungen; sie behaupten
nicht, dass alle bestehenden Adapter bereits vollständig danach umgesetzt
sind. Die Unterstützung beider Betriebsarten beinhaltet keine automatische
Synchronisierung zwischen Cloud und Standalone. Eine solche Funktion benötigt
einen eigenen Vertrag einschließlich Konfliktregeln.

### Bestehendes Persistenzverhalten

- Sichtbarer, veränderlicher Firestore-Zustand wird im Client über
  Repository-Streams (`watch*`) bezogen. Cubits halten ihre Subscription nur
  für ihre Lebensdauer und kündigen sie in `close()`. Einmalige `get()`-Reads
  bleiben auf technische Schreibabläufe, Transaktionen und direkte
  Mutationsrückgaben beschränkt.
- Im Web verwendet Firestore einen persistenten IndexedDB-Cache mit
  Multi-Tab-Synchronisierung. Dadurch bleiben bereits geladene Daten bei einer
  temporären Offlinephase verfügbar; der Cache darf daher nur auf
  vertrauenswürdigen Geräten verwendet werden.
- Ein globaler Browser-Netzstatus zeigt bei fehlender Verbindung dauerhaft eine
  Snackbar. Die Firestore-Repositories behalten dabei unverändert ihre
  Stream-Schnittstellen und liefern gecachte Snapshots.
- Die Team-ID wird vor jeder team-scoped Abfrage über einen normalen
  Firestore-Read mit Cache-Fallback aufgelöst. Eine Transaktion wird nur für
  die erstmalige Anlage eines Arbeitsbereichs verwendet, da Transaktionen
  offline nicht ausgeführt werden können.
- Team-scoped Live-Abfragen basieren auf `watchCurrentTeamId()`. Ändert sich
  die `teamId` im Nutzerprofil, wird die vorherige Sammlung abgemeldet und die
  entsprechende Sammlung des neuen Teams live abonniert.
- Aufgaben werden in Firestore unter `teams/{teamId}/tasks/{taskId}` gespeichert.
- Der Task Builder arbeitet mit Autosave: Beim Öffnen einer neuen Aufgabe und
  nach jeder Mutation ruft der Cubit `TaskRepository.saveTask()` auf.
- Es gibt keinen expliziten Speichern-Button. Nutzer:innen müssen den
  Persistenzzeitpunkt nicht selbst verwalten.
- `TaskRepository` bündelt Entwurfs-Persistenz und Ausführung. Die konkrete
  Implementierung `FirebaseTaskRepository` speichert in Firestore und ruft für
  die Ausführung die Firebase Callable Function über `TaskRunnerDatasource` auf.
- Bei der Ausführung sendet der Client nur `taskId` und optionalen Kontext.
  Die Callable Function ist authentifiziert, lädt die Aufgabe serverseitig aus
  `teams/{teamId}/tasks/{taskId}`, erstellt
  `teams/{teamId}/taskRuns/{runId}` und gibt sofort die `runId` zurück.
- Die eigentliche Ausführung läuft über Cloud Tasks. Nach dem Erstellen des
  `taskRuns/{runId}`-Dokuments enqueue't das Backend einen Task mit
  `{teamId, runId, mode}`. Der Task-Queue-Worker lädt den Run aus Firestore und
  führt ihn aus. Activity-Logs werden unter
  `teams/{teamId}/activities/{activityId}` gespeichert.
- Architekturentscheidung: Nicht abgeschlossene `TaskRunDocument`-Dokumente
  bleiben die Quelle der Wahrheit für Status, UI, Freigaben und Wiederaufnahme.
  Nach erfolgreichem Abschluss wird der Run gelöscht; der Verlauf bleibt über
  die zugehörigen Activity-Logs erhalten. Cloud Tasks ersetzt nur den
  Ausführungsauftrag, Retry und Concurrency-Steuerung, nicht den persistierten
  Zustand eines laufenden Runs.
- Freigaben, Formulareingaben und Medienaufnahmen laufen über
  `reviewTaskRunFlow`: Eine Bestätigung, validierte Formulardaten oder eine
  geprüfte Datei-Referenz setzen einen pausierten Run anhand von `resumeState`
  fort. Eine Ablehnung verwirft den Zwischenzustand und setzt den Run auf
  `rejected`.
- Firestore-Dokumente enthalten `id`, `title`, `objective`, `selectedNodeId`,
  `teamId`, `graph`, `createdAt` und `updatedAt`.
- Sprachmodelle sind team-scoped. `languageModelConnections` enthalten
  Anbieter-Metadaten und den zugehörigen Endpunkt. Google AI bleibt nativ;
  xAI (Grok), Mistral AI, OpenRouter, Abacus.AI (RouteLLM) und Hugging Face
  verwenden festgelegte OpenAI-kompatible Endpunkte; ElevenLabs läuft über sein
  SDK und bietet nur Sprachausgabe. Nur der generische OpenAI-kompatible Anbieter
  erlaubt eine frei gewählte HTTPS-Adresse;
  `languageModels` referenzieren eine Verbindung und eine konkrete Modell-ID.
  API-Keys werden ausschließlich durch Callable Functions verschlüsselt unter
  `languageModelSecrets` gespeichert. Diese Collection ist weder im Client
  lesbar noch beschreibbar. In der lokalen Runtime werden dieselben Metadaten
  in SQLite und die Secrets im lokalen Secret Store abgelegt.

### Teams und Dateien

In der lokalen Ausführung bestimmen Runs die Teamzugehörigkeit ihrer Queue-Jobs
und Schrittergebnisse. Diese Tabellen speichern nur `run_id`; die SQLite-Adapter
lösen das Team über `task_runs` auf und sichern Zugriffe entsprechend ab.
Schrittergebnisse bleiben flexible JSON-Snapshots.

SQLite trennt Benutzerprofile (`user_profiles`, Schlüssel `uid`) von
Teammitgliedschaften (`team_members`, Schlüssel `team_id` + `uid`). E-Mail und
Anzeigename gehören zum Benutzerprofil; Rolle und Mitgliedschaftszeitpunkte
gehören zur jeweiligen Teamzuordnung. Fremdschlüssel sichern beide Beziehungen
ab. Die Initialisierung des lokalen Arbeitsbereichs legt Profil, Team und
Mitgliedschaft gemeinsam in einer Transaktion an. Firestore behält seinen
separaten Adapter und seine eigene Speicherstruktur.

Dateien sind von Beginn an team-scoped modelliert, auch wenn aktuell nur ein
persönlicher Arbeitsbereich verwendet wird.

Firestore:

```text
users/{uid}/notifications/{notificationId}
teams/{teamId}
teams/{teamId}/members/{uid}
teams/{teamId}/tasks/{taskId}
teams/{teamId}/taskTriggers/{triggerId}
teams/{teamId}/taskRuns/{runId}
teams/{teamId}/activities/{activityId}
teams/{teamId}/communicationChannels/{channelId}
teams/{teamId}/mailConnectors/{connectorId}
teams/{teamId}/inboxes/{channelId}/conversations/{conversationId}
teams/{teamId}/inboxes/{channelId}/conversations/{conversationId}/messages/{messageId}
teams/{teamId}/folders/{folderId}
teams/{teamId}/files/{fileId}
teams/{teamId}/files/{fileId}/versions/{versionId}
modelCatalog/{modelId}
licenses/{tokenHash}
teams/{teamId}/knowledgeBases/{knowledgeBaseId}
teams/{teamId}/knowledgeBases/{knowledgeBaseId}/notes/{noteId}
```

Team-Einladungen werden als Notification unter
`users/{uid}/notifications/{notificationId}` geschrieben. Die Annahme der
Einladung setzt `users/{uid}.teamId` und erstellt
`teams/{teamId}/members/{uid}`.
HITL-Freigaben werden ebenfalls als Notification (`taskRunApproval`) unter den
Team-Mitgliedern verteilt, lösen zusätzlich einen FCM-Push aus und öffnen im
Client den Freigabe-Dialog. Nicht mehr registrierte Geräte-Tokens entfernt das
Backend nach einer fehlgeschlagenen Zustellung. Identische Tokens werden vor
dem Versand dedupliziert.

Lokale Lizenzen liegen als backend-only Dokumente unter `licenses/{tokenHash}`
in Firestore. Der Hash ist SHA-256 eines sechzehnstelligen Aktivierungstokens; der
Roh-Token wird nie gespeichert. Jedes Dokument enthält Name, Lizenz- und
Arbeitsbereich-ID, Ablaufdatum sowie `inUse`. Die Aktivierung setzt in einer
Firestore-Transaktion `inUse`, eine zufällige `activationId` und nur den Hash
eines zufälligen Aktivierungsgeheimnisses. Das Lizenz-Gateway liefert der Runtime
eine Ed25519-signierte Lizenz plus Geheimnis. Die Runtime speichert das Geheimnis
per Envelope Encryption mit einem eigenen Datenschlüssel; der lokale Master-Key
schützt diesen ausschließlich über einen per HKDF abgeleiteten Schlüssel.
Der Token verbleibt weder dort noch in
Firestore. Eine Freigabe weist `activationId` und Geheimnis nach, setzt
`inUse` zurück und macht den Token für genau eine neue Aktivierung frei. Das
Push-Relay prüft zusätzlich die aktive `activationId`, sodass freigegebene
Altinstallationen keine Cloud-Relay-Funktionen mehr verwenden können.
Im Flutter-Web-Client zeigt FCM Hintergrund-Pushes selbst an. Der FCM-Klick
öffnet auf Desktop die App-Startseite, ohne die aktuelle Arbeit automatisch
zur Aktivitätenansicht umzuleiten. Mobile PWAs lesen den Klick-Payload aus und
öffnen die zugehörige Freigabe. Im Vordergrund erscheint dieselbe
Benachrichtigung als Snackbar.

In der lokalen Desktop-Variante registriert der Client seinen FCM-Token nur
über die Loopback-Runtime. Ein Cloud-Relay validiert die signierte Lizenz gegen
den aktuellen Firestore-Status, speichert die Token lizenzgebunden und versendet
Freigabe-Pushes. Dadurch besitzen weder die Desktop-App noch der lokale
Container Firebase-Admin-Zugang oder Cloud-Messaging-Credentials.

Kommunikation trennt novooa-eigene System-E-Mails von Kundenpostfächern.
System-E-Mails wie Benachrichtigungen, Einladungen und Marketing versendet
novooa global über SendGrid. Die Absenderdomain `novooa.de` ist per Domain
Authentication verifiziert; der Function-Secret `SENDGRID_API_KEY` erhält nur
die Berechtigung `mail.send`. Dieser Versanddienst ist kein Kundenpostfach und
kann keine vorhandenen E-Mails lesen.

Kommunikationskanäle wie E-Mail, WhatsApp und SMS werden im Client unter
`Einstellungen > Kommunikation` gepflegt und bleiben bewusst team-scoped.
Provider-Credentials werden nicht im Client erfasst. Für Twilio provisioniert
novooa intern einen Subaccount pro Team und speichert dessen SID am
Team-Dokument (`twilioSubaccountSid`). Die Nutzeroberfläche zeigt keine
Provider-Begriffe wie Twilio, Subaccount oder Account SID.

Kundenpostfächer werden innerhalb des Features Kommunikation über
Mail-Connectoren angebunden:
Microsoft 365 und Outlook.com über OAuth und Microsoft Graph, später Gmail und
Google Workspace über OAuth und die Gmail API sowie weitere Anbieter über
IMAP/SMTP. Ein Connector gehört zu einem Team, speichert Zugangsdaten
verschlüsselt und versendet Antworten über dasselbe verbundene Postfach. Jeder
E-Mail-Baustein verwendet einen aktiven Connector; SendGrid ist dafür nicht
verfügbar. Der Connector ist die technische Implementierung eines E-Mail-
`CommunicationChannel`: Er verwaltet OAuth und Tokens, während Aufgaben,
Trigger und die Oberfläche ausschließlich mit der gemeinsamen
Kanalabstraktion arbeiten.

WhatsApp meint eine WhatsApp-Business-Nummer auf der WhatsApp Business
Platform. Bestehende WhatsApp-Business-App-Nummern werden nicht parallel
gesynct, sondern über das offizielle Onboarding migriert bzw. verbunden. Neu
angelegte WhatsApp-Kanäle starten daher mit `status: "pendingVerification"`
und werden erst nach erfolgreicher Verifizierung/Migration aktiv.

Storage:

```text
teams/{teamId}/files/{fileId}/versions/{versionId}/{fileName}
```

Modelldateien liegen nicht in Firebase Storage, sondern im globalen Modellspeicher
(Hetzner Object Storage) unter `model-artifacts/{artifactId}/versions/{versionId}/`
(siehe [ML-Modelle](./features/ml-modelle.md)).

Der aktuelle Client erzeugt für angemeldete Nutzer:innen automatisch ein
Team-Dokument mit generierter ID und speichert die Referenz im User-Dokument:

```text
users/{uid}.teamId = "{teamId}"
teams/{teamId}
teams/{teamId}/members/{uid}
```

Die Team-ID wird nicht aus der UID abgeleitet. Client und Functions lösen den
aktuellen Team-Kontext über `users/{uid}.teamId` auf. Aufgaben,
Datei-Metadaten, Aktivitäten und Storage-Pfade bleiben team-scoped.

Copy-on-Write wird über `versions/{versionId}` vorbereitet. Eine neue
Dateiversion schreibt ein neues Storage-Objekt und aktualisiert am
Datei-Dokument `currentVersionId`.

Detailtiefe in [`features/dateien.md`](./features/dateien.md).

### Teams und Wissensbasis

Die Wissensbasis ist team-scoped, aber nicht wie Dateien versioniert. Der
aktuelle Startpunkt ist eine `default`-Knowledge-Base pro Team:

```text
teams/{teamId}/knowledgeBases/default/notes/{noteId}
```

Eine Notiz enthält Markdown-Content, Metadaten (`title`, `path`) und
`outgoingLinks` als Liste verlinkter Notiz-IDs. SQLite berechnet diese Liste
seit `0019` beim Lesen aus Markdown und dem aktuellen Notizbestand desselben
Teams und derselben Wissensbasis; Firestore speichert sie über seinen eigenen
Adapter als Client-Projektion. Eine angehängte Notiz stellt
immer sich selbst plus rekursiv verlinkte
Notizen bereit. Anhänge werden an unterstützten Bausteinen gespeichert; aktuell
ist nur der Prompt-Baustein angebunden.

Detailtiefe in [`features/wissensbasis.md`](./features/wissensbasis.md).

## Auth & AppCheck

Die Section **Passwort neu setzen** in den allgemeinen Einstellungen verwendet
`SetNewPassword` und einen separaten `PasswordRepository`-Port. Der Cloud-Adapter
ändert das Passwort des angemeldeten Firebase-Nutzers über `User.updatePassword`;
der Standalone-HTTP-Adapter nutzt die authentifizierte Runtime-Route
`PUT /v1/auth/password` (siehe [Runtime-Dokumentation](notes/passwort-aendern.md)).
Das Formular enthält ein neues Passwortfeld mit Klartext-Umschaltung, ohne
aktuelles Passwort oder Wiederholung. Firebase kann `requires-recent-login`
melden; dann zeigt die App einen Hinweis auf erneute Anmeldung. Der Cubit hält
keine Passwörter im State und schützt vor parallelem Speichern.

- Auth-Source: Firebase Auth (anzubinden).
- `onCallGenkit` unterstützt `authPolicy` (`hasClaim`, `isSignedIn`).
- `enforceAppCheck: true` aktivieren, sobald das erste Feature produktiv geht.
- Secrets (Modell-API-Key) ausschließlich via
  `defineSecret("GOOGLE_GENAI_API_KEY")`.

## Trigger-Modell (geplant)

| Trigger-Typ     | Quelle                    | Umsetzung                                  |
| --------------- | ------------------------- | ------------------------------------------ |
| Manuell         | UI-Button „Jetzt starten" | Direkter `onCallGenkit`                    |
| Zeitgesteuert   | `taskTriggers`            | Scheduled Function → `taskRuns`            |
| Event           | Geräte- / Webhook-Event   | Firestore-Trigger oder HTTPS-Webhook       |
| Freigabe        | Mensch bestätigt          | Genkit-Interrupt + Task-Rückkanal          |

Detailtiefe im Inhaltsverzeichnis [`index/zeitplan.md`](./index/zeitplan.md).

## Telemetrie

- `enableFirebaseTelemetry()` aus `@genkit-ai/firebase` aktivieren — Traces
  und Metrics landen in Google Cloud Observability.
- Im Client: `firebase_crashlytics` ergänzen, sobald produktiv.

## Genkit-Backend (allgemein)

### Konventionen für neue Flows

- Flow-Namen: `camelCase`, enden auf `Flow`.
- Datei: feature-spezifische Flows in `<feature>-workflows.ts`. Wenn der Flow
  keinem Feature zugeordnet ist (z. B. ein Querschnitts-Service), eigene
  gleichnamige Datei.
- **Schemas:** `inputSchema` / `outputSchema` mit **Zod** (`z.object(...)`).
  Keine `any`-Typen in der Schnittstelle.
- **Modell:** Flows verwenden keine Provider direkt. Modell-Plugins und
  ModelRefs werden zentral über
  `functions/src/features/task_execution/infrastructure/genkit/runner/ai-models.ts`
  bereitgestellt. Unterstützte Profile sind `google`, `minimax`,
  `openai-compatible` und `local`.
- **Export:** Jeder Flow wird in `functions/src/index.ts` re-exportiert.
- **Secrets:** Cloud-Provider-API-Keys via Secret Manager / Runtime-Env. Lokale
  Runtimes verwenden eigene lokale `.env`-Werte und dürfen keine produktiven
  Cloud-Secrets voraussetzen.
- **Streaming:** `streamSchema` setzen, wenn der Flow gestreamt werden soll.

### Vorhandene Flows

| Flow                          | Datei                            | Status                          |
| ----------------------------- | -------------------------------- | ------------------------------- |
| `runTaskDefinitionFlow`       | `functions/src/task-workflows.ts` | Produktiv (Feature Aufgabe)     |
| `reviewTaskRunFlow`           | `functions/src/task-workflows.ts` | Produktiv (Feature Aktivitäten) |
| `menuSuggestionFlow`          | `functions/src/genkit-sample.ts` | Vorlage — nicht produktiv       |

Feature-spezifische Detailtiefe (Inputs, Outputs, Executor-Registry) in
[`features/aufgabe-ausfuehrung.md`](./features/aufgabe-ausfuehrung.md).

### Neue Genkit-Tools

Eigene Tools unter `functions/src/tools/<domain>.ts` ablegen. Jeder Export
eines Tools wird über `ai.defineTool({...}, async (...) => {...})` registriert
und in dem jeweiligen Flow verwendet.
