# Changelog novooa-dashboard

Versionen nach SemVer. Bei jeder Änderung an `SKILL.md`, `references/`,
`assets/starter/` oder `scripts/` die Version in `SKILL.md`
(`metadata.version`) und in `scripts/create_dashboard.sh` (`skill_version`)
heben und hier eintragen.

## 0.2.0

- Die Runtime kennt den Baustein „Bild anfordern“ (`mediaInput`) nicht mehr;
  Bilder fragt die Formulareingabe über den Feldtyp `image` ab. Vorlage:
  `UnsupportedRequest` entfällt, `FormFieldType.image` kommt hinzu,
  Formulare mit Bildfeld zeigen einen Hinweis aufs offizielle Frontend und
  lassen sich nicht freigeben. Bestehende Dashboards: `run_interaction.dart`,
  `task_run_mapper.dart`, `review_section.dart` und
  `form_request_fields.dart` übernehmen.

## 0.1.0

- Erste Fassung für `novooa_runtime_client` 0.1.0.
- Vorlage (`assets/starter`): Anmeldung über `RuntimeConnectionCubit`
  (Adresse, Login, Einladungscode, Sitzungsende), Aufgaben live mit Start und
  Eingabe, Läufe live mit Ergebnis, Freigabe und Formular, responsive
  Navigation, Texte in `en`, `de`, `tr`, Cubit- und Mapper-Tests.
- Referenzen: Authentifizierung, Runtime-API, Echtzeit, Plattformen,
  Architektur, optionales Modul „Auslöser“.
- `scripts/create_dashboard.sh` legt ein Dashboard aus der Vorlage an.
