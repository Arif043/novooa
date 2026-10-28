export type DialogInputFieldType =
  | "string"
  | "number"
  | "integer"
  | "decimal"
  | "selection"
  | "boolean"
  | "radio"
  /** Ein Bild; der Wert ist die `fileId` einer hochgeladenen Team-Datei. */
  | "image"
  /** Ein Kalendertag als `YYYY-MM-DD`, ohne Uhrzeit und Zeitzone. */
  | "date"
  /** Eine Uhrzeit als `HH:mm` (24 Stunden), ohne Datum. */
  | "time";

export type DialogInputField = {
  name: string;
  type: DialogInputFieldType;
  options: string[];
};

export type DialogInputDefinition = {
  instruction: string;
  fields: DialogInputField[];
};

export type DialogInputValue = string | number | boolean;

export function validateDialogInputDefinition(
  definition: DialogInputDefinition,
): void {
  const names = definition.fields.map((field) => field.name.trim());
  if (names.length === 0) throw new Error("Das Formular benötigt mindestens ein Feld.");
  if (names.some((name) => name.length === 0)) throw new Error("Jedes Formularfeld benötigt einen Namen.");
  if (names.some((name) => !/^[a-zA-Z_][a-zA-Z0-9_]*$/.test(name))) {
    throw new Error("Formularfeldnamen dürfen nur Buchstaben, Zahlen und Unterstriche enthalten.");
  }
  if (names.includes("text")) throw new Error("Der Feldname \"text\" ist reserviert.");
  if (new Set(names).size !== names.length) throw new Error("Formularfeldnamen müssen eindeutig sein.");
  for (const field of definition.fields) validateOptions(field);
}

export function validateDialogInputValues(
  definition: DialogInputDefinition,
  values: Record<string, unknown>,
): Record<string, DialogInputValue> {
  validateDialogInputDefinition(definition);
  return definition.fields.reduce<Record<string, DialogInputValue>>(
    (validated, field) => {
      const name = field.name.trim();
      validated[name] = validateDialogInputValue(field, values[name]);
      return validated;
    },
    {},
  );
}

function validateOptions(field: DialogInputField): void {
  if (!needsOptions(field) || validOptions(field).length > 0) return;
  throw new Error(`Das Feld "${field.name}" benötigt mindestens eine Option.`);
}

function validateDialogInputValue(
  field: DialogInputField,
  value: unknown,
): DialogInputValue {
  if (field.type === "boolean") return booleanValue(field, value);
  if (field.type === "number" || field.type === "decimal") {
    return numberValue(field, value, false);
  }
  if (field.type === "integer") return numberValue(field, value, true);
  if (field.type === "date") return patternValue(field, value, isCalendarDate);
  if (field.type === "time") return patternValue(field, value, isTimeOfDay);
  return textValue(field, value);
}

function booleanValue(field: DialogInputField, value: unknown): boolean {
  if (typeof value === "boolean") return value;
  throw invalidValue(field);
}

function numberValue(
  field: DialogInputField,
  value: unknown,
  integerOnly: boolean,
): number {
  if (typeof value !== "number" || !Number.isFinite(value)) throw invalidValue(field);
  if (integerOnly && !Number.isInteger(value)) throw invalidValue(field);
  return value;
}

function textValue(field: DialogInputField, value: unknown): string {
  if (typeof value !== "string" || value.trim().length === 0) throw invalidValue(field);
  if (needsOptions(field) && !validOptions(field).includes(value)) {
    throw invalidValue(field);
  }
  return value;
}

function patternValue(field: DialogInputField, value: unknown, isValid: (text: string) => boolean): string {
  if (typeof value !== "string" || !isValid(value)) throw invalidValue(field);
  return value;
}

/** Nur echte Kalendertage: `2026-02-30` passt zum Muster, existiert aber nicht. */
function isCalendarDate(text: string): boolean {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(text);
  if (match === null) return false;
  const [year, month, day] = match.slice(1).map(Number);
  const date = new Date(Date.UTC(year, month - 1, day));
  return date.getUTCFullYear() === year && date.getUTCMonth() === month - 1 && date.getUTCDate() === day;
}

function isTimeOfDay(text: string): boolean {
  return /^([01]\d|2[0-3]):[0-5]\d$/.test(text);
}

function needsOptions(field: DialogInputField): boolean {
  return field.type === "selection" || field.type === "radio";
}

function validOptions(field: DialogInputField): string[] {
  return field.options.map((option) => option.trim()).filter(Boolean);
}

function invalidValue(field: DialogInputField): Error {
  return new Error(`Ungültige Eingabe für "${field.name}".`);
}
