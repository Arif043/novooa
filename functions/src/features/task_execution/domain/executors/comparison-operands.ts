import {ConditionOperandError} from "../entities/condition-operand-error.js";

/** Rohwert eines Tabellen-Werts, wie ihn `resolveValue` liefert. */
type TableValue = {columns: unknown[]; rows: unknown[]};
type FileValue = {fileId: string; contentType: string};

const dateOnlyPattern = /^(\d{4})-(\d{2})-(\d{2})$/;

/** Ad-hoc-Koerzion für „ist“/„ist nicht“: Zahl und Wahrheitswert auch aus Text. */
export function looseEquals(left: unknown, right: unknown): boolean {
  if (typeof left === "number" || typeof right === "number") {
    const leftNumber = numberOrNaN(left);
    const rightNumber = numberOrNaN(right);
    if (!Number.isNaN(leftNumber) && !Number.isNaN(rightNumber)) return leftNumber === rightNumber;
  }
  if (typeof left === "boolean" || typeof right === "boolean") {
    const leftBoolean = booleanOrUndefined(left);
    const rightBoolean = booleanOrUndefined(right);
    if (leftBoolean !== undefined && rightBoolean !== undefined) return leftBoolean === rightBoolean;
  }
  return stringFor(left) === stringFor(right);
}

export function stringFor(value: unknown): string {
  if (typeof value === "string") return value;
  if (typeof value === "number" || typeof value === "boolean") return String(value);
  return value === undefined || value === null ? "" : JSON.stringify(value);
}

/** Eine Tabelle zählt als Zahl ihrer Zeilen („Zeilenanzahl > 3“). */
export function requireNumber(value: unknown, label: string): number {
  if (isTable(value)) return value.rows.length;
  const number = numberOrNaN(value);
  if (Number.isNaN(number)) throw new ConditionOperandError(label, "eine Zahl", value);
  return number;
}

export function requireBoolean(value: unknown, label: string): boolean {
  const boolean = booleanOrUndefined(value);
  if (boolean === undefined) throw new ConditionOperandError(label, "einen Wahrheitswert", value);
  return boolean;
}

export function requireText(value: unknown, label: string): string {
  if (typeof value === "string" || typeof value === "number" || typeof value === "boolean") return String(value);
  throw new ConditionOperandError(label, "einen Text", value);
}

/** Ein reines Datum (`2026-10-18`) ist Mitternacht in der Zeitzone der Runtime. */
export function requireDate(value: unknown, label: string): Date {
  if (typeof value === "string") {
    const dateOnly = dateOnlyPattern.exec(value.trim());
    const date = dateOnly
      ? new Date(Number(dateOnly[1]), Number(dateOnly[2]) - 1, Number(dateOnly[3]))
      : new Date(value);
    if (!Number.isNaN(date.getTime())) return date;
  }
  throw new ConditionOperandError(label, "ein Datum", value);
}

export function requireFile(value: unknown, label: string): FileValue {
  if (isRecord(value) && typeof value.fileId === "string" && typeof value.contentType === "string") {
    return {fileId: value.fileId, contentType: value.contentType};
  }
  throw new ConditionOperandError(label, "eine Datei", value);
}

/** Leer: kein Wert, leerer Text, leere Liste, leeres Objekt, Tabelle ohne Zeilen. */
export function isEmptyValue(value: unknown): boolean {
  if (value === undefined || value === null) return true;
  if (typeof value === "string") return value.trim().length === 0;
  if (Array.isArray(value)) return value.length === 0;
  if (isTable(value)) return value.rows.length === 0;
  return isRecord(value) && Object.keys(value).length === 0;
}

/** Kalendertag (`YYYY-MM-DD`) in der Zeitzone der Runtime (`TZ`). */
export function calendarDayOf(date: Date): string {
  return new Intl.DateTimeFormat("en-CA", {year: "numeric", month: "2-digit", day: "2-digit"}).format(date);
}

export function isRecord(value: unknown): value is Record<string, unknown> {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function isTable(value: unknown): value is TableValue {
  return isRecord(value) && Array.isArray(value.columns) && Array.isArray(value.rows);
}

function numberOrNaN(value: unknown): number {
  if (typeof value === "number") return value;
  if (typeof value === "string" && value.trim().length > 0) return Number(value);
  return NaN;
}

function booleanOrUndefined(value: unknown): boolean | undefined {
  if (typeof value === "boolean") return value;
  if (typeof value !== "string") return undefined;
  const lower = value.trim().toLowerCase();
  if (lower === "true") return true;
  return lower === "false" ? false : undefined;
}
