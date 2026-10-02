import {discoverSkills, type DiscoveredSkills} from "../../domain/entities/skill-discovery.js";
import {SkillImportError} from "../../domain/entities/skill-import-error.js";
import {type SkillFile} from "../../domain/entities/skill-package.js";
import {type SkillSource} from "../../domain/repositories/skill-source.js";

export type FolderSkillReference = {
  /** Name des gewählten Ordners; benennt einen Skill, dessen `SKILL.md` direkt darin liegt. */
  name: string;
  files: Array<{path: string; contentBase64: string}>;
};

/** Ein vom Client gelesener Ordner (Dateiliste mit relativen Pfaden); der Ordner darf einen oder mehrere Skills enthalten. */
export class FolderSkillSource implements SkillSource<FolderSkillReference> {
  async resolve({name, files}: FolderSkillReference): Promise<DiscoveredSkills> {
    const skillFiles: SkillFile[] = files.map((file) => ({path: file.path, bytes: new Uint8Array(Buffer.from(file.contentBase64, "base64"))}));
    const discovered = discoverSkills(skillFiles, name);
    if (discovered.packages.length === 0 && discovered.rejected.length === 0) {
      throw new SkillImportError("Im Ordner wurde kein Skill gefunden (ein Skill-Ordner enthält eine Datei SKILL.md).");
    }
    return discovered;
  }
}
