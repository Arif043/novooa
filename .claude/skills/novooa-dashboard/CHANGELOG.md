# Changelog novooa-dashboard

Versionen nach SemVer. Bei jeder Änderung an `SKILL.md`, `references/`,
`assets/starter/` oder `scripts/` die Version in `SKILL.md`
(`metadata.version`) und in `scripts/create_dashboard.sh` (`skill_version`)
heben und hier eintragen.

## 0.1.0

- Erste Fassung für `novooa_runtime_client` 0.1.0.
- Vorlage (`assets/starter`): Anmeldung über `RuntimeConnectionCubit`
  (Adresse, Login, Einladungscode, Sitzungsende), Aufgaben live mit Start und
  Eingabe, Läufe live mit Ergebnis, Freigabe und Formular, responsive
  Navigation, Texte in `en`, `de`, `tr`, Cubit- und Mapper-Tests.
- Referenzen: Authentifizierung, Runtime-API, Echtzeit, Plattformen,
  Architektur, optionales Modul „Auslöser“.
- `scripts/create_dashboard.sh` legt ein Dashboard aus der Vorlage an.
