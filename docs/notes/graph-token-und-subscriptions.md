# Token- und Subscription-Pflege (Microsoft Graph)

> `MailConnectorTokenService` hält Zugriffstokens frisch, rotiert Refresh Tokens sicher und erneuert Graph-Subscriptions, bevor sie ablaufen.

Gehört zu: [Kommunikation](../index/kommunikation.md)

Ort: `communication/domain/services/`.

- **Zugriffstokens** pro Connector bis kurz vor Ablauf gemerkt
  (`AccessTokenCache`, je Funktionsinstanz). Gleichzeitige Aufrufe teilen sich
  einen Refresh; bei 401 von Graph einmal mit frischem Token wiederholen.
- **Refresh Token:** Microsoft rotiert bei jedem Refresh; das neue wird
  verschlüsselt gespeichert. Lehnt Microsoft eines ab, lädt der Dienst das
  gespeicherte neu — hat eine andere Instanz rotiert, einmal mit dem neuen
  wiederholen.
- **Ungültige Anmeldung** (`invalid_grant`, `interaction_required`,
  `consent_required`, `login_required`; z. B. Passwortwechsel, widerrufene
  Einwilligung) → Status `reauthorizationRequired`. Die App zeigt „Erneute
  Anmeldung erforderlich“ mit „Postfach neu verbinden“; Senden meldet das.
  Vorübergehende Fehler (Netz, 5xx) ändern den Status nicht; die
  Warteschlange wiederholt.
- **Subscriptions** (2 Tage) verlängert der Scheduler alle 6 Stunden, wenn
  sie binnen 12 Stunden ablaufen. Abgelaufen, fehlend oder 404 → neu anlegen.
- **Lifecycle-Benachrichtigungen:** `reauthorizationRequired` verlängert,
  `subscriptionRemoved` legt neu an, `missed` wird ignoriert — verpasste Mails
  werden nicht nachgeholt.
- **Neu verbinden** desselben Postfachs behält die Connector-ID (Kanäle und
  Auslöser bleiben gültig), ersetzt Zugangsdaten und Subscription, Status
  wieder `active`.

## Siehe auch

- [Mail-Connectoren](./mail-connectoren.md)
- [Einstellungs-Tab „Kommunikation“](./kommunikation-einstellungen.md)
