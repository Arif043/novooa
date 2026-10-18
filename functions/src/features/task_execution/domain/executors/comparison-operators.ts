import {ok, Result} from "neverthrow";
import {type ConditionOperandFailure} from "../entities/condition-operand-failure.js";
import {type ComparisonOperator} from "../entities/task.js";
import {
  booleanOperand, calendarDayOf, dateOperand, fileOperand, isEmptyValue, isRecord, looseEquals,
  numberOperand, textOperand, stringFor, type OperandOrFailure,
} from "./comparison-operands.js";

export type ComparisonOrFailure = Result<boolean, ConditionOperandFailure>;
type Comparison = (left: unknown, right: unknown) => ComparisonOrFailure;
type Operand<T> = (value: unknown, operator: ComparisonOperator) => OperandOrFailure<T>;

/** Eine Strategie je Operator. Einstellige Operatoren ignorieren `right`. */
export const comparisonOperators: Record<ComparisonOperator, Comparison> = {
  equals: (left, right) => ok(looseEquals(left, right)),
  notEquals: (left, right) => ok(!looseEquals(left, right)),
  greaterThan: binary("greaterThan", numberOperand, (left, right) => left > right),
  greaterThanOrEqual: binary("greaterThanOrEqual", numberOperand, (left, right) => left >= right),
  lessThan: binary("lessThan", numberOperand, (left, right) => left < right),
  lessThanOrEqual: binary("lessThanOrEqual", numberOperand, (left, right) => left <= right),
  contains: (left, right) => ok(contains(left, right)),
  notContains: textual("notContains", (left, right) => !left.includes(right)),
  startsWith: textual("startsWith", (left, right) => left.startsWith(right)),
  endsWith: textual("endsWith", (left, right) => left.endsWith(right)),
  isEmpty: (left) => ok(isEmptyValue(left)),
  isNotEmpty: (left) => ok(!isEmptyValue(left)),
  isTrue: (left) => booleanOperand(left, "isTrue"),
  isFalse: (left) => booleanOperand(left, "isFalse").map((value) => !value),
  sameDay: binary("sameDay", dateOperand, (left, right) => calendarDayOf(left) === calendarDayOf(right)),
  before: binary("before", dateOperand, (left, right) => left.getTime() < right.getTime()),
  after: binary("after", dateOperand, (left, right) => left.getTime() > right.getTime()),
  contentTypeIs: (left, right) =>
    fileOperand(left, "contentTypeIs").map((file) => contentTypeMatches(file.contentType, right)),
};

/** Beide Seiten müssen die gleiche Art Wert sein (Zahl, Datum). */
function binary<T>(
  operator: ComparisonOperator, operand: Operand<T>, compare: (left: T, right: T) => boolean,
): Comparison {
  return (left, right) => Result.combine([operand(left, operator), operand(right, operator)])
    .map(([leftValue, rightValue]) => compare(leftValue, rightValue));
}

/** Der geprüfte Wert muss Text sein; der Vergleichswert wird als Text gelesen. */
function textual(operator: ComparisonOperator, compare: (left: string, right: string) => boolean): Comparison {
  return (left, right) => textOperand(left, operator).map((text) => compare(text, stringFor(right)));
}

/** Liste: enthält ein gleiches Element; Objekt: hat den Schlüssel; sonst Teiltext. */
function contains(left: unknown, right: unknown): boolean {
  if (Array.isArray(left)) return left.some((element) => looseEquals(element, right));
  if (isRecord(left) && !("rows" in left)) return stringFor(right) in left;
  return stringFor(left).includes(stringFor(right));
}

/** `image/png` exakt oder `image/*` als Platzhalter für die Hauptart. */
function contentTypeMatches(contentType: string, expected: unknown): boolean {
  const pattern = stringFor(expected).trim().toLowerCase();
  const actual = contentType.toLowerCase();
  return pattern.endsWith("/*") ? actual.startsWith(pattern.slice(0, -1)) : actual === pattern;
}
