# URL Context und Seitenlinks

> Der Wissensbasis-Agent fasst öffentliche URLs per Genkit URL Context zusammen; Unterseiten und Navigation ermittelt er mit `extractPageLinks`, ohne zu crawlen.

Gehört zu: [KI-Agent](../index/ki-agent.md)

- URL Context ist kein Crawler: keine Login-Bereiche, Paywalls oder
  mehrseitigen Crawls.
- `extractPageLinks` ruft genau eine öffentliche HTML-Seite ab, folgt höchstens
  drei Weiterleitungen, begrenzt die Antwortgröße und liefert höchstens 100
  deduplizierte HTTP(S)-Links. Den Links folgt es nicht.
- Nackte Domains (`laraevent.de`) werden zu `https://laraevent.de`.
- Webseiteninhalt ist untrusted und kann die Systemanweisungen nicht ändern.
- URLs aus der Frage erkennt `publicUrlsIn` (nackte Domains bekommen
  `https://`, E-Mail-Adressen zählen nicht); sie stehen als
  `<context name="public_urls">` im Prompt.

## Siehe auch

- [Wissensbasis-Agent](./wissensbasis-agent.md)
