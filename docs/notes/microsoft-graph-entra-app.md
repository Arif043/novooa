# Microsoft-Graph-App je Umgebung

> Jede Firebase-Umgebung hat eine eigene Entra-App für Microsoft Graph, mehrmandantenfähig und nur mit delegierten Mail-Berechtigungen.

Gehört zu: [Betrieb und Deployment](../index/betrieb-und-deployment.md)

- Kontotypen: *Accounts in any organizational directory and personal Microsoft
  accounts* — so gehen Microsoft 365, Outlook.com und Hotmail. Publisher- oder
  Unternehmensverifizierung ist technisch nicht nötig; einzelne Organisationen
  können nicht verifizierte Mehrmandanten-Apps aber sperren.
- Delegierte Berechtigungen: `Mail.Read`, `Mail.Send`, `User.Read`,
  `offline_access`.
- Function-Parameter: `MICROSOFT_GRAPH_CLIENT_ID`,
  `MICROSOFT_GRAPH_REDIRECT_URI` (→ `completeMicrosoftMailConnector`),
  `MICROSOFT_GRAPH_WEBHOOK_URL` (→ `microsoftGraphWebhook`); beide URLs HTTPS
  und exakt wie in der Entra-App.
- Firebase-Secrets: `MICROSOFT_GRAPH_CLIENT_SECRET`,
  `MAIL_CONNECTOR_ENCRYPTION_KEY` (Base64, 32 Byte, z. B.
  `openssl rand -base64 32`). Nach einem Wechsel dieses Keys sind
  gespeicherte Refresh Tokens unlesbar; Postfächer müssen neu verbunden werden.
- Vor dem ersten OAuth-Connect muss die Webhook-Function deployt sein, weil
  Graph die URL beim Anlegen einer Subscription validiert.

## Siehe auch

- [Mail-Connectoren](./mail-connectoren.md)
- [Token- und Subscription-Pflege (Microsoft Graph)](./graph-token-und-subscriptions.md)
