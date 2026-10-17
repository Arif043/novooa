import {type ComparisonOperator} from "../entities/task.js";
import {
  calendarDayOf, isEmptyValue, isRecord, looseEquals, requireBoolean, requireDate, requireFile,
  requireNumber, requireText, stringFor,
} from "./comparison-operands.js";

type Comparison = (left: unknown, right: unknown) => boolean;

/** Deutsche Namen für Laufzeitmeldungen; übersetzt wird im Client. */
const operatorLabels: Record<ComparisonOperator, string> = {
  equals: "ist", notEquals: "ist nicht",
  greaterThan: "größer als", greaterThanOrEqual: "größer oder gleich",
  lessThan: "kleiner als", lessThanOrEqual: "kleiner oder gleich",
  contains: "enthält", notContains: "enthält nicht",
  startsWith: "beginnt mit", endsWith: "endet mit",
  isEmpty: "ist leer", isNotEmpty: "ist nicht leer",
  isTrue: "ist wahr", isFalse: "ist falsch",
  sameDay: "ist am", before: "vor", after: "nach",
  contentTypeIs: "Dateityp ist",
};

/** Eine Strategie je Operator. Einstellige Operatoren ignorieren `right`. */
export const comparisonOperators: Record<ComparisonOperator, Comparison> = {
  equals: looseEquals,
  notEquals: (left, right) => !looseEquals(left, right),
  greaterThan: numeric("greaterThan", (left, right) => left > right),
  greaterThanOrEqual: numeric("greaterThanOrEqual", (left, right) => left >= right),
  lessThan: numeric("lessThan", (left, right) => left < right),
  lessThanOrEqual: numeric("lessThanOrEqual", (left, right) => left <= right),
  contains,
  notContains: (left, right) => !requireText(left, operatorLabels.notContains).includes(stringFor(right)),
  startsWith: (left, right) => requireText(left, operatorLabels.startsWith).startsWith(stringFor(right)),
  endsWith: (left, right) => requireText(left, operatorLabels.endsWith).endsWith(stringFor(right)),
  isEmpty: (left) => isEmptyValue(left),
  isNotEmpty: (left) => !isEmptyValue(left),
  isTrue: (left) => requireBoolean(left, operatorLabels.isTrue),
  isFalse: (left) => !requireBoolean(left, operatorLabels.isFalse),
  sameDay: dated("sameDay", (left, right) => calendarDayOf(left) === calendarDayOf(right)),
  before: dated("before", (left, right) => left.getTime() < right.getTime()),
  after: dated("after", (left, right) => left.getTime() > right.getTime()),
  contentTypeIs: (left, right) => contentTypeMatches(requireFile(left, operatorLabels.contentTypeIs).contentType, right),
};

function numeric(operator: ComparisonOperator, compare: (left: number, right: number) => boolean): Comparison {
  const label = operatorLabels[operator];
  return (left, right) => compare(requireNumber(left, label), requireNumber(right, label));
}

function dated(operator: ComparisonOperator, compare: (left: Date, right: Date) => boolean): Comparison {
  const label = operatorLabels[operator];
  return (left, right) => compare(requireDate(left, label), requireDate(right, label));
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
