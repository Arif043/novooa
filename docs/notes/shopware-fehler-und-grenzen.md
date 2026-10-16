# Shopware-Fehler und Grenzen

> Shopware-Fehler erscheinen als verständliche Meldung am Baustein; Eingaben werden vor dem Senden geprüft.

Gehört zu: [Integrationen](../index/integrationen.md)

- Meldungen für abgelehnte Anmeldung (401), fehlendes Recht der Integration
  mit Namen des Rechts (403), unbekannte Adresse (404), Begrenzung (429) und
  Fehler des Shops (5xx).
- Vorab geprüft: unbekannter Status, ungültiges Datum, Limit außerhalb 1–500.

**Nicht umgesetzt:** signierte App-Aufrufe (App-Geheimnis), Auslöser per
Abfrage im Takt (ohne App und öffentliche Adresse), Dokumente wie Rechnung
und Lieferschein (braucht Binärantworten im HTTP-Client), Sprachwahl, Anlegen
von Datensätzen, Schreiben über die Experten-Abfrage.

## Siehe auch

- [Shopware-Plugin](./shopware-plugin.md)
- [Verhalten der Shopware-Auslöser](./shopware-ausloeser-verhalten.md)
