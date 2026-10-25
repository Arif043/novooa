# Google Cloud einrichten

> Für Google Drive braucht das Firebase-Projekt die Drive API, einen OAuth-Client vom Typ Webanwendung und drei Werte in den Functions.

Gehört zu: [Google Drive](../index/google-drive.md)

Einmalig in der Google Cloud Console (Projekt `syscat-90bff`):

1. „APIs & Dienste“ → „Bibliothek“ → **Google Drive API** aktivieren.
2. **Google Auth Platform**:
   - Branding: App-Name `novooa`, Support-E-Mail.
   - Zielgruppe: Extern. Im Status „Testen“ dürfen sich nur eingetragene
     Testnutzer:innen anmelden.
   - Datenzugriff: `openid`, `.../auth/userinfo.email`,
     `.../auth/drive.file`.
3. **Clients** → Webanwendung mit der Weiterleitungs-URI
   `https://europe-west3-syscat-90bff.cloudfunctions.net/completeGoogleAccountAuthorization`.

Werte für die Functions:

```bash
firebase functions:secrets:set GOOGLE_OAUTH_CLIENT_SECRET     # aus dem OAuth-Client
firebase functions:secrets:set GOOGLE_ACCOUNT_ENCRYPTION_KEY  # openssl rand -base64 32
```

In `functions/.env.<projekt>`:

```text
GOOGLE_OAUTH_CLIENT_ID=<…>.apps.googleusercontent.com
GOOGLE_OAUTH_REDIRECT_URI=https://europe-west3-syscat-90bff.cloudfunctions.net/completeGoogleAccountAuthorization
```

Die Runtime erreicht das Relay über `LOCAL_RUNTIME_GOOGLE_RELAY_URL`, siehe
[Cloud-Endpunkte der Runtime](./runtime-cloud-endpunkte.md).

Für die Veröffentlichung (Status „In Produktion“) verlangt Google eine
verifizierte Domain auf dem Zustimmungsbildschirm. `cloudfunctions.net` lässt
sich nicht verifizieren; der Callback braucht dann eine eigene Domain.

## Siehe auch

- [Google-Konto verbinden](./google-konto-verbinden.md)
- [Microsoft-Graph-App je Umgebung](./microsoft-graph-entra-app.md)
