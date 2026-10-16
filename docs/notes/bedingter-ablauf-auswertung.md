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
  Zahlen- und Boolean-Vergleiche gehen; untypisierte Werte werden ad hoc
  koerziert.
- Editor `ConditionalBranchesEditor` ist immer bearbeitbar.

**Label-Matching** (nur Altdaten ohne jede Bedingung): `valueTemplate` als
Ziellabel, exakt passender Zweig, sonst der erste
(`executeConditionalFlow`). Der Builder erzeugt das nicht mehr.

In beiden Fällen läuft der Zweig über denselben Graph-Runner; dessen finale
Ausgabe wird `value` des Knotens (Metadaten `selectedNodeId`,
`selectedBranchId`, `selectedBranchLabel`). Ausgehende Top-Level-Kanten sind
nur Legacy-Fallback.

## Siehe auch

- [Entscheidungs-Prompt und Zweige](./entscheidungs-prompt-zweige.md)
- [Anschlüsse auf der Leinwand](./leinwand-anschluesse.md)
