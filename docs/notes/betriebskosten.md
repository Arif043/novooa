# Betriebskosten

> Firebase ist bei kleiner Nutzung nahezu kostenlos; der einzige mit der Nutzung skalierende Kostenblock sind KI-Tokens.

Gehört zu: [Produkt](../index/produkt.md)

Basispreise (Stand der Kalkulation):

- Firestore Free Tier: 50k Reads, 20k Writes, 20k Deletes pro Tag, 1 GiB;
  danach ca. 0,30 USD je 1 Mio Reads, 0,90 USD je 1 Mio Writes.
- Cloud Functions: 2 Mio Aufrufe/Monat frei, danach ca. 0,40 USD je 1 Mio
  plus Rechenzeit.
- Gemini 2.5 Flash: ca. 0,30 USD je 1 Mio Input-, 2,50 USD je 1 Mio
  Output-Tokens.

| Szenario | Annahme | Kosten |
| --- | --- | --- |
| MVP | 10 Nutzer × 10 Runs/Tag × 2 Prompts (1k in, 500 out) | ca. 10 USD/Monat (6.000 Aufrufe × 0,00155 USD) |
| Mittel | 100 Nutzer × 20 Runs/Tag × 3 Prompts | ca. 300–350 USD/Monat (279 USD Gemini + 10–30 USD Firebase) |

Bei 100 Pro-Nutzern (39 EUR) stehen ca. 3.900 EUR Umsatz gegenüber — rund
90 % Bruttomarge, solange die KI-Nutzung je Nutzer begrenzt bleibt.

**Auto-Save-Debounce:** 500 getippte Zeichen sind meist 1 statt bis zu 500
Writes (100 Nutzer: 1.000–3.000 statt 500.000 Writes/Tag). Preislich nur ca.
13 USD/Monat, aber weniger Quota-Druck, Listener-Updates und Latenz.

Fazit: Tokens sind der einzige relevante variable Block (besonders große
Dateien, RAG, viele Prompt-Bausteine); detaillierte Live-Aktivitäten werden
relevant; alles andere ist im MVP Rundungsfehler. Daraus folgt: Sitzplatzpreis
für Zugang, KI-Credits als Mengenbegrenzung.

Hinweis: Die Kalkulation nimmt Twilio nur als interne Marketing-Kosten an;
SMS- und WhatsApp-Kanäle laufen technisch aber über Twilio
([Kommunikationskanal-Datenmodell](./kommunikationskanal-datenmodell.md)) —
ihre Kosten sind noch nicht eingepreist.

Quellen: [Firebase](https://firebase.google.com/pricing),
[Firestore](https://cloud.google.com/firestore/pricing),
[Cloud Functions](https://cloud.google.com/functions/pricing-1stgen),
[Gemini](https://ai.google.dev/gemini-api/docs/pricing).

## Siehe auch

- [Cloud-Preismodell](./cloud-preismodell.md)
- [Grenzen von Cloud Functions](./cloud-functions-grenzen.md)
