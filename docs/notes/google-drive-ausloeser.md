# Auslöser für Google Drive

> Geplant: Ein Auslöser startet Aufgaben, wenn in einem Drive-Ordner eine Datei landet. Er braucht den vollen Scope `drive` und damit die Google-Verifizierung.

Gehört zu: [Google Drive](../index/google-drive.md)

Status: **geplant**, nicht umgesetzt.

Vorgesehener Weg, ohne Abfragen im Takt:

1. Firebase legt je Konto einen Push-Kanal an (`changes.watch`, Adresse
   eine HTTPS-Funktion, höchstens eine Woche gültig). Ein geplanter Job
   erneuert ihn, wie die
   [Graph-Subscriptions](./graph-token-und-subscriptions.md).
2. Googles Benachrichtigung ist leer. Firebase erhöht nur eine Revision im
   [Wake-up-Dokument](./runtime-firebase-wakeup.md).
3. Die Runtime holt mit ihrem Zugriffstoken `changes.list` ab ihrem
   gespeicherten `pageToken` und startet passende Auslöser. Dateiinhalte und
   -namen laufen so nicht über Firebase.

Voraussetzungen:

- Scope `drive` oder `drive.readonly`, siehe
  [Scope `drive.file`](./google-drive-scope.md).
- Verifizierte Domain für den OAuth-Callback, siehe
  [Google Cloud einrichten](./google-cloud-einrichtung.md).

## Siehe auch

- [Google-Konto verbinden](./google-konto-verbinden.md)
