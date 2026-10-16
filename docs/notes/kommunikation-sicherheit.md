# Sicherheit der Kommunikation

> Postfach-Zugänge folgen Least Privilege, liegen verschlüsselt nur in der Cloud und sind pro Team isoliert.

Gehört zu: [Kommunikation](../index/kommunikation.md)

- OAuth-Berechtigungen nach dem Least-Privilege-Prinzip.
- Refresh Tokens verschlüsselt, nie im Flutter-Client.
- Zugangsdaten und temporäre OAuth-States sind nur für Cloud Functions lesbar.
- Connectoren sind pro Team isoliert: kein Lesen oder Senden für fremde Teams.
- Trennen widerruft oder löscht die gespeicherten Provider-Zugangsdaten.
- Jede Arbeitsplan-E-Mail geht aus einem verbundenen Kundenpostfach heraus,
  nie über SendGrid.

## Siehe auch

- [Mail-Connectoren](./mail-connectoren.md)
- [System-E-Mail über SendGrid](./system-email-sendgrid.md)
