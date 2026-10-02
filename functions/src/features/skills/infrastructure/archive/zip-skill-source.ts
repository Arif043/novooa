import {discoverSkills, type DiscoveredSkills} from "../../domain/entities/skill-discovery.js";
import {SkillImportError} from "../../domain/entities/skill-import-error.js";
import {type SkillSource} from "../../domain/repositories/skill-source.js";
import {readZipFiles, withoutCommonRoot} from "./zip-reader.js";

export type ZipSkillReference = {bytes: Uint8Array; fileName: string};

/** Hochgeladenes ZIP mit einem oder mehreren Skill-Ordnern. */
export class ZipSkillSource implements SkillSource<ZipSkillReference> {
  async resolve({bytes, fileName}: ZipSkillReference): Promise<DiscoveredSkills> {
    const {files, root} = withoutCommonRoot(readZipFiles(bytes));
    const discovered = discoverSkills(files, root ?? fileName.replace(/\.zip$/i, ""));
    if (discovered.packages.length === 0 && discovered.rejected.length === 0) {
      throw new SkillImportError("Im Archiv wurde kein Skill gefunden (ein Skill-Ordner enthält eine Datei SKILL.md).");
    }
    return discovered;
  }
}
