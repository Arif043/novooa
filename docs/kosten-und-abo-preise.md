# Kosten- und Preismodell

## 1. Kostenstruktur

### Was novooa wirklich kostet

Auf Firebase-Seite ist novooa bei kleiner Nutzung nahezu kostenlos. Der einzige
Kostentreiber, der direkt mit der Kundennutzung skaliert, sind **KI-Tokens**.
Firestore-Writes durch Auto-Save sind preislich nicht riesig, aber ohne Debounce
unnoetig ineffizient und belasten Free-Quota sowie Realtime-Reads.

Twilio ist **kein** Produktkostenfaktor. Twilio wird ausschliesslich intern fuer
eigene Marketing-Kommunikation genutzt; Kundinnen und Kunden haben damit keine
Beruehrung. Twilio gehoert damit in die Marketing-Kostenstelle, nicht in die
Preiskalkulation der Plaene.

### Basispreise

- Firestore Free Tier: 50k Reads/Tag, 20k Writes/Tag, 20k Deletes/Tag, 1 GiB
  Storage. Danach grob 0,30 USD pro 1 Mio Reads und 0,90 USD pro 1 Mio Writes.
- Cloud Functions: 2 Mio Invocations/Monat frei, danach ca. 0,40 USD pro
  1 Mio Invocations plus Compute-Zeit.
- Gemini 2.5 Flash: ca. 0,30 USD pro 1 Mio Input Tokens und 2,50 USD pro
  1 Mio Output Tokens.

### Beispielrechnung MVP / kleine Nutzung

Annahme:

- 10 aktive Nutzer
- 20 Aufgaben pro Nutzer
- 10 Task-Runs pro Nutzer/Tag
- pro Run 2 Prompt-Nodes
- je Prompt ca. 1.000 Input Tokens und 500 Output Tokens

Kosten:

- Firestore, Functions, Storage: wahrscheinlich 0 USD, innerhalb Free Tier.
- Gemini: 10 Nutzer x 10 Runs/Tag x 30 Tage x 2 Prompts = 6.000 Prompt-Aufrufe.
  Pro Prompt: 1k Input = 0,0003 USD, 500 Output = 0,00125 USD, zusammen
  0,00155 USD. Ergebnis: ca. 9,30 USD/Monat.

Ergebnis: MVP klein grob 10 USD/Monat.

### Mittlere Nutzung

Annahme:

- 100 aktive Nutzer
- 20 Runs pro Nutzer/Tag
- 3 Prompt-Nodes pro Run
- gleiche Token-Groesse

Gemini: 100 x 20 x 30 x 3 = 180.000 Prompt-Aufrufe.
180.000 x 0,00155 USD = ca. 279 USD/Monat.

Firestore/Functions bleiben eher unter 10-30 USD, ausser bei vielen
Realtime-Listenern, Logs oder Activity-Dokumenten.

Ergebnis: Mittlere Nutzung grob 300-350 USD/Monat, fast vollstaendig
KI-getrieben. Bei 100 Nutzern auf Pro-Niveau (39 EUR) steht dem ein Umsatz von
ca. 3.900 EUR/Monat gegenueber. Die Bruttomarge liegt damit bei rund 90 Prozent,
solange die KI-Nutzung pro Nutzer begrenzt bleibt.

### Auto-Save-Debounce Effekt

Vorher: 500 Zeichen tippen = bis zu 500 Writes.
Jetzt: 500 Zeichen tippen = meist 1 Write, wenn der Nutzer durchgehend tippt.

Beispiel: 100 Nutzer, 10 Textaenderungen/Tag, 500 Zeichen je Aenderung.
Ohne Debounce 500.000 Writes/Tag, mit Debounce 1.000-3.000 Writes/Tag.

Preislich waeren 500k Writes/Tag nach Free Tier nur ca. 13 USD/Monat, aber der
wichtigere Punkt ist: weniger Quota-Druck, weniger Listener-Updates, weniger
Latenz und weniger Risiko bei Skalierung.

### Kostenfazit

1. Gemini Tokens sind der einzige relevante variable Kostenblock, besonders bei
   grossen Dateien, RAG und mehreren Prompt-Nodes.
2. Activity Logs und Firestore Listener werden relevant, wenn sehr detailliert
   geloggt und live angezeigt wird.
3. Alles andere ist im MVP Rundungsfehler.

