# Kosten- und Abo-Preisabschaetzung

## Erste Kostenabschaetzung

Grob: Syscat ist bei kleiner Nutzung fast kostenlos auf Firebase-Seite; die
echten Kostentreiber werden KI-Tokens und spaeter Twilio-Nachrichten.
Firestore-Writes durch Auto-Save sind preislich nicht riesig, aber ohne
Debounce unnoetig ineffizient und koennen schnell Free-Quota/Realtimereads
belasten.

### Basispreise

- Firestore Free Tier: 50k Reads/Tag, 20k Writes/Tag, 20k Deletes/Tag, 1 GiB
  Storage. Danach grob 0,30 USD pro 1 Mio Reads und 0,90 USD pro 1 Mio Writes.
- Cloud Functions: 2 Mio Invocations/Monat frei, danach ca. 0,40 USD pro
  1 Mio Invocations plus Compute-Zeit.
- Gemini 2.5 Flash: ca. 0,30 USD pro 1 Mio Input Tokens und 2,50 USD pro
  1 Mio Output Tokens.
- Twilio SMS USA: ca. 0,0083 USD inbound/outbound pro Segment plus Carrier Fees;
  Nummer ca. 1,15 USD/Monat.
- Twilio WhatsApp: Twilio Fee ca. 0,005 USD pro Message plus Meta-Template-
  Gebuehren.

### Beispielrechnung MVP / kleine Nutzung

Annahme:

- 10 aktive Nutzer
- 20 Aufgaben pro Nutzer
- 10 Task-Runs pro Nutzer/Tag
- pro Run 2 Prompt-Nodes
- je Prompt ca. 1.000 Input Tokens und 500 Output Tokens
- wenige Dateien, wenig Twilio

Kosten:

- Firestore: wahrscheinlich 0 USD, innerhalb Free Tier.
- Functions: wahrscheinlich 0 USD, innerhalb Free Tier.
- Storage: wahrscheinlich 0 USD, solange unter Free Tier.
- Gemini: 10 Nutzer x 10 Runs/Tag x 30 Tage x 2 Prompts = 6.000 Prompt-Aufrufe.
  Pro Prompt: 1k Input = 0,0003 USD, 500 Output = 0,00125 USD, zusammen
  0,00155 USD. Ergebnis: ca. 9,30 USD/Monat.
- Twilio: ohne echte Nachrichten fast 0 USD plus Nummer, also ca. 1-2 USD/Monat.

Ergebnis: MVP klein grob 10-20 USD/Monat.

### Mittlere Nutzung

Annahme:

- 100 aktive Nutzer
- 20 Runs pro Nutzer/Tag
- 3 Prompt-Nodes pro Run
- gleiche Token-Groesse

Gemini:

100 x 20 x 30 x 3 = 180.000 Prompt-Aufrufe.
180.000 x 0,00155 USD = ca. 279 USD/Monat.

Firebase bleibt wahrscheinlich noch relativ klein:

- Firestore/Functions eher unter 10-30 USD, ausser bei vielen Realtime-Listenern,
  Logs oder Activity-Dokumenten.
- Twilio haengt komplett vom Volumen ab. 10.000 SMS inbound/outbound in den USA
  waeren allein grob 83 USD plus Carrier Fees.

Ergebnis: Mittlere Nutzung grob 300-500 USD/Monat, stark abhaengig von KI- und
Messaging-Volumen.

### Auto-Save-Debounce Effekt

Vorher: 500 Zeichen tippen = bis zu 500 Writes.
Jetzt: 500 Zeichen tippen = meist 1 Write, wenn der Nutzer durchgehend tippt.

Beispiel:

- 100 Nutzer
- 10 Textaenderungen/Tag
- 500 Zeichen je Aenderung

Ohne Debounce: 500.000 Writes/Tag.
Mit Debounce: vielleicht 1.000-3.000 Writes/Tag.

Preislich waeren 500k Writes/Tag nach Free Tier nur ca. 13 USD/Monat, aber der
wichtigere Punkt ist: weniger Quota-Druck, weniger Listener-Updates, weniger
Latenz und weniger Risiko bei Skalierung.

### Fazit

Firestore-Autosave ist nicht der groesste Kostenblock, aber der Debounce ist
trotzdem richtig. Die Hauptkosten werden spaeter sein:

1. Gemini Tokens, besonders bei grossen Dateien, RAG und mehreren Prompt-Nodes.
2. Twilio, sobald echte SMS/WhatsApp-Kommunikation skaliert.
3. Activity Logs / Firestore Listener, wenn sehr detailliert geloggt und live
   angezeigt wird.

