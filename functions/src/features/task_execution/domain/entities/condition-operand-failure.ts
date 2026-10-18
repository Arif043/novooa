import {NodeFailure} from "./node-failure.js";
import {type ComparisonOperator} from "./task.js";

/** Welche Art Wert ein Vergleich braucht. */
export type OperandKind = "number" | "date" | "boolean" | "text" | "file";

const maxReceivedLength = 80;

/**
 * Ein Wert passt nicht zum Vergleich, z. B. „ist vor“ auf einen Text, der
 * kein Datum ist. Ein Geschäftsfehler: Der Bedingungs-Baustein scheitert,
 * statt still „trifft nicht zu“ zu werten. Übersetzt wird im Client anhand
 * von Code und Feldern.
 */
export class ConditionOperandFailure {
  readonly code = "conditionOperandMismatch";
  readonly received: string;

  constructor(
    readonly operator: ComparisonOperator,
    readonly expected: OperandKind,
    receivedValue: unknown,
  ) {
    this.received = shortened(receivedValue);
  }

  /** Als Ursache eines gescheiterten Bausteins. */
  toNodeFailure(): NodeFailure {
    return NodeFailure.of({code: this.code, message: this.technicalMessage, details: this.details});
  }

  /** Die Felder für die Übersetzung im Client. */
  get details(): Record<string, string> {
    return {operator: this.operator, expected: this.expected, received: this.received};
  }

  /** Sprachneutral, für Protokoll und als technischer Rückfalltext. */
  get technicalMessage(): string {
    return `${this.code}: operator=${this.operator} expected=${this.expected} received="${this.received}"`;
  }
}

function shortened(value: unknown): string {
  if (value === undefined || value === null) return "";
  const text = typeof value === "string" ? value : JSON.stringify(value);
  return text.length > maxReceivedLength ? `${text.slice(0, maxReceivedLength - 1)}…` : text;
}
