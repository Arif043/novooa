import {SkillImportError} from "../entities/skill-import-error.js";
import {renamedSkillPackage} from "../entities/skill-package-rename.js";
import {SkillName} from "../entities/skill-name.js";
import {type StoredSkill} from "../entities/stored-skill.js";
import {type SkillStore} from "../repositories/skill-store.js";
import {type StagedSkillImports} from "../repositories/staged-skill-imports.js";

/** Übernimmt die ausgewählten Kandidaten eines Imports in den Skills-Ordner. */
export class CommitSkillImport {
  constructor(private readonly store: SkillStore, private readonly staged: StagedSkillImports) {}

  async execute(importId: string, names: readonly string[]): Promise<StoredSkill[]> {
    const entry = this.staged.find(importId);
    if (entry === undefined) throw new SkillImportError("Der Import ist abgelaufen. Bitte starte ihn erneut.");
    if (names.length === 0) throw new SkillImportError("Es wurde kein Skill ausgewählt.");
    const selected = names.map((name) => {
      const skill = entry.packages.find((candidate) => candidate.name === name);
      if (skill === undefined) throw new SkillImportError(`Der Skill „${name}“ gehört nicht zu diesem Import.`);
      return skill;
    });
    const taken = new Set((await this.store.list()).map((skill) => skill.name));
    const saved: StoredSkill[] = [];
    for (const skill of selected) {
      const name = SkillName.uniqueFor(SkillName.parse(skill.name)!, taken);
      taken.add(name.value);
      saved.push(await this.store.save(renamedSkillPackage(skill, name.value)));
    }
    this.staged.discard(importId);
    return saved;
  }
}
