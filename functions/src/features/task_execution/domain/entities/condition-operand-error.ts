/**
 * Ein Operand einer Bedingung passt nicht zum Operator, z. B. „vor“ auf
 * einen Text, der kein Datum ist. Der Bedingungs-Baustein scheitert dann,
 * statt still „trifft nicht zu“ zu werten.
 */
export class ConditionOperandError extends Error {
  constructor(operatorLabel: string, expected: string, received: unknown) {
    super(`„${operatorLabel}“ braucht ${expected}, erhalten: ${describe(received)}.`);
    this.name = "ConditionOperandError";
  }
}

function describe(value: unknown): string {
  if (value === undefined || value === null) return "keinen Wert";
  const text = typeof value === "string" ? value : JSON.stringify(value);
  const shortened = text.length > 80 ? `${text.slice(0, 77)}…` : text;
  return `„${shortened}“`;
}
