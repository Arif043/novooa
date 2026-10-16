# Baustein „HTTP-Anfrage“

> `httpRequest` sendet eine Anfrage, optional über eine Verbindung, und gibt die Antwort als typisierte Werte weiter.

Gehört zu: [Verbindungen](../index/verbindungen.md)

| Einstellung | Bedeutung |
| --- | --- |
| Verbindung | optional; mit Verbindung ist die Adresse ein **Pfad** unter der Basis-URL |
| Methode | GET, POST, PUT, PATCH, DELETE; Body nur außer GET |
| Pfad / URL | Template; mit Verbindung relativ (oder dieselbe Origin) |
| Query, Header | Name-Wert-Listen, Werte als Templates; Query-Werte URL-kodiert |
| Body | `kein`, `JSON`, `Text`; JSON muss nach dem Einsetzen gültig sein, sonst Abbruch vor dem Senden; bei JSON `Content-Type: application/json` voreingestellt |
| Zeitlimit | 1–120 s, Standard 30 |
| Bei Fehlerstatus abbrechen | Standard an; aus liefert `status`/`ok` zum Verzweigen |

**Ausgaben:** `value` (`json`: geparster JSON-Body, sonst Text, leer `null`)
als `{{antwort}}`/`{{antwort.feld}}`; dazu `status` (`number`), `ok`
(`boolean`, 2xx), `headers` (`json`, kleingeschrieben, ohne `set-cookie`), z. B.
`{{Status}}`, `{{Erfolgreich}}`.

**Grenzen:**

- Antworten höchstens 5 MB und nur Text (UTF-8); keine Binärantworten.
- Weiterleitungen nur innerhalb derselben Origin (höchstens 5; 303 sowie
  301/302 nach Nicht-GET werden GET ohne Body); fremde Hosts kommen als 3xx
  zurück.
- Fehlermeldungen nennen nur den Host, nie die volle Adresse (Query kann Token
  enthalten).
- Kein seitenweises Abrufen, keine Wiederholungen, keine
  Rate-Limit-Behandlung (über „Für jedes Element“ lösbar).
- Der KI-Agent kennt den Baustein nicht.

## Siehe auch

- [Sicherheit der HTTP-Anfrage](./http-anfrage-sicherheit.md)
- [Verbindung](./verbindung.md)
