import {type DiscoveredSkills} from "../entities/skill-discovery.js";
import {SkillName} from "../entities/skill-name.js";
import {type SkillImportOrigin, type SkillImportPreview} from "../entities/skill-import-preview.js";
import {type SkillPackage} from "../entities/skill-package.js";
import {type SkillStore} from "../repositories/skill-store.js";
import {type StagedSkillImports} from "../repositories/staged-skill-imports.js";

/** Macht aus den gefundenen Skills eine Vorschau und hält sie bis zur Bestätigung bereit. */
export class PreviewSkillImport {
  constructor(private readonly store: SkillStore, private readonly staged: StagedSkillImports) {}

  async execute(origin: SkillImportOrigin, discovered: DiscoveredSkills): Promise<SkillImportPreview> {
    const installed = new Set((await this.store.list()).map((skill) => skill.name));
    const packages = withUniqueNames(discovered.packages);
    const importId = this.staged.stage({origin, packages, rejected: discovered.rejected});
    return {
      importId,
      origin,
      rejected: discovered.rejected,
      candidates: packages.map((skill) => ({
        name: skill.name,
        description: skill.description,
        fileCount: skill.files.length,
        totalBytes: skill.files.reduce((sum, file) => sum + file.bytes.length, 0),
        warnings: skill.warnings,
        nameTaken: installed.has(skill.name),
      })),
    };
  }
}

/** Zwei Skills desselben Imports mit gleichem Namen sind sonst nicht einzeln auswählbar. */
function withUniqueNames(packages: readonly SkillPackage[]): SkillPackage[] {
  const taken = new Set<string>();
  return packages.map((skill) => {
    const base = SkillName.parse(skill.name)!;
    const unique = SkillName.uniqueFor(base, taken);
    taken.add(unique.value);
    if (unique.value === skill.name) return skill;
    return {...skill, name: unique.value, warnings: [...skill.warnings, `Der Name „${skill.name}“ kommt im Import mehrfach vor; verwendet wird „${unique.value}“.`]};
  });
}
