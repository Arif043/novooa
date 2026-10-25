# Authentifizierung

Ein Dashboard meldet sich genauso an wie das offizielle Frontend. Der gesamte
Ablauf steckt in `novooa_runtime_client`; das Dashboard baut nur die
Oberfläche dafür.

## Inhalt

- [Paket einbinden](#paket-einbinden)
- [Ablauf und Zustände](#ablauf-und-zustände)
- [Adresse der Runtime](#adresse-der-runtime)
- [Sitzung, Token und Sitzungsende](#sitzung-token-und-sitzungsende)
- [Rollen](#rollen)
- [Fehler anzeigen](#fehler-anzeigen)
- [Endpunkte](#endpunkte)

## Paket einbinden

```yaml
dependencies:
  novooa_runtime_client:
    git:
      url: https://github.com/Arif043/syscat2.git   # privat, Lesezugriff nötig
      path: packages/novooa_runtime_client
      ref: novooa-runtime-client-v0.2.0
```

Ein Import genügt: `import 'package:novooa_runtime_client/novooa_runtime_client.dart';`.
In der CI braucht `flutter pub get` Zugriff auf das Repo (Deploy-Key oder
Token); das Paket ist nicht auf pub.dev.

## Ablauf und Zustände

`RuntimeConnectionCubit` führt durch alle Schritte. Das Dashboard reagiert
auf jeden Zustand (`sealed`, exhaustiver `switch`):

| Zustand | Bedeutung | Dashboard |
| --- | --- | --- |
| `RuntimeConnectionLoading` | Start | Ladeanzeige |
| `RuntimeConnectionConnecting(address)` | Verbindung wird geprüft | Ladeanzeige mit Adresse |
| `RuntimeConnectionNeedsAddress(address, failure)` | nativ: Adresse fehlt oder falsch | Adressfeld |
| `RuntimeConnectionUnreachable(endpoint, failure)` | Web: Runtime nicht erreichbar | Fehler + „Erneut versuchen“ |
| `RuntimeConnectionNeedsPassword(endpoint, mode, failure)` | Anmeldung nötig | `password`: Login, `invitation`: Einladungscode, `recovery`: Hinweis aufs offizielle Frontend |
| `RuntimeConnectionNeedsLicense` | Runtime ohne Lizenz | Hinweis aufs offizielle Frontend |
| `RuntimeConnectionNeedsPasswordSetup` | Runtime nicht eingerichtet | Hinweis aufs offizielle Frontend |
| `RuntimeConnectionReady(endpoint)` | angemeldet | Dashboard zeigen |

Aufbau (wie in `assets/starter/lib/connection/connection_gate.dart`):

```dart
final credentials = createRuntimeCredentialStore();
final sessionEvents = RuntimeSessionEvents();
final connection = RuntimeConnectionCubit(
  RuntimeEndpointPreferences(SharedPreferencesAsync()),
  credentials,
  // Name des Dashboards: erscheint in der Geräteliste des offiziellen Frontends.
  HttpRuntimeLoginClient(device: RuntimeDevice.current(app: DashboardConfig.title)),
  const HttpRuntimeAvailability(),
  onboarding: const HttpRuntimeOnboardingClient(),
  onSignedOut: restartAfterSignOut, // Abhängigkeiten verwerfen, neu verbinden
);
final profile = RuntimeProfile.fromEnvironment();
await connection.initialize(RuntimeEndpoint.fromUri(profile.workspaceApiUri));
```

Aktionen des Cubits für das Dashboard:

```dart
connection.connect('192.168.1.42');                       // Adresse
connection.login(endpoint, loginName: name, password: pw);
connection.showSignIn(endpoint, RuntimeSignInMode.invitation);
connection.redeemInvitation(endpoint, code: code, password: pw);
connection.signOut();                                      // Token + Adresse vergessen
connection.handleSessionEnded();                           // nur Token vergessen
```

`activateLicense`, `setUpAdmin` und `recoverAccess` gibt es auch; ein
Dashboard ruft sie **nicht** auf.

## Adresse der Runtime

`RuntimeEndpoint.fromAddress` wählt das Schema an der Adresse:

| Eingabe | Ergebnis |
| --- | --- |
| `192.168.1.42` | `http://192.168.1.42:8090` |
| `novooa.example.de` | `https://novooa.example.de:443` |
| `http://novooa.fritz.box` | ausdrückliches Schema gilt |
| `192.168.1.42:9000` | eigener Port |

Eine Domain fällt nie still auf `http` zurück. Ein ungültiges Zertifikat
meldet der Cubit als `certificateInvalid`, nicht als „nicht erreichbar“.

- **Desktop/Mobil:** erster Versuch `http://127.0.0.1:8090`, danach die
  gespeicherte Adresse (`RuntimeEndpointPreferences`).
- **Web:** Es gibt kein Adressfeld. Die Adresse kommt aus
  `--dart-define=WORKSPACE_API_URL=…`, sonst aus der eigenen Herkunft. Ein
  Dashboard läuft fast immer auf einer anderen Herkunft als die Runtime, also
  **immer** `WORKSPACE_API_URL` setzen (siehe [Plattformen](plattformen.md)).

## Sitzung, Token und Sitzungsende

- Login liefert ein Session-Token; jede Anfrage sendet es als
  `Authorization: Bearer <token>`. Es gilt 7 Tage ab der letzten Nutzung.
- Gespeichert wird es mit `createRuntimeCredentialStore()`: nativ im
  Schlüsselbund des Systems (`flutter_secure_storage`), im Web über `http`
  nur für den offenen Tab (`sessionStorage`).
- Antwortet die Runtime mit `401 {code: "session_required"}`, meldet
  `SessionAwareWorkspaceApiClient` das über `RuntimeSessionEvents`. Das
  Dashboard schließt dann den Echtzeit-Kanal und ruft
  `handleSessionEnded()`; die Adresse bleibt, nur die Anmeldung wird
  wiederholt. Andere `401` (z. B. `license_rejected`) sind kein Sitzungsende.
- Nach erneuter Anmeldung kann eine **andere Person** angemeldet sein: alle
  Abhängigkeiten (Repositories, Cubits) neu aufbauen, nichts aus der alten
  Sitzung weiterverwenden. Die Vorlage tut das mit `DashboardDependencies`.

API-Client mit Token und Sitzungsende:

```dart
Future<String?> authHeader() async {
  final token = await credentials.sessionToken(endpoint.address);
  return token == null ? null : 'Bearer $token';
}

final api = SessionAwareWorkspaceApiClient(
  HttpWorkspaceApiClient(baseUri: endpoint.apiUri, authHeaderProvider: authHeader),
  sessionEvents,
);
```

## Rollen

`GET /v1/auth/me` → `{uid, loginName, displayName, role, hasPassword, createdAt}`,
`role` ist `admin` oder `member`.

| Bereich | Mitglied | Admin |
| --- | --- | --- |
| Aufgaben lesen und starten, Läufe, Freigaben, Auslöser, Dateien | ja | ja |
| Verbindungen, Sprachmodelle, Skills | nur lesen | ja |
| Benutzer, Import/Export, Protokoll, Lizenz | nein (`403 admin_required`) | ja |

Ein Dashboard braucht nur Mitgliedsrechte. Konten legt ein Admin im
offiziellen Frontend an; neue Personen melden sich im Dashboard mit ihrem
Einladungscode an.

## Fehler anzeigen

Fehler kommen als `RuntimeAccessFailure(kind, statusCode, detail)`, nie als
fertiger Text. Das Dashboard formuliert sie selbst (Vorlage:
`connection/access_failure_text.dart`).

| `RuntimeAccessFailureKind` | Ursache |
| --- | --- |
| `invalidAddress`, `savedAddressUnreadable` | Eingabe bzw. gespeicherte Adresse unbrauchbar |
| `unreachable`, `certificateInvalid` | Netzwerk bzw. Zertifikat |
| `invalidCredentials` | `401` beim Login |
| `invalidInvitation`, `invalidPassword` | Einladungscode bzw. Passwortregel (12–1000 Zeichen) |
| `notLicensed` | `423` |
| `tooManyAttempts` | `429`, eine Minute warten |
| `sessionEnded`, `signOutFailed` | Sitzung |
| `failedWithStatus` | anderer HTTP-Status (`statusCode`) |
| `rejectedByRuntime` | Runtime erklärt den Grund selbst (`detail`) |
| `unexpected` | Fehler im Client nach der Prüfung (`detail`) |
| `licenseTokenMismatch`, `adminNotFound`, `activation*`, `setup*`, `noToken` | Einrichtung und Notzugang, im Dashboard nicht erreichbar |

## Endpunkte

Ohne Sitzung: `GET /healthz`, `POST /v1/auth/login {loginName, password, device?}`,
`POST /v1/auth/invitations/redeem {code, password, device?}` (beide → `{token}`;
`device` = `{app, os, browser}`, setzt `HttpRuntimeLoginClient`).
Mit Sitzung: `GET /v1/auth/me`, `POST /v1/auth/logout` (`204`),
`POST /v1/realtime/ticket`. Alles Weitere: [Runtime-API](runtime-api.md).
