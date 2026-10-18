import {ok, Result} from "neverthrow";
import {type ConditionOperandFailure} from "../entities/condition-operand-failure.js";
import {type BranchCondition, type ConditionalBranch} from "../entities/task.js";
import {comparisonOperators, type ComparisonOrFailure} from "./comparison-operators.js";

export type BranchMatch = {branch: ConditionalBranch; matched: boolean};
export type BranchMatchOrFailure = Result<BranchMatch | undefined, ConditionOperandFailure>;

/** Löst `left`/`right` über [resolveValue] auf (der rohe, typisierte Wert —
 * siehe `TemplateExpressionResolver.resolveValue`, NICHT `resolveText`,
 * sonst wären echte Zahlen-/Boolean-Vergleiche unmöglich) und wertet den
 * gesamten Ausdrucksbaum rekursiv aus. Passt ein Wert nicht zum Operator,
 * ist das Ergebnis eine `ConditionOperandFailure`. */
export function evaluateBranchCondition(
  condition: BranchCondition,
  resolveValue: (template: string) => unknown,
): ComparisonOrFailure {
  return condition.kind === "group"
    ? evaluateGroup(condition, resolveValue)
    : evaluateComparison(condition, resolveValue);
}

/** Wählt den ersten bedingten Zweig, dessen Ausdruck zutrifft (Reihenfolge
 * der Liste = Prüfreihenfolge). Trifft keiner zu, ist der "Sonst"-Zweig
 * (`condition === undefined`) der garantierte Fallback — kein stiller
 * Rückfall auf den ersten Zweig wie im alten Label-Matching-Pfad. */
export function selectConditionedBranch(
  branches: ConditionalBranch[],
  resolveValue: (template: string) => unknown,
): BranchMatchOrFailure {
  for (const branch of branches) {
    if (branch.condition === undefined) continue;
    const matchOrFailure = evaluateBranchCondition(branch.condition, resolveValue);
    if (matchOrFailure.isErr()) return matchOrFailure.map(() => undefined);
    if (matchOrFailure.value) return ok({branch, matched: true});
  }
  const sonst = branches.find((branch) => branch.condition === undefined);
  return ok(sonst ? {branch: sonst, matched: false} : undefined);
}

function evaluateComparison(
  comparison: Extract<BranchCondition, {kind: "comparison"}>,
  resolveValue: (template: string) => unknown,
): ComparisonOrFailure {
  const compare = comparisonOperators[comparison.operator];
  return compare(resolveValue(comparison.left), resolveValue(comparison.right));
}

// "ENTWEDER-ODER" (xor) über mehr als zwei Kinder: die für eine
// Baukasten-UI naheliegendste Lesart ist "genau eines trifft zu", nicht
// bitweise bei mehr als zwei Operanden verkettete Parität.
function evaluateGroup(
  group: Extract<BranchCondition, {kind: "group"}>,
  resolveValue: (template: string) => unknown,
): ComparisonOrFailure {
  const childResults = group.children.map((child) => evaluateBranchCondition(child, resolveValue));
  return Result.combine(childResults).map((results) => {
    switch (group.combinator) {
      case "and": return results.every((result) => result);
      case "or": return results.some((result) => result);
      case "xor": return results.filter((result) => result).length === 1;
    }
  });
}
