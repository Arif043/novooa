export type Employee = {
  id: string;
  name: string;
  /** Rahmenbedingung: gilt als System-Prompt für jeden Aufruf des Mitarbeiters. */
  constraint: string;
  /** Namen der Fähigkeiten (Ordnernamen im Skills-Verzeichnis), die der Mitarbeiter implizit erhält. */
  skills: string[];
  createdAt: string;
  updatedAt: string;
};

/** Was der Nutzer beim Anlegen und Ändern angibt. */
export type EmployeeInput = {
  name: string;
  constraint: string;
  skills: string[];
};

export const employeeLimits = {
  maximumNameLength: 80,
  maximumConstraintLength: 8000,
  maximumSkills: 50,
} as const;

/** Ein Fehler mit einer Meldung, die der Nutzer lesen darf. */
export class EmployeeValidationError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "EmployeeValidationError";
  }
}

export class EmployeeNotFoundError extends Error {
  constructor(readonly employeeId: string) {
    super("Der Mitarbeiter wurde nicht gefunden.");
    this.name = "EmployeeNotFoundError";
  }
}

export class EmployeeNameTakenError extends Error {
  constructor(readonly employeeName: string) {
    super(`Es gibt schon einen Mitarbeiter mit dem Namen „${employeeName}“.`);
    this.name = "EmployeeNameTakenError";
  }
}

/** Ein Skill-Name ist ein einzelner Ordnername: kein Pfadtrenner, nicht versteckt, nicht leer. */
export function isSkillFolderName(name: string): boolean {
  return name.length > 0 && name.length <= 255 && !name.startsWith(".") && !/[\\/\0]/.test(name);
}

/** Prüft und bereinigt die Eingabe: getrimmte Texte, Skill-Namen ohne Dubletten in der Reihenfolge der Eingabe. */
export function employeeInputFrom(raw: EmployeeInput): EmployeeInput {
  const name = raw.name.trim();
  if (name.length === 0) throw new EmployeeValidationError("Gib dem Mitarbeiter einen Namen.");
  if (name.length > employeeLimits.maximumNameLength) {
    throw new EmployeeValidationError(`Der Name ist zu lang (höchstens ${employeeLimits.maximumNameLength} Zeichen).`);
  }
  const constraint = raw.constraint.trim();
  if (constraint.length > employeeLimits.maximumConstraintLength) {
    throw new EmployeeValidationError(`Die Rahmenbedingung ist zu lang (höchstens ${employeeLimits.maximumConstraintLength} Zeichen).`);
  }
  const skills = [...new Set(raw.skills.map((skill) => skill.trim()))];
  if (skills.length > employeeLimits.maximumSkills) {
    throw new EmployeeValidationError(`Zu viele Fähigkeiten (höchstens ${employeeLimits.maximumSkills}).`);
  }
  const invalid = skills.find((skill) => !isSkillFolderName(skill));
  if (invalid !== undefined) throw new EmployeeValidationError(`Der Name der Fähigkeit „${invalid}“ ist ungültig.`);
  return {name, constraint, skills};
}

export function sameEmployeeName(first: string, second: string): boolean {
  return first.trim().toLocaleLowerCase("de") === second.trim().toLocaleLowerCase("de");
}
