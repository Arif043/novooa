# Bedingter Ablauf: Auswertung

> Jeder Zweig trägt einen booleschen Ausdrucksbaum; der erste zutreffende Zweig gewinnt, ein Zweig ohne Bedingung („Sonst“) ist der garantierte Fallback.

Gehört zu: [Aufgabe](../index/aufgabe.md)

**Baukasten-Bedingungen** (Standard, auch hinter Entscheidungs-Prompts):

- `BranchCondition`: Vergleich `left`/`operator`/`right` oder Gruppe mit
  AND/OR/XOR-verknüpften Kindern, beliebig verschachtelt (Verschachtelung
  ersetzt Klammern). UI: alle / mindestens eine / genau eine Bedingung.
- `selectConditionedBranch`/`evaluateBranchCondition`
  (`branch-condition-evaluator.ts`) prüfen der Reihe nach.
- Operanden über `resolveValue` (nicht `resolveText`) als Rohwert, damit echte
  Zahlen- und Boolean-Vergleiche gehen. „ist“/„ist nicht“ koerzieren ad hoc.
- Je Operator eine Strategie (`comparison-operators.ts`), die ein `Result`
  liefert. Passt ein Wert nicht zum Operator (z. B. „vor“ auf Text ohne
  Datum), ist das Ergebnis die Domain-Failure `ConditionOperandFailure`
  (Code `conditionOperandMismatch`, Felder `operator`, `expected`,
  `received`). Der Executor verpackt sie in `NodeFailedError`; der Client
  übersetzt Code und Felder (en/de/tr). Der technische Text ist sprachneutral.
- Der Client bietet je Datentyp passende Vergleiche an (`operatorsFor`; Typ
  aus `outputTypeOf`, also für alle Werte, nicht nur Felder):

  | Typ | Vergleiche |
  | --- | --- |
  | Text | ist, ist nicht, enthält (nicht), beginnt/endet mit, ist (nicht) leer |
  | Zahl | =, ≠, >, ≥, <, ≤ |
  | Wahrheitswert | ist wahr, ist falsch |
  | Auswahl | ist, ist nicht |
  | Datum/Zeit | ist am, ist vor, ist nach |
  | JSON | enthält (Element einer Liste, Schlüssel eines Objekts), ist (nicht) leer |
  | Datei/Bild/Audio | ist vorhanden, fehlt, Dateityp ist (`image/png`, `image/*`) |
  | Tabelle | ist (nicht) leer, Zeilenanzahl =, ≠, >, ≥, <, ≤ |

  Ohne erkennbaren Typ (gemischter Text, Pfad in JSON) bleiben die
  allgemeinen Vergleiche. Einstellige Vergleiche speichern keinen
  Vergleichswert (`ComparisonCondition.withOperator`).
- „ist am“ vergleicht Kalendertage in der Zeitzone der Runtime (`TZ`, im
  Docker-Stack `Europe/Berlin`). Ein reines Datum (`2026-10-18`) ist
  Mitternacht dieser Zeitzone.
- Editor `ConditionalBranchesEditor` ist immer bearbeitbar.

**Label-Matching** (nur Altdaten ohne jede Bedingung): `valueTemplate` als
Ziellabel, exakt passender Zweig, sonst der erste
(`executeConditionalFlow`). Der Builder erzeugt das nicht mehr.

In beiden Fällen läuft der Zweig über denselben Graph-Runner; dessen finale
Ausgabe wird `value` des Knotens, ohne Ausgabe der Name des Zweigs, ohne
gewählten Zweig gibt es keinen `value` (Metadaten `selectedNodeId`,
`selectedBranchId`, `selectedBranchLabel`). Ausgehende Top-Level-Kanten sind
nur Legacy-Fallback.

## Siehe auch

- [Entscheidungs-Prompt und Zweige](./entscheidungs-prompt-zweige.md)
- [Anschlüsse auf der Leinwand](./leinwand-anschluesse.md)
