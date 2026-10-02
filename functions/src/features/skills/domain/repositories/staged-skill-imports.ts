import {type StagedSkillImport} from "../entities/skill-import-preview.js";

/** Hält die Kandidaten eines Imports bis zur Bestätigung vor. */
export interface StagedSkillImports {
  stage(entry: StagedSkillImport): string;
  find(importId: string): StagedSkillImport | undefined;
  discard(importId: string): void;
}
