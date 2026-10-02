/** Ein Importfehler mit einer Meldung, die der Nutzer lesen darf. */
export class SkillImportError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "SkillImportError";
  }
}
