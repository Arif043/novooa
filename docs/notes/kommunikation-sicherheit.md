# Sicherheit der Kommunikation

> Postfach-Zugänge folgen Least Privilege, liegen verschlüsselt nur im Mail-Relay und sind pro Runtime-Lizenz isoliert.

Gehört zu: [Kommunikation](../index/kommunikation.md)

- OAuth-Berechtigungen nach dem Least-Privilege-Prinzip.
- Refresh Tokens verschlüsselt, nie im Flutter-Client.
- Zugangsdaten und temporäre OAuth-States sind nur für die Functions des
  Mail-Relays lesbar.
- Connectoren sind pro Runtime-Lizenz isoliert: kein Lesen oder Senden für
  fremde Runtimes.
- Trennen widerruft oder löscht die gespeicherten Provider-Zugangsdaten.
- Jede Arbeitsplan-E-Mail geht aus einem verbundenen Kundenpostfach heraus,
  nie über SendGrid.

## Siehe auch

- [Mail-Connectoren](./mail-connectoren.md)
- [System-E-Mail über SendGrid](./system-email-sendgrid.md)
