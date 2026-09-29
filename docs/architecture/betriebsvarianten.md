# Betriebsvarianten: Clients × Cloud/Standalone

> Cross-cutting. Verwandt: [`../architecture.md`](../architecture.md) ·
> [`../local-runtime.md`](../local-runtime.md) ·
> [`../backend-struktur.md`](../backend-struktur.md)

## Zweck

novooa hat zwei Backend-Varianten (**Cloud** über Firebase, **Standalone**
über die lokale Runtime) und zwei Client-Gattungen (**native** Apps und die
**Web-App**). Ziel ist, dass jede Client-Gattung beide Varianten bedienen
kann. Dieses Dokument hält fest, was den Umbau trägt, welche Blocker
tatsächlich bestehen und welcher davon nicht in Software lösbar ist.

## Ist-Zustand

| | Cloud | Standalone |
| --- | --- | --- |
| **Native** (macOS, Windows, iOS, Android) | Ja — Default-Build | Ja — `--dart-define=NOVOOA_RUNTIME=standalone` |
| **Web** | Ja — Firebase Hosting, CI deployt bei Merge auf `main` | **Nein** — `RuntimeProfile.fromEnvironment()` wirft bei `kIsWeb` |

Zwei Einschränkungen, die die Tabelle nicht zeigt:

- Die Variante ist eine **Compile-Zeit-Entscheidung**
  (`const String.fromEnvironment('NOVOOA_RUNTIME')` in
  `lib/core/runtime/runtime_profile.dart`). Auch native sind Cloud und
  Standalone deshalb **zwei getrennte Auslieferungen**, kein umschaltbares
  Binary.
