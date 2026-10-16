# System-E-Mail über SendGrid

> SendGrid versendet ausschließlich novooa-eigene E-Mails (Benachrichtigungen, Einladungen, Marketing); Arbeitspläne und Kundenpostfächer nutzen es nie.

Gehört zu: [Kommunikation](../index/kommunikation.md)

- Absenderdomain `novooa.de` per Domain Authentication verifiziert.
- Key nur als Firebase-Secret `SENDGRID_API_KEY` mit der Berechtigung
  `mail.send`.
- Warum getrennt: Ein kompromittierter Versand-Key kann weder ein Postfach
  lesen noch Provider-Einstellungen erreichen.
- Nutzer:innen konfigurieren SendGrid nicht. Ein künftiger
  `SystemEmailSender` bleibt backend-intern (noch nicht umgesetzt).
- SendGrid-Inbound-Parse ersetzt keinen Connector: Es empfängt nur Mails an
  eine eigene, auf SendGrid zeigende Subdomain und kann kein bestehendes
  Postfach lesen.

## Siehe auch

- [Mail-Connectoren](./mail-connectoren.md)
- [E-Mail-Auslöser über Mail-Connector](./email-ausloeser-mail-connector.md)