Daraus folgt direkt das Preismodell: **Sitzplatzpreis fuer Zugang und Features,
KI-Credits als Mengenbegrenzung.**

Quellen:

- Firebase Pricing: https://firebase.google.com/pricing
- Firestore Pricing: https://cloud.google.com/firestore/pricing
- Cloud Functions Pricing: https://cloud.google.com/functions/pricing-1stgen
- Gemini Pricing: https://ai.google.dev/gemini-api/docs/pricing

## 2. Preismodell Cloud (Abo)

novooa wird nicht rein per Seat bepreist, sondern hybrid:

**Abo pro Nutzer + inkludierte KI-Credits + Overage.**

Grund: Firebase ist guenstig, aber Gemini-Kosten skalieren direkt mit Nutzung.
Ein Nutzer mit wenigen Tasks kostet fast nichts; ein Nutzer mit vielen
Prompt-Nodes, grossen Dateien und RAG kann teuer werden.

### Referenzmarkt

- Zapier: Free, Professional ab ca. 19,99 USD/Monat, Team ab ca. 69 USD/Monat.
- Make: Free plus creditbasierte Core/Pro/Teams-Plaene.
- Zapier Agents: Pro ca. 33,33 USD/Monat jaehrlich.
- n8n Cloud: instanzbasiert, ca. 20-50 EUR/Monat.

### Preisliste

| Plan | Preis/Nutzer/Monat | jaehrlich | KI-Credits/Nutzer | Enthalten |
| --- | ---: | ---: | ---: | --- |
| Free | 0 EUR | – | 100 | 3 Aufgaben, keine externen Trigger |
| Starter | 19 EUR | 15 EUR | 2.000 | 20 Aufgaben, Zeittrigger, kleine Wissensbasis |
| Pro | 39 EUR | 32 EUR | 10.000 | Dateien/RAG, HITL, Webhooks, Team-Freigaben |
| Business | 79 EUR (ab 5 Nutzern) | 65 EUR | 25.000 | Audit Logs, SSO, Support-SLA, eigene Limits |

Jaehrliche Zahlung entspricht zwei Freimonaten.

Bewusste Abweichung vom frueheren Entwurf: kein Flat-Team-Plan mit Zusatznutzern
zum halben Preis. Ein reines Per-Seat-Modell ist konsistent, waechst mit dem
Kunden und vermeidet die Situation, dass der vierte Nutzer weniger kostet als
der erste.

### KI-Credits

Intern wird mit Credits gearbeitet:

- 1 einfacher Prompt-Aufruf = 1 Credit
- grosse Dateien und RAG = mehrere Credits
- sehr lange Outputs = mehrere Credits
- Script- und File-Nodes ohne KI = frei innerhalb der Runs

Credits werden im Team gepoolt. Overage: 10 EUR pro weitere 5.000 Credits.

### Bring your own Key

Wer eigene Modell-Keys hinterlegt (Google AI, xAI, Mistral, OpenRouter,
OpenAI-kompatibel), erhaelt 30 Prozent Rabatt auf den Sitzplatzpreis; inkludierte
Credits entfallen dann. Das entkoppelt die Marge von den Modellpreisen und bildet
gleichzeitig die Bruecke zur lokalen Variante, die ohnehin auf Kunden-Keys und
Ollama setzt.

## 3. Preismodell Lokal (Lizenz)

### Warum Jahreslizenz und nicht Einmalkauf

Die lokale Variante verursacht laufende Arbeit: Image-Updates, SQLite-
Migrationen, Betrieb des novooa-Relays, Anpassungen an sich aendernde
Modellanbieter und deutlich hoeheren Supportaufwand pro Kunde (Docker Desktop,
LAN-Konfiguration, Updates). Eine Einmalzahlung finanziert das nicht dauerhaft.

Default ist daher eine **Subscription-Lizenz pro Runtime-Instanz mit
Nutzerstaffel**, abgerechnet jaehrlich.

### Preisliste

| Paket | Umfang | Preis |
| --- | --- | ---: |
| Local Team | 1 Runtime, bis 5 Nutzer | 1.990 EUR/Jahr |
| Local Business | 1 Runtime, bis 15 Nutzer | 4.900 EUR/Jahr |
| Local Enterprise | je Standort, unbegrenzte Nutzer, SSO/LDAP, Offline-Aktivierung | ab 9.900 EUR/Jahr |

