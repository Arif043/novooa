# Lokalisierung

> Die App ist mit `easy_localization` dreisprachig (Englisch als Standard und Rückfall, Deutsch, Türkisch); sichtbare Texte kommen nur über typisierte `LocaleKeys`.

Gehört zu: [Architektur](../index/architektur.md)

- Ohne gespeicherte Wahl gilt die Gerätesprache, sofern unterstützt; Wechsel
  unter Einstellungen (`LanguageSettingsSection`), gespeichert von
  easy_localization.
- Texte in `assets/translations/{en,de,tr}.json`; Schlüssel in
  `lib/core/localization/locale_keys.g.dart`, neu erzeugen mit
  `dart run easy_localization:generate -S assets/translations -O lib/core/localization -o locale_keys.g.dart -f keys`.
- `translations_test.dart` erzwingt gleiche Schlüssel und Platzhalter in allen
  Sprachen.
- `domain/` kennt kein `easy_localization`: Sprachabhängige Standardtexte
  kommen über Ports (z. B. `NodeTextDefaults`), die `tr()`-Umsetzung liegt in
  `presentation/`.
- Tests laufen mit deutschen Texten (`test/flutter_test_config.dart`); andere
  Sprache per `loadTestTranslations(Locale('en'))`.
- Stand: Aufgabenstudio, Agent-Panel, Baustein-Labels, Standardnamen,
  Spracheinstellung sowie Zeitplan- und Dateien-Leerzustände sind migriert;
  übrige Features und Texte in Domain/Infrastructure sind noch deutsch.

## Siehe auch

- [Standardnamen neuer Bausteine](./standardnamen-neuer-bausteine.md)
- [Antwortsprache des Agenten](./agent-antwortsprache.md)