- Keine Variante ist funktional vollständig (siehe
  [Paritätslücken](#paritätslücken)).

## Was den Umbau trägt

Die Architektur ist näher am Ziel als der Ist-Zustand vermuten lässt:

- **Der Client hält keine eigene Datenbank.** Kein sqflite/drift/hive/isar,
  weder in `lib/` noch in `pubspec.yaml`. Alle Fachdaten laufen über
  Domain-Repository-Interfaces — entweder per `package:http`
  (`lib/core/network/workspace_api_client.dart`) oder über die Firebase-SDKs.
  Lokale Persistenz ist ausschließlich `SharedPreferencesAsync` und
  `FlutterSecureStorage`; beide haben Web-Implementierungen. Der Client ist
  damit von sich aus backend-agnostisch.
- **Die DI-Weiche ist bereits parametrisiert.**
  `configureDependencies({RuntimeProfile? runtimeProfile})` in
  `lib/core/di/service_locator.dart` nimmt das Profil als Argument; es wird
  nicht intern aus der Umgebung gelesen.
- **Das Profil wird schon heute zur Laufzeit ersetzt.**
  `RuntimeProfile.withWorkspaceApiUri()` wird vom `RuntimeConnectionGate`
  aufgerufen, bevor die DI läuft — der Mechanismus für eine
  Laufzeitentscheidung existiert also, er entscheidet bloß nur über die
  Adresse, nicht über die Variante.
- **Das Backend ist zur Hälfte geteilt.** Von 428 Nicht-Test-Dateien unter
  `functions/src` liegen 140 in `features/*/domain` und 58 im geteilten
  `infrastructure/genkit`; variantenspezifisch sind 66 unter
  `infrastructure/firebase`, 71 unter `infrastructure/local` und 24 in
  `shared/local` (der Runtime-Host selbst). Beide Pfade verdrahten dasselbe
  `createGenkitTaskWorkflow` und denselben Executor-Registry — es
  unterscheiden sich nur die injizierten Stores.
- **Web ist ein vollwertiges Ziel**, kein Nebenprodukt: `web/index.html`,
  Hosting-Konfiguration in `firebase.json`, und
  `.github/workflows/firebase-hosting-merge.yml` baut und deployt es bei
  jedem Merge.

## Blocker

### 1. Variantenwahl ist an die Compile-Zeit gebunden

`lib/core/runtime/runtime_profile.dart` liest `NOVOOA_RUNTIME` als
`const String.fromEnvironment`. Betrifft alle vier Felder der Matrix, nicht
nur Web.

### 2. Die Runtime liefert die Web-App nicht aus — **der verbleibende Blocker**

Seit Schritt 1 ist Standalone im Web nicht mehr pauschal gesperrt: Die
Herkunftsregel oben ordnet jede Nicht-Cloud-Adresse Standalone zu, und der
Workspace-Endpunkt ist dann die **eigene Herkunft** (`Uri.base.origin`).
Damit das trägt, muss die Runtime das Web-Build unter ihrer Adresse
ausliefern — genau das fehlt noch (siehe Schritt 2 unten).

Der Nebeneffekt ist erfreulich: Same Origin lässt die beiden folgenden
Blocker vollständig entfallen.

### 3. Die lokale Runtime setzt keine CORS-Header

Nur noch relevant, falls das Web-Build jemals von einer **fremden** Origin
gegen eine Runtime sprechen soll. Für den vorgesehenen Weg (Runtime liefert
die App selbst aus) ist CORS gegenstandslos.

`functions/src/shared/local/local-runtime-http-server.ts` setzt in seiner
einzigen Antwortfunktion ausschließlich `content-type`. Kein
`Access-Control-Allow-Origin`, keine OPTIONS-Preflight-Behandlung. Ein
Browser von fremder Origin kommt nicht durch. (Der WebSocket-Pfad
`/v1/realtime` ist nicht CORS-gebunden und würde funktionieren — er prüft
allerdings auch keinen `Origin`, was mit Web-Clients nachzuziehen ist.)

### 4. Mixed Content — durch die Herkunftsregel entschärft

Durch Same Origin tritt der Fall im vorgesehenen Betrieb **nicht mehr auf**:
Eine von `http://192.168.1.42:8090` ausgelieferte App spricht dieselbe
unverschlüsselte Herkunft an — kein Mischbetrieb. Relevant bleibt es nur,
wenn eine über HTTPS ausgelieferte App eine HTTP-Runtime ansprechen soll.

Die lokale Runtime terminiert bewusst kein TLS (siehe
[`../local-runtime.md`](../local-runtime.md)). Für diesen Fall gälte:

| Ziel | Verhalten im Browser |
| --- | --- |
| `http://127.0.0.1:8090` | Erlaubt — Loopback ist „potentially trustworthy origin“. Chrome verlangt zusätzlich einen Private-Network-Access-Preflight. |
| `http://192.168.1.42:8090` (LAN-IP) | **Hart blockiert** als Mixed Content. Kein Codefix möglich. |
| `https://novooa.example.de` (eigener Reverse Proxy) | Erlaubt, braucht nur CORS. |

Deshalb ist „die Runtime liefert die Web-App selbst aus“ nicht nur bequem,
sondern der einzige Weg, der im LAN ohne eigenes Zertifikat funktioniert.
Wer die Runtime aus dem Internet erreichbar macht, stellt ohnehin einen
Reverse Proxy mit Zertifikat davor — dann ist auch die App-Herkunft HTTPS.

### 5. Paritätslücken

Kein reines Plumbing-Problem, sondern der größte Arbeitsanteil:

- **Nur Cloud**: Einstellungen, Nutzerprofile, Mitarbeiter, Fähigkeiten,
  Team-Verwaltung, Kommunikations-Connectoren. Die lokale Runtime hat für
  diese Features keine Endpunkte. Der KI-Agent ist keine Lücke mehr —
  `LocalAssistantHttpHandler` bedient beide Bereiche über die lokale
  Runtime (siehe [`../features/ki-agent.md`](../features/ki-agent.md)).
- **Nur Standalone**: Datensammlungen (`DataRepository`), Anwendungsprotokoll,
  ML-Modellkatalog, Lizenz. Der Cloud-Task-Runner injiziert bewusst einen
  `UnavailableDocumentStore`.
- `lib/features/user/infrastructure/repositories/local_workspace_user_repository.dart`
  ist implementiert und getestet, aber nirgends registriert.

### 6. `isStandalone` ist eine Compile-Zeit-Wahrheit in der UI — **teilweise entschärft**

Zwei getrennte Fragen stecken hier drin:

- **Welche Tabs/Routen existieren.** Weiterhin wird ein `bool isStandalone`
  durch `root_page.dart`, `core/routing/app_router.dart`,
  `core/widgets/root_navigation.dart`, `settings_page.dart`,
  `activity_page.dart` und `auth_form_footer.dart` gefädelt. Unverändert,
  nicht Teil der folgenden Änderung.
- **Ob ein einzelnes Feature innerhalb einer Seite verfügbar ist.** Dafür
  gab es vier Stellen, die dieselbe Frage über
  `serviceLocator.isRegistered<T>()` erraten haben — eine zufällige
  DI-Nebenwirkung als Ersatz für ein fachliches Flag
  (`table_from_collection_widget.dart`, `task_builder_page.dart`,
  `task_builder_side_panel.dart`, `knowledge_base_side_panel.dart`). Das ist
  jetzt `lib/core/runtime/workspace_capabilities.dart`: ein typisiertes
  `WorkspaceCapabilities`-Value-Object (`assistant`, `dataCollections`,
  `modelCatalog`), einmal aus der `RuntimeKind` abgeleitet und in
  `configureDependencies` als Singleton registriert. Die vier genannten
  Stellen lesen jetzt `capabilities.<feld>` statt den Container zu befragen.

`assistant` steht inzwischen für beide Varianten auf `true` — der lokale
Assistant-Endpunkt existiert (siehe Paritätslücken, Punkt 5, und
[`../features/ki-agent.md`](../features/ki-agent.md)).

### 7. Zwei unterschiedliche Identitätsmodelle

Cloud nutzt echte Firebase-Auth-Nutzer. Standalone kennt genau einen
hart kodierten `AuthUser('local-user')` mit `teamId: 'local-team'` hinter
einem Stub-`AuthRepository`; die echte Anmeldung passiert außerhalb des
Repository-Seams im `RuntimeConnectionGate` (Betreiber-Passwort →
Session-Token). Für Standalone im Browser landet dieser Token im
Web-Backend von `FlutterSecureStorage` (WebCrypto + localStorage) und ist
damit XSS-exponiert — deutlich schwächer als Keychain. Bewusst zu
entscheiden, nicht implizit mitzunehmen.

## Ausdrücklich **kein** Blocker

`lib/features/activity/infrastructure/datasources/image_picker_media_input_picker.dart`
importiert `dart:io` und wird von beiden DI-Graphen unbedingt importiert.
Das sieht nach einem Web-Build-Bruch aus, ist aber keiner:

- `flutter build web` wurde verifiziert und läuft durch.
- Der einzige `File()`-Aufruf liegt in `_pickWithDocumentScanner()`, das nur
  über `documentScanSupportedOnThisPlatform()` erreichbar ist — und das ist
  `!kIsWeb && (android || iOS)`.

Hier ist also nichts zu tun. Festgehalten, damit die Stelle nicht erneut als
Blocker aufgeworfen wird.

## Zielbild

1. **Nativ ist die Variante eine Laufzeitentscheidung** der Nutzer:innen,
   persistiert wie schon heute die Runtime-Adresse. `NOVOOA_RUNTIME` bleibt
   der Vorgabewert für den Erststart.

   **Im Web gibt es dagegen nie eine Auswahl — die Herkunft entscheidet:**

   | Herkunft | Variante |
   | --- | --- |
   | `app.novooa.de`, `*.web.app`, `*.firebaseapp.com` | Cloud |
   | jede andere Adresse (die IP oder Domain der eigenen Runtime) | Standalone |

   Das ist nicht nur einfacher, sondern auch sicherer: Eine unter einer
   Cloud-Domain ausgelieferte App kann gar nicht dazu gebracht werden,
   gegen eine fremde Runtime zu sprechen — und umgekehrt. Die Firebase-
   Hosting-Domains gehören dazu, weil sonst der CI-Live-Deploy und jede
   PR-Vorschau als Standalone starten würden. Ein ausdrücklich gesetztes
   `--dart-define=NOVOOA_RUNTIME` gewinnt weiterhin, sonst liesse sich die
   Cloud-Web-App nicht mehr lokal entwickeln (`flutter run -d chrome` läuft
   auf `localhost`, also keiner Cloud-Domain).
2. **Die lokale Runtime liefert die Web-App selbst aus.** Same Origin lässt
   CORS, Mixed Content und Private Network Access auf einmal entfallen und
   macht `WORKSPACE_API_URL` relativ. Die Runtime *ist* bereits ein
   HTTP-Server; ihr fehlt nur das Ausliefern statischer Dateien. Nebeneffekt:
   Standalone-Nutzer bekommen „Browser auf `http://runtime-host:8090`
   öffnen“ ohne Installation.
3. **Die UI fragt nach Fähigkeiten, nicht nach der Variante.** Ein
   `WorkspaceCapabilities`-Value-Object ersetzt `bool isStandalone`. Das ist
   ohnehin das sauberere Design (OCP) und macht Teil-Parität erträglich: die
   Oberfläche verbirgt, was das Backend nicht kann — unabhängig davon,
   welche Variante läuft. Für die Feature-Verfügbarkeit (nicht für die
   Tab-/Routenstruktur) bereits umgesetzt — siehe Blocker 6.

## Umsetzung

Schritte 1–3 sind in sich abgeschlossen und liefern **native × beides aus
einem Binary** sowie **Web × Standalone**. Sie schließen bewusst *keine*
Paritätslücken; das bleibt Schritt 5.

### Schritt 1 — Variantenwahl zur Laufzeit — **umgesetzt**

- `lib/core/runtime/runtime_profile.dart`: neu `RuntimeProfile.forKind(kind)`,
  `defaultKind`, `configuredKind`, `runtimeKindOrNull(name)` sowie
  `supports(kind)`/`supportedKinds`. `NOVOOA_RUNTIME` ist damit nur noch
  **Vorgabe**, keine Festlegung. Die Herkunftsregel fürs Web steckt in den
  reinen Funktionen `isCloudWebHost(host)` und
  `webRuntimeKindForOrigin(uri)` — bewusst ohne direkten `Uri.base`-Zugriff,
  damit sie ohne Browser testbar bleiben.
- `lib/core/runtime/runtime_kind_store.dart` +
  `runtime_kind_preferences.dart`: persistiert die Wahl unter
  `novooa.runtime.kind`, nach dem Muster von `RuntimeEndpointPreferences`.
  Ein unbekannter oder auf dieser Plattform nicht unterstützter Wert wird
  verworfen und weggeräumt, damit ein Altbestand den Start nicht blockiert.
- `lib/main.dart`: `_resolveRuntimeProfile()` löst die Variante **vor** der
  Firebase-Initialisierung auf (die von ihr abhängt). Ein Fehler im
  Einstellungsspeicher fällt auf den Vorgabewert zurück statt den Start zu
  verhindern.
- `lib/core/di/service_locator.dart`: `resetDependencies()` mit
  `serviceLocator.reset()`, damit beide Graphen in einem Prozess (und in
  Tests) nacheinander aufgebaut werden können.
- `runtime_variant_section.dart`: Auswahl in **beiden**
  Einstellungs-Oberflächen (Cloud: Profil-Tab, Standalone: Allgemein-Tab),
  damit der Rückweg aus jeder Variante erreichbar ist.
- `core/widgets/runtime_variant_switch_hint.dart`: derselbe Wechsel
  **vor** der Anmeldung im Auth-Formular. Ohne ihn käme man nie zur eigenen
  Runtime, wenn man kein Cloud-Konto hat — die Einstellungen liegen hinter
  dem Login. Ersetzt dort einen vorbestehenden Fehler: Der Hinweis
  „Du nutzt novooa Standalone?“ war fest verdrahtet, löste aber nur den
  Wechsel zwischen Registrieren und Login aus; der passende `_prefix`-Text
  war toter Code (und als `unused_element` in der Analyse sichtbar).
- Beide Oberflächen blenden sich aus, wenn es nur eine unterstützte
  Variante gibt — im Web also **immer**, weil dort die Herkunft entscheidet.

**Bewusste Entscheidung:** Kein Wechsel im laufenden Prozess. Die Wahl wird
gespeichert und beim nächsten Start übernommen, angezeigt über einen
Neustart-Hinweis. Firebase-Initialisierung, DI-Graph und Anmeldung hängen
alle an der Variante — ein Neustart ist ehrlicher als ein halb umgebauter
Zustand. `resetDependencies()` existiert trotzdem, weil Tests beide Graphen
brauchen.

Ebenfalls bewusst: **kein erzwungener Auswahldialog beim Erststart.** Der
`dart-define`-Vorgabewert greift weiterhin, damit bestehende Builds, CI und
die Erstlauf-Erfahrung unverändert bleiben.

### Schritt 2 — Die Runtime liefert die App aus und lässt sich von jedem Client einrichten — **umgesetzt**

Neue Umgebungsvariablen:

| Variable | Wirkung | Ohne Angabe |
| --- | --- | --- |
| `LOCAL_RUNTIME_WEB_DIRECTORY` | Verzeichnis des Flutter-Web-Builds, das die Runtime ausliefert | Die Runtime bleibt eine reine API — bestehende Installationen verhalten sich unverändert |
| `LOCAL_RUNTIME_ALLOWED_ORIGINS` | Kommagetrennte Browser-Herkünfte, die CORS-Freigabe erhalten | Keine fremde Herkunft erlaubt |


Ziel: Eine nackt installierte Runtime ist **ohne nativen Client und ohne
SSH** einzurichten — auch headless auf VPS, NAS oder Raspberry Pi.

#### 2a — Kopplungscode statt Netzwerkgrenze

Heute ist `/v1/setup` dadurch geschützt, dass der Setup-Port nur an
`127.0.0.1` des Docker-Hosts veröffentlicht wird. Der Vertrauensanker lautet
also „wer Zugriff auf den Host hat, besitzt die Runtime“ — richtig, aber es
schliesst headless-Installationen von der Einrichtung aus.

Stattdessen erzeugt die Runtime beim ersten Start ein zufälliges
**Setup-Geheimnis** und schreibt es in ihr Log (die Stelle existiert bereits:
`local_runtime.started` in `local-runtime-entrypoint.ts`). `/v1/setup` wird
damit auch auf dem regulären Port erreichbar, verlangt dort aber diesen Code.

Der Vertrauensanker bleibt derselbe — `docker compose logs` setzt
Host-Zugriff voraus —, aber die *Bedienung* löst sich davon: Jeder Client
kann einrichten, solange jemand den Code vorliest. Es ist dasselbe Modell,
das `/v1/license/*` hier schon verwendet: geschützt durch **Besitz eines
Geheimnisses**, nicht durch **Netzwerkposition**.

Entschieden:

- Der Code verfällt nach erfolgreicher Einrichtung (er hat dann keinen Zweck
  mehr und wäre nur noch Angriffsfläche).
- Port `8091` bleibt als loopback-gebundener Rückfallweg bestehen — er
  kostet nichts und rettet den Fall „Code verloren“. Dort ist weiterhin
  **kein** Code nötig, weil die Netzwerkgrenze ihn ersetzt.

#### 2b — Static-Serving

Neuer `LocalRuntimeStaticFileHandler` als letztes Glied der bestehenden
Chain-of-Responsibility (`local-runtime-request-router.ts`), vor dem 404:
liefert das Web-Build aus, mit SPA-Fallback auf `index.html`. Verzeichnis
per Env, damit das Image den Build mitbringen kann. Damit ist die Setup-UI
kein Sonderfall, sondern schlicht der erste Bildschirm der normalen Web-App.

#### 2c — CORS, eng zugeschnitten

Im vorgesehenen Betrieb (Runtime liefert die App aus) wird CORS **nicht
gebraucht** — und native Clients ignorieren es ohnehin, es ist ein reiner
Browser-Mechanismus. Nötig ist es allein für die **lokale Entwicklung**:
`flutter run -d chrome` läuft auf `localhost:59193`, die Runtime auf `:8090`
— verschiedene Ports sind verschiedene Origins.

Deshalb: erlaubte Origins über Env, **Standard leer**. Im Betrieb ist nichts
offen, in der Entwicklung setzt man gezielt eine Origin. Kein pauschales
`*`. Analog eine `Origin`-Prüfung beim WebSocket-Upgrade in
`local-runtime-realtime-server.ts`, die es heute nicht gibt.

#### 2d — Adressen anzeigen statt abfragen

Die Setup-UI zeigt die Adressen, unter denen die Runtime erreichbar ist
(Netzwerk-Interfaces über `node:os`; die Runtime ermittelt sie heute nicht).

Bewusst **kein** Eingabefeld für die eigene Domain: Ein eingetippter Wert
wird bei jedem DHCP-Wechsel still falsch, und niemand merkt es, bis sich
jemand nicht mehr verbinden kann. Eine angezeigte Liste ist immer aktuell
und spart das fehleranfällige Abtippen.

Die Runtime braucht ihre eigene Adresse auch sonst nirgends: Sie baut
keinen einzigen absoluten Link auf sich selbst, hat keine
`publicUrl`-Konfiguration, und Microsoft-OAuth liegt vollständig im
Cloud-Teil (`infrastructure/firebase/`). Same Origin macht die Zuordnung
selbstkonfigurierend.

#### Umsetzungsdetails

- `local-runtime-setup-code.ts`: Der Code lebt **nur im Prozessspeicher** —
  kein Geheimnis at rest, keine Migration, und er verfällt zusätzlich bei
  jedem Neustart.
- `/v1/setup` steht in `unauthenticatedPaths` der Session-Middleware: Man braucht
  das Passwort, um eine Session zu bekommen — Henne und Ei. Dort schützt
  stattdessen der Code.
- Die Reihenfolge bleibt Lizenz → Passwort: Vor der Aktivierung existiert
  der Setup-Handler noch gar nicht (er hängt an der erst dann erzeugten
  Datenbank), und die Lizenz-Middleware blockiert den regulären Port ohnehin.
- Die angezeigten Adressen übernehmen den Port aus dem `Host`-Header der
  Anfrage. Im Container lauscht die Runtime auf 8080, Clients sprechen aber
  den veröffentlichten 8090 an — nur der Browser weiß verlässlich, welcher
  es war.
- Statische Dateien werden erst geprüft, wenn **kein** Handler zuständig
  war. Ein Endpunkt lässt sich dadurch nicht von einer Datei überschatten,
  und `/v1/*` sowie `/healthz` sind zusätzlich ausgenommen.

#### Tests

38 neue Tests: Kopplungscode (Erzeugung, Normalisierung beim Abtippen,
Verfall); Setup mit gültigem, fehlendem, falschem und verbrauchtem Code;
loopback-Weg ohne Code; Static-Auslieferung mit SPA-Fallback,
Content-Types, Pfad-Traversal und Endpunkt-Abschattung; CORS-Freigabe nur
bei konfigurierter Herkunft, Same Origin ohne Header, kein pauschales `*`.

### Schritt 3 — Web × Standalone freischalten — **teilweise vorgezogen**

Mit der Herkunftsregel aus Schritt 1 ist der Client-Teil bereits erledigt:
Der pauschale `kIsWeb`-Guard ist weg, und im Web-Standalone-Fall leitet
`RuntimeProfile` den Workspace-Endpunkt aus `Uri.base.origin` ab. Offen
bleibt:

- Den Startflow im Web prüfen: `RuntimeConnectionGate` fragt heute nach
  einer Adresse — bei Same Origin ist sie bereits bekannt und der Schritt
  sollte entfallen.
- Entscheidung zur Token-Ablage im Browser dokumentieren (siehe Blocker 7).
- Tests: Widget-Test, dass der Standalone-Startflow im Web ohne
  Adresseingabe lädt.

### Verifikation

- `flutter analyze` (Baseline 28 Hinweise) und `flutter test`.
- `flutter build web` muss weiterhin durchlaufen.
- `npm --prefix functions run build` und `npm --prefix functions test`.
- Manuell: Web-Build über die lokale Runtime aufrufen und einen Arbeitsplan
  anlegen, ausführen und in den Aktivitäten wiederfinden.

## Nicht lösbar

Eine über HTTPS ausgelieferte Web-App kann eine Runtime unter einer
**LAN-IP ohne TLS** nicht erreichen. Das ist eine Browser-Sicherheitsgrenze,
keine Implementierungslücke. Wer Web-Clients im LAN will, nutzt entweder das
Same-Origin-Ausliefern aus Schritt 2 oder stellt einen Reverse Proxy mit
Zertifikat davor.

## Offene Fragen

- Wird die Web-App im Standalone-Betrieb aus dem Runtime-Image ausgeliefert
  oder aus einem gemounteten Volume?
- Bleibt Standalone bei einem einzigen Betreiber-Konto, oder braucht es
  mehrere Nutzer, sobald mehrere Browser-Clients zugreifen?
