# Google-Konto verbinden

> Ein Google-Konto wird im Browser über das Google-Relay in Firebase verbunden; Firebase hält das Refresh-Token, die Runtime bekommt nur kurzlebige Zugriffstokens und ruft Google selbst auf.

Gehört zu: [Google Drive](../index/google-drive.md)

Ablauf:

1. Die App ruft `POST /v1/google-accounts/authorization` auf (nur Admins).
   Die Runtime fragt das Relay (`beginAuthorization`, optional mit
   `loginHint`) und bekommt die Google-Adresse zurück.
2. Im Browser meldet sich die Person an und wählt im **Google-Picker**
   Dateien und Ordner aus (`trigger_onepick`, `allow_folder_selection`,
   `allow_multiple`). PKCE schützt den Code.
3. Google leitet auf `completeGoogleAccountAuthorization` um. Die Funktion
   tauscht den Code und liest die Konto-ID (`sub`) und die E-Mail-Adresse.
   Die gewählten Einträge (`picked_file_ids`) benennt sie per `files.get`.
4. Konto und verschlüsseltes Refresh-Token landen in Firestore. Danach
   erhöht die Funktion `googleAccountsRevision` im
   [Wake-up-Dokument](./runtime-firebase-wakeup.md); die Runtime leert ihren
   Cache und meldet das Realtime-Thema `google-accounts`.

Regeln:

- Ein Konto gehört genau einer Runtime-Lizenz. Nur diese bekommt über
  `accessToken` ein Zugriffstoken; eine fremde Lizenz wird abgelehnt.
- Verbindet jemand dasselbe Google-Konto erneut („Weitere Dateien
  freigeben“, „Neu verbinden“), bleibt die Konto-ID. Neue Freigaben kommen zu
  den alten hinzu.
- `invalid_grant` beim Erneuern setzt das Konto auf
  `reauthorizationRequired`; die App zeigt „Neu verbinden“, Bausteine melden,
  dass das Konto neu verbunden werden muss.
- Dateiinhalte laufen nie über Firebase. Die Runtime hält Zugriffstokens bis
  60 s vor Ablauf im Speicher (`RelayGoogleAccessTokens`); gleichzeitige
  Bausteine teilen sich eine Anfrage.

Ablage:

| Was | Wo |
| --- | --- |
| Konto (E-Mail, Status, Freigaben) | `teams/{team}/googleAccounts/{id}` |
| Refresh-Token (AES-GCM, `GOOGLE_ACCOUNT_ENCRYPTION_KEY`) | `teams/{team}/googleAccountCredentials/{id}` |
| Begonnene Anmeldung (10 Minuten, einmalig) | `googleAccountAuthorizations/{id}` |
| Code | `functions/src/features/google_accounts/` |
| Client | `lib/features/google_accounts/`, unter Einstellungen → Plugins → Google Drive (nur bei aktivem Plugin) |

## Siehe auch

- [Scope `drive.file`](./google-drive-scope.md)
- [Google Cloud einrichten](./google-cloud-einrichtung.md)
- [Mail-Connectoren](./mail-connectoren.md) — derselbe Weg für Outlook
