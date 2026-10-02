import {SkillCatalogError} from "../../domain/entities/skill-catalog.js";
import {discoverSkills, type DiscoveredSkills} from "../../domain/entities/skill-discovery.js";
import {SkillImportError} from "../../domain/entities/skill-import-error.js";
import {type SkillSource} from "../../domain/repositories/skill-source.js";
import {catalogPath} from "./skills-sh-catalog.js";
import {type SkillsShClient} from "./skills-sh-client.js";

export type SkillsShSkillReference = {id: string};

const detailTtlSeconds = 300;

/** Importiert einen Katalog-Skill: Der Detail-Endpunkt liefert alle Dateien als Text, GitHub wird nicht gebraucht. */
export class SkillsShSkillSource implements SkillSource<SkillsShSkillReference> {
  constructor(private readonly client: SkillsShClient) {}

  async resolve({id}: SkillsShSkillReference): Promise<DiscoveredSkills> {
    const detail = await this.client.get<{slug?: unknown; files?: unknown}>(`/skills/${catalogPath(id)}`, {}, detailTtlSeconds)
      .catch((error: unknown) => { throw error instanceof SkillCatalogError ? new SkillImportError(error.message) : error; });
    if (!Array.isArray(detail.files) || detail.files.length === 0) {
      throw new SkillImportError("Für diesen Skill liegt bei skills.sh kein Dateiabzug vor. Importiere ihn über seine GitHub-Adresse.");
    }
    const files = detail.files.flatMap((file) => {
      const entry = file as {path?: unknown; contents?: unknown} | null;
      return typeof entry?.path === "string" && typeof entry.contents === "string"
        ? [{path: entry.path, bytes: new TextEncoder().encode(entry.contents)}] : [];
    });
    const discovered = discoverSkills(files, typeof detail.slug === "string" ? detail.slug : id.split("/").pop()!);
    for (const skill of discovered.packages) {
      skill.warnings.push("skills.sh liefert nur Textdateien; Bilder und andere Binärdateien des Skills fehlen.");
    }
    return discovered;
  }
}
