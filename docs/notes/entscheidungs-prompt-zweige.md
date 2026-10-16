# Entscheidungs-Prompt und Zweige

> Ein Bedingter Ablauf hinter einem Entscheidungs-Prompt ist nur lose gekoppelt: Umbenennen zieht nach, alles andere ist sichtbar und manuell.

Gehört zu: [Aufgabe](../index/aufgabe.md)

Code: `task_builder_decision_branch_mutations.dart`.

- **Anhängen:** Ein leerer Bedingter Ablauf hinter einem Entscheidungs-Prompt
  bekommt einmalig je Antwort einen Zweig mit sichtbarer Bedingung
  `{{Antwort}}` *ist gleich* `<Antwort>`.
- **Antwort umbenennen:** Zweige, deren Bedingung noch genau
  `{{Antwort}}` *ist gleich* `<alte Antwort>` lautet, folgen
  (`withRenamedAnswer`); die Beschriftung folgt, solange sie der alten Antwort
  entspricht. Wer eine Bedingung ändert, löst den Zweig vom Prompt.
- **Hauptwert umbenennen** (auch automatisch beim Typwechsel): alle
  Bedingungen ziehen nach (`{{Antwort}}` → `{{Text}}`).
- **Neue oder gelöschte Antworten** ändern den Ablauf nicht. Das Panel nennt
  Antworten ohne Zweig (`missingDecisionAnswers`, `DecisionCoverageHint`);
  „Fehlende Zweige ergänzen“ fügt sie vor „Sonst“ ein. Eigene Bedingungen und
  „Sonst“ bleiben immer.

Darstellung: Die Leinwand beschriftet jeden Zweig mit seiner Bedingung
(„Antwort ist Ja“, `branchConditionSummary`), ohne Bedingung „Sonst“; die
Panel-Karten heißen fest „Bedingung 1, 2 …“. Den Sonst-Pfad schaltet eine
Checkbox im Panel; gefüllte Pfade werden nur nach Bestätigung entfernt.

## Siehe auch

- [Bedingter Ablauf: Auswertung](./bedingter-ablauf-auswertung.md)
- [Standardnamen neuer Bausteine](./standardnamen-neuer-bausteine.md)
