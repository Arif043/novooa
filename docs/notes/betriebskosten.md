# Betriebskosten

> novooa trägt nur die Kosten der Firebase-Hintergrunddienste; Rechenleistung und die meisten KI-Tokens zahlt die Kundschaft über ihre Runtime und eigene Anbieterschlüssel.

Gehört zu: [Produkt](../index/produkt.md)

Was bei novooa anfällt:

- **Cloud Functions und Firestore** für Lizenz-Gateway, Wake-ups und die
  Relays (Push, Mail, Aufgabenstudio-Agent, Skills). Das Volumen hängt an der
  Zahl der Runtimes, nicht an der Zahl der Läufe; im Free Tier (2 Mio
  Aufrufe/Monat, 50k Reads und 20k Writes pro Tag) ist das lange kostenlos.
- **Aufgabenstudio-Agent:** Er läuft über `localRuntimeTaskBuilderRelay` mit
  dem Gemini-Schlüssel des Betreibers
  ([Wo die KI-Agenten laufen](./ki-agenten-betriebsorte.md)). Gemini 2.5
  Flash kostet ca. 0,30 USD je 1 Mio Input- und 2,50 USD je 1 Mio
  Output-Tokens; das ist der einzige mit der Nutzung skalierende Block.
- **Microsoft Graph und FCM** sind kostenlos; ihre Last trägt das Relay.

Was die Kundschaft trägt: Hardware der Runtime, Sprachmodelle über eigene
Schlüssel oder Ollama, ML-Inferenz im eigenen ML-Dienst.

Quellen: [Firebase](https://firebase.google.com/pricing),
[Gemini](https://ai.google.dev/gemini-api/docs/pricing).

## Siehe auch

- [Lokales Lizenzmodell](./lokales-lizenzmodell.md)
- [Cloud-Endpunkte der Runtime](./runtime-cloud-endpunkte.md)
