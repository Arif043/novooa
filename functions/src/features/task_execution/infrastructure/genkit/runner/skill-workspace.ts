import {mkdir} from "node:fs/promises";
import path from "node:path";

import {SkillNotFoundError} from "../../../../skills/domain/entities/stored-skill.js";
import {type SkillContentReader} from "../../../../skills/domain/repositories/skill-content-reader.js";
import {type SkillAttachment} from "./task-definition.js";

/**
 * Kopiert die angehängten Skills als Ordner in einen node-lokalen `skills/`-Ordner. Die Genkit-Skill-Middleware
 * (`@genkit-ai/middleware`) macht jeden Unterordner mit einer SKILL.md zum Skill und nimmt den Ordnernamen als
 * Namen; weitere Dateien (`references/`, `scripts/`, `assets/`) liest das Modell über die Dateisystem-Werkzeuge.
 *
 * Rückgabe: der absolute Pfad zum Elternordner, den die Middleware als `skillPaths`-Eintrag verwendet.
 * `undefined`, wenn nichts anzuhängen ist.
 */
export async function prepareSkillDirectory(
  rootDirectory: string,
  attachments: SkillAttachment[],
  reader: SkillContentReader | undefined,
): Promise<string | undefined> {
  if (attachments.length === 0) return undefined;
  if (reader === undefined) throw new Error("Fähigkeiten sind in dieser Umgebung nicht verfügbar.");
  const skillsRoot = path.join(rootDirectory, "skills");
  await mkdir(skillsRoot, {recursive: true});
  for (const name of new Set(attachments.map((attachment) => attachment.name))) {
    try {
      await reader.copyTo(name, skillsRoot);
    } catch (error) {
      if (error instanceof SkillNotFoundError) throw new Error(error.message);
      throw error;
    }
  }
  return skillsRoot;
}
