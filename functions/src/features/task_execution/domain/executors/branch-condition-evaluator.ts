import {type BranchCondition, type ConditionalBranch} from "../entities/task.js";

/** Löst `left`/`right` über [resolveValue] auf (der rohe, typisierte Wert —
 * siehe `TemplateExpressionResolver.resolveValue`, NICHT `resolveText`,
 * sonst wären echte Zahlen-/Boolean-Vergleiche unmöglich) und wertet den
 * gesamten Ausdrucksbaum rekursiv aus. */
export function evaluateBranchCondition(
  condition: BranchCondition,
  resolveValue: (template: string) => unknown,
): boolean {
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
): {branch: ConditionalBranch; matched: boolean} | undefined {
  for (const branch of branches) {
    if (branch.condition === undefined) continue;
    if (evaluateBranchCondition(branch.condition, resolveValue)) {
      return {branch, matched: true};
    }
  }
  const sonst = branches.find((branch) => branch.condition === undefined);
  return sonst ? {branch: sonst, matched: false} : undefined;
}

function evaluateComparison(
  comparison: Extract<BranchCondition, {kind: "comparison"}>,
  resolveValue: (template: string) => unknown,
): boolean {
  const left = resolveValue(comparison.left);
  const right = resolveValue(comparison.right);
  switch (comparison.operator) {
    case "equals": return looseEquals(left, right);
    case "notEquals": return !looseEquals(left, right);
    case "contains": return stringFor(left).includes(stringFor(right));
    case "greaterThan": return numberFor(left) > numberFor(right);
    case "greaterThanOrEqual": return numberFor(left) >= numberFor(right);
    case "lessThan": return numberFor(left) < numberFor(right);
    case "lessThanOrEqual": return numberFor(left) <= numberFor(right);
  }
}

// "ENTWEDER-ODER" (xor) über mehr als zwei Kinder: die für eine
// Baukasten-UI naheliegendste Lesart ist "genau eines trifft zu", nicht
// bitweise bei mehr als zwei Operanden verkettete Parität.
function evaluateGroup(
  group: Extract<BranchCondition, {kind: "group"}>,
  resolveValue: (template: string) => unknown,
): boolean {
  const results = group.children.map((child) => evaluateBranchCondition(child, resolveValue));
  switch (group.combinator) {
    case "and": return results.every((result) => result);
    case "or": return results.some((result) => result);
    case "xor": return results.filter((result) => result).length === 1;
  }
}

/** Ad-hoc-Koerzion: ein Literal (immer ein String, siehe
 * `resolveValue`-Fallback für nicht-isolierte Ausdrücke) wird bei Bedarf
 * als Zahl/Boolean interpretiert, damit z.B. `{{zahl}} > 10` auch
 * funktioniert, wenn `zahl` als String-typisierter Wert zurückkommt. */
function looseEquals(left: unknown, right: unknown): boolean {
  if (typeof left === "number" || typeof right === "number") {
    const leftNumber = numberFor(left);
    const rightNumber = numberFor(right);
    if (!Number.isNaN(leftNumber) && !Number.isNaN(rightNumber)) {
      return leftNumber === rightNumber;
    }
  }
  if (typeof left === "boolean" || typeof right === "boolean") {
    const leftBoolean = booleanFor(left);
    const rightBoolean = booleanFor(right);
    if (leftBoolean !== undefined && rightBoolean !== undefined) {
      return leftBoolean === rightBoolean;
    }
  }
  return stringFor(left) === stringFor(right);
}

function numberFor(value: unknown): number {
  if (typeof value === "number") return value;
  if (typeof value === "string" && value.trim().length > 0) {
    const parsed = Number(value);
    if (!Number.isNaN(parsed)) return parsed;
  }
  return NaN;
}

function booleanFor(value: unknown): boolean | undefined {
  if (typeof value === "boolean") return value;
  if (typeof value === "string") {
    const lower = value.trim().toLowerCase();
    if (lower === "true") return true;
    if (lower === "false") return false;
  }
  return undefined;
}

function stringFor(value: unknown): string {
  if (typeof value === "string") return value;
  if (value === undefined || value === null) return "";
  return typeof value === "object" ? JSON.stringify(value) : String(value);
}