Quellen:

- Firebase Pricing: https://firebase.google.com/pricing
- Firestore Pricing: https://cloud.google.com/firestore/pricing
- Cloud Functions Pricing: https://cloud.google.com/functions/pricing-1stgen
- Gemini Pricing: https://ai.google.dev/gemini-api/docs/pricing
- Twilio SMS: https://www.twilio.com/en-us/sms/pricing/us
- Twilio WhatsApp: https://www.twilio.com/en-us/whatsapp/pricing

## Moegliche Abo-Preise

Syscat sollte nicht rein per Seat bepreist werden, sondern als Hybrid:

**Abo + inkludierte Ausfuehrungen/KI-Credits + harte Limits fuer Twilio/Storage.**

Grund: Firebase ist guenstig, aber Gemini- und Twilio-Kosten skalieren direkt
mit Nutzung. Ein Nutzer mit wenigen Tasks kostet fast nichts; ein Nutzer mit
vielen Prompt-Nodes, Dateien und WhatsApp-Nachrichten kann schnell teuer werden.

### Referenzmarkt

- Zapier: Free, Professional ab ca. 19,99 USD/Monat, Team ab ca. 69 USD/Monat.
- Make: Free + creditbasierte Core/Pro/Teams-Plaene.
- Zapier Agents: Pro ca. 33,33 USD/Monat jaehrlich.
- Reclaim: Free + teamorientierte Plaene.

### Vorschlag fuer Syscat MVP

| Plan | Preis | Zielgruppe | Enthalten |
| --- | ---: | --- | --- |
| Free | 0 EUR | Testen | 3 Aufgaben, 50 Runs/Monat, begrenzte KI, keine externen Trigger |
| Starter | 19 EUR/Monat | Einzelperson/Freelancer | 20 Aufgaben, 1.000 Runs/Monat, einfache Zeittrigger, kleine Wissensbasis |
| Pro | 39 EUR/Monat | Power User | 100 Aufgaben, 5.000 Runs/Monat, Datei-/Wissensbasis, HITL, Webhooks/Kommunikation |
| Team | 79 EUR/Monat inkl. 3 Nutzer | kleine Teams | Team-Aufgaben, spaeter Rollen, 15.000 Runs/Monat, Freigaben, gemeinsame Channels |
| Business | ab 199 EUR/Monat | Unternehmen | hoehere Limits, Audit Logs, Support, eigene Limits, spaeter SSO |

Zusaetzliche Nutzer im Team: 10-15 EUR/Nutzer/Monat.

### KI nicht unbegrenzt inkludieren

Intern sollte mit AI-Credits gearbeitet werden:

- 1 einfacher Prompt-Aufruf = z.B. 1 Credit
- grosse Dateien/RAG = mehrere Credits
- sehr lange Outputs = mehrere Credits
- Script/File Nodes ohne KI = sehr guenstig oder frei innerhalb Runs

Moegliche Credit-Limits:

| Plan | KI-Credits |
| --- | ---: |
| Free | 100/Monat |
| Starter | 2.000/Monat |
| Pro | 10.000/Monat |
| Team | 30.000/Monat |

Overage: z.B. 10 EUR pro weitere 5.000 Credits.

### Twilio / WhatsApp / SMS

Twilio sollte nicht pauschal inkludiert werden, hoechstens sehr wenig zum
Testen.

Empfehlung:

- Eingehende Webhooks/Trigger sind im Plan enthalten.
- SMS/WhatsApp-Versand wird als Add-on oder Passthrough berechnet.
- Beispiel: Twilio-Kosten + 20-30 Prozent Plattformaufschlag.
- Oder: Nutzer verbindet spaeter eigenes Twilio-Konto.

Sonst kann ein einzelner Kunde mit vielen Nachrichten die Marge zerstoeren.

### Bevorzugte erste Preisliste

- Free: 0 EUR
- Starter: 19 EUR/Monat
- Pro: 39 EUR/Monat
- Team: 79 EUR/Monat inkl. 3 Nutzer
- Business: 199 EUR/Monat

Jaehrlich: 2 Monate Rabatt, also ca. 190 EUR, 390 EUR, 790 EUR, 1.990 EUR.

### Warum nicht niedriger?

Syscat ist kein simples Notiztool. Es kombiniert Automation, KI, Dateien,
Trigger, Team-Freigaben und spaeter Kommunikation. Unter 19 EUR/Monat wird es
schwer, KI-Nutzung, Support und Produktkomplexitaet sinnvoll abzubilden.