Zusaetzlich:

- Einrichtung und Onboarding einmalig 990-2.500 EUR.
- Relay-Nutzung fuer externe Trigger und Benachrichtigungen als Add-on,
  ca. 29 EUR/Monat pro Runtime. Das Relay ist novooa-Infrastruktur und gehoert
  nicht in den Lizenzpreis.
- KI-Kosten traegt die Kundschaft selbst ueber eigene Provider-Keys oder Ollama.

### Warum lokal pro Nutzer teurer ist als Cloud

Die Zielgruppe der lokalen Variante kauft Datenhoheit, nicht Rechenleistung:
Kanzleien, Steuerberatung, Praxen, Behoerden, Industrie. In diesem Segment ist
die Zahlungsbereitschaft hoeher, die Inferenzkosten liegen beim Kunden und der
Supportaufwand bei novooa. Ein niedrigerer Preis pro Nutzer waere doppelt falsch.

### Dauerlizenz als Ausnahme

Fuer Kundschaft mit CAPEX-Budget (Behoerden, klassischer Mittelstand) auf
Anfrage: **3x Jahrespreis einmalig plus 20 Prozent Wartung pro Jahr.** Nicht auf
der Preisseite listen, nur im Vertriebsgespraech anbieten.

### Lizenzverhalten

Zwei Punkte, die bei On-Premise ueber Vertrauen entscheiden und von der
bestehenden `license-state.json`-Architektur bereits getragen werden:

- Nach Ablauf 30 Tage Grace Period, danach Read-only statt Abschaltung. Daten
  bleiben jederzeit zugaenglich und exportierbar.
- Offline-Aktivierung per signierter Datei fuer Netze ohne Internetzugang, als
  Enterprise-Merkmal.

## 4. Abgrenzung Cloud und Lokal

Die lokale Variante darf die Cloud nicht kannibalisieren. Ohne Abgrenzung
passiert Folgendes: ein Kunde, der in der Cloud 5 x 39 EUR = 195 EUR/Monat
zahlen wuerde, kauft stattdessen eine guenstige Einzelplatz-Lizenz, nutzt eigene
Modell-Keys und verursacht gleichzeitig den hoeheren Supportaufwand einer
Docker-Installation. Umsatz sinkt, Kosten steigen.

Abgrenzende Regeln:

1. **Mindestgroesse.** Kein lokales Paket unter 5 Nutzern. Einzelpersonen und
   Kleinstteams gehoeren in die Cloud.
2. **Mindestpreis.** Der guenstigste lokale Einstieg (1.990 EUR/Jahr) liegt
   oberhalb dessen, was ein kleines Cloud-Team zahlt.
3. **Kein Self-Service.** Lokal wird nicht im Checkout verkauft, sondern nach
   Gespraech. Das qualifiziert und verhindert Supportlast durch Kundschaft, die
   Docker nicht betreiben kann.
4. **Klare Positionierung.** Lokal ist die Antwort auf Datenhoheit und
   Compliance, nicht die guenstigere Variante.

## 5. Go-to-Market-Konsequenz

Cloud bei 19-39 EUR ist Self-Service und Product-led Growth. Lokal ab
1.990 EUR/Jahr ist vertriebsgetrieben mit Demo-Termin. Das sind zwei
verschiedene Go-to-Markets mit verschiedenen Websites, Funnels und
Support-Erwartungen.

Empfehlung: nicht gleichzeitig starten. Zuerst die Cloud validieren, lokal
zunaechst nur als "Enterprise: auf Anfrage" fuehren, bis mindestens zehn echte
Vertriebsgespraeche gefuehrt wurden und die Zahlungsbereitschaft im DACH-Markt
belegt ist.

## 6. Offene Punkte

- Credit-Gewichtung pro Node-Typ muss vor dem Launch konkret festgelegt und
  gemessen werden, sonst stimmt die Kalkulation der inkludierten Mengen nicht.
- Free-Plan-Missbrauch: 100 Credits/Monat sind die Obergrenze; alternativ statt
  eines dauerhaften Free-Plans eine 14-taegige Pro-Testphase pruefen.
- Externe Kommunikationstrigger (E-Mail, Messaging) sind in der
  Produktpositionierung vorgesehen, laufen aber nicht ueber Twilio. Der
  tatsaechliche Weg und dessen Kosten sind noch offen und derzeit nicht
  eingepreist.
