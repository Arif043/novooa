export type StoredSkill = {
  /** Ordnername im Skills-Ordner — zugleich der Name, unter dem das Modell den Skill kennt. */
  name: string;
  description: string;
  license?: string;
  compatibility?: string;
  fileCount: number;
  /** Probleme, die der Nutzer beheben sollte (fehlende Beschreibung, abweichender Name). */
  warnings: string[];
};

export class SkillNotFoundError extends Error {
  constructor(readonly skillName: string) {
    super(`Der Skill „${skillName}“ wurde nicht gefunden. Wurde sein Ordner entfernt?`);
    this.name = "SkillNotFoundError";
  }
}

/** Der Skills-Ordner lässt sich nicht beschreiben (Rechte, schreibgeschützt). */
export class SkillStorageError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "SkillStorageError";
  }
}

export class SkillAlreadyExistsError extends Error {
  constructor(readonly skillName: string) {
    super(`Der Skill „${skillName}“ existiert bereits.`);
    this.name = "SkillAlreadyExistsError";
  }
}
