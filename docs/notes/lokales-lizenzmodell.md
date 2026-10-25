# Lokales Lizenzmodell

> novooa wird als Jahreslizenz pro Runtime mit Nutzerstaffel verkauft, nicht als Einmalkauf; KI-Kosten trägt die Kundschaft selbst.

Gehört zu: [Produkt](../index/produkt.md)

| Paket | Umfang | Preis |
| --- | --- | ---: |
| Local Team | 1 Runtime, bis 5 Nutzer | 1.990 EUR/Jahr |
| Local Business | 1 Runtime, bis 15 Nutzer | 4.900 EUR/Jahr |
| Local Enterprise | je Standort, unbegrenzte Nutzer, SSO/LDAP, Offline-Aktivierung | ab 9.900 EUR/Jahr |

- **Nutzerstaffel in der Lizenz:** Die signierte Lizenz trägt `maxUsers`
  (Zahl oder `null` = unbegrenzt); die Runtime lehnt weitere Konten ab
  ([Benutzerkonten](./runtime-benutzerkonten.md)). SSO ist
  [geplant](./runtime-sso-geplant.md), LDAP nicht.

- Dazu: Einrichtung einmalig 990–2.500 EUR; Relay für externe Auslöser und
  Benachrichtigungen als Add-on ca. 29 EUR/Monat je Runtime (Infrastruktur,
  nicht Teil der Lizenz); Modellkosten über eigene Keys oder Ollama.
- **Warum Jahreslizenz:** Image-Updates, Migrationen, Relay-Betrieb,
  Anpassung an Modellanbieter und höherer Support (Docker, LAN, Updates)
  verursachen laufende Arbeit.
- **Warum dieser Preis:** Die Zielgruppe (Kanzleien, Steuerberatung, Praxen,
  Behörden, Industrie) kauft Datenhoheit; Inferenz zahlt der Kunde, Support
  trägt novooa. Verkauft wird nach Gespräch, nicht per Self-Service.
- **Dauerlizenz** nur auf Anfrage für CAPEX-Budgets: 3× Jahrespreis einmalig
  plus 20 % Wartung jährlich; nicht auf der Preisseite.
- **Lizenzverhalten (vorgesehen):** nach Ablauf 30 Tage Kulanz, danach
  Read-only statt Abschaltung, Daten bleiben exportierbar; Offline-Aktivierung
  per signierter Datei als Enterprise-Merkmal. Heute sperrt eine abgelaufene
  Lizenz die Runtime mit `423`
  ([Regelmäßige Lizenzprüfung](./lizenz-regelmaessige-pruefung.md)).

## Siehe auch

- [Produktpositionierung](./produktpositionierung.md)
- [Lizenz-Token und Aktivierung](./lizenz-aktivierung.md)
- [Entscheidung: ML-Inferenz nur lokal](./ml-nur-lokal-entscheidung.md)
