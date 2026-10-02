/** Gibt dem Lauf Zugriff auf die Ordner angehängter Skills. */
export interface SkillContentReader {
  /** Kopiert den ganzen Skill-Ordner nach `<directory>/<name>/`; wirft `SkillNotFoundError`. */
  copyTo(name: string, directory: string): Promise<void>;
}
