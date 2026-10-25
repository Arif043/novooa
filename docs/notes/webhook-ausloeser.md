# Webhook-Auslöser

> Ein Webhook ist ein Auslöser mit eigener Adresse `…/hooks/<Auslöser>/<Token>`, über die ein externes System eine Aufgabe startet.

Gehört zu: [Webhooks](../index/webhooks.md)

Die Runtime muss für das aufrufende System erreichbar sein (z. B. VPS hinter Reverse Proxy mit `https`).

*Zeitplan → Auslöser hinzufügen → Ereignis → Webhook empfangen:*

| Einstellung | Bedeutung |
| --- | --- |
| Signatur prüfen | an: HMAC über den **Rohbody** jeder Anfrage; aus: die Adresse genügt |
| Kopfzeile, Verfahren, Darstellung, Präfix | wo und wie die Signatur kommt, z. B. `X-Hub-Signature-256`, SHA-256, Hex, `sha256=` |
| Geheimnis | gemeinsamer Schlüssel; verschlüsselt gespeichert, nie wieder angezeigt |
| Parameter der Einrichtungsprüfung | Query-Parameter, den die Runtime unverändert zurückgibt (Microsoft Graph: `validationToken`); leer = keine |

- Die Karte des Auslösers zeigt die Adresse mit Kopierknopf und „Neue Adresse
  erzeugen“. Das Token (256 Bit zufällig) vergibt immer die Runtime; die alte
  Adresse ist danach ungültig.
- Die Adresse baut der Client aus der Runtime-Adresse, über die er arbeitet.
  Ein externes System braucht die **öffentliche** Adresse; eine abweichende
  lässt sich noch nicht hinterlegen.
- Geheimnis oder Prüfung ändern: Auslöser löschen und neu anlegen.

## Siehe auch

- [Ablauf eines Webhook-Aufrufs](./webhook-aufruf.md)
- [Webhook-Ereignis im Lauf](./webhook-ereignis.md)
- [Sicherheit und Grenzen der Webhooks](./webhook-sicherheit.md)
