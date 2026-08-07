# Deployment-Umgebungen

## Zielbild

novooa verwendet getrennte Firebase-Projekte fuer Staging und Produktion. Eine
Hosting-Preview im Produktionsprojekt gilt nicht als Staging, weil sie sonst
weiterhin dieselben Functions, Auth-Nutzer:innen, Firestore-Daten und Push-Tokens
verwendet.

| Umgebung | GitHub-Environment | Firebase-Projekt | Deployment-Ziel |
| --- | --- | --- | --- |
| Staging | `staging` | Noch anzulegen | `develop` und PR-Previews |
| Produktion | `production` | `syscat-90bff` | `main` und Hosting `live` |

Die GitHub-Environments `staging` und `production` sind bereits angelegt.
Der Hosting-Deploy auf `main` verwendet bereits das Environment `production`.

## Secrets

Beide GitHub-Environments erhalten getrennte Secrets mit denselben Namen:

```text
FCM_WEB_VAPID_KEY
FIREBASE_SERVICE_ACCOUNT
```

Der VAPID-Key ist ein oeffentlicher Web-Push-Schluessel, wird jedoch als Secret
behandelt, damit die Build-Konfiguration einheitlich bleibt. Der Service-Account
muss jeweils zum Firebase-Projekt der Umgebung gehoeren.

## Microsoft Graph

Microsoft Graph wird pro Firebase-Umgebung als eigene Entra-App registriert.
Als unterstützte Kontotypen wird `Accounts in any organizational directory and
personal Microsoft accounts` gewählt. So können Microsoft-365-, Outlook.com-
und Hotmail-Postfächer verbunden werden. Publisher Verification und eine
Unternehmensverifizierung sind dafür technisch nicht erforderlich; einzelne
Organisationen können nicht verifizierte Mehrmandanten-Apps jedoch sperren.

Die App erhält ausschliesslich delegierte Berechtigungen:

```text
Mail.Read
Mail.Send
User.Read
offline_access
```

Die folgenden Function-Parameter werden pro Umgebung gesetzt:

```text
MICROSOFT_GRAPH_CLIENT_ID
MICROSOFT_GRAPH_REDIRECT_URI
MICROSOFT_GRAPH_WEBHOOK_URL
```

`MICROSOFT_GRAPH_REDIRECT_URI` verweist auf die öffentlich erreichbare Function
`completeMicrosoftMailConnector`; `MICROSOFT_GRAPH_WEBHOOK_URL` auf
`microsoftGraphWebhook`. Beide URLs müssen HTTPS verwenden und exakt mit den
Werten in der Entra-App übereinstimmen.

Als Firebase-Secrets werden zusätzlich gesetzt:

```text
MICROSOFT_GRAPH_CLIENT_SECRET
MAIL_CONNECTOR_ENCRYPTION_KEY
```

`MAIL_CONNECTOR_ENCRYPTION_KEY` ist ein eigener, Base64-kodierter 32-Byte-Key,
zum Beispiel aus `openssl rand -base64 32`. Nach einem Key-Wechsel können
bestehende Refresh-Tokens nicht mehr entschlüsselt werden und die Postfächer
müssen erneut verbunden werden. Vor dem ersten OAuth-Connect muss die
Webhook-Function bereits deployt sein, weil Microsoft Graph die URL beim
Anlegen einer Subscription validiert.

## Pipeline

Jeder Hosting-Build muss die passende Firebase-Konfiguration und den VAPID-Key
als Dart-Define erhalten:

```yaml
- run: flutter build web --dart-define=FCM_WEB_VAPID_KEY=${{ secrets.FCM_WEB_VAPID_KEY }}
```

Die Jobs deklarieren ihre Umgebung explizit:

```yaml
environment: staging
```

oder:

```yaml
environment: production
```

Der aktuelle Produktionsworkflow deployt nach `syscat-90bff` und verwendet das
GitHub-Environment `production`. Der PR-Workflow bleibt bis zur Einrichtung
des Staging-Projekts im Produktionsprojekt. Vor dem ersten Staging-Deploy sind
Firebase-Projekt, Flutter-Konfiguration, Projekt-Aliase und die Workflows auf
die obige Trennung umzustellen.

## Firebase-Projekt-Aliase

Nach dem Anlegen des Staging-Projekts werden die Aliase in `.firebaserc`
geführt:

```json
{
  "projects": {
    "production": "syscat-90bff",
    "staging": "<staging-project-id>"
  }
}
```
