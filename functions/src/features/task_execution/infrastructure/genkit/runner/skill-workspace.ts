import {mkdir} from "node:fs/promises";
import path from "node:path";

import {type ObjectStore} from "../../../../files/domain/repositories/object-store.js";
import {type SkillAttachment} from "./task-definition.js";

/**
 * Kopiert alle an einen Baustein angehängten Skills in einen node-lokalen
 * `skills/`-Ordner. Die Genkit-Skill-Middleware (`@genkit-ai/middleware`)
 * erwartet pro Skill einen Unterordner mit einer SKILL.md — genau dieses
 * Layout stellen wir hier her.
 *
 * Rückgabe: der absolute Pfad zum Elternordner, den die Middleware als
 * `skillPaths`-Eintrag verwendet. `undefined`, wenn nichts anzuhängen ist.
 */
export async function prepareSkillDirectory(
  rootDirectory: string,
  attachments: SkillAttachment[],
  objectStore: ObjectStore,
): Promise<string | undefined> {
  if (attachments.length === 0) return undefined;
  const skillsRoot = path.join(rootDirectory, "skills");
  await mkdir(skillsRoot, {recursive: true});
  await Promise.all(
    attachments.map((attachment, index) =>
      downloadSkill(skillsRoot, attachment, index, objectStore),
    ),
  );
  return skillsRoot;
}

async function downloadSkill(
  skillsRoot: string,
  attachment: SkillAttachment,
  index: number,
  objectStore: ObjectStore,
): Promise<void> {
  const slug = safeSlug(attachment.title, attachment.skillId, index);
  const skillDir = path.join(skillsRoot, slug);
  await mkdir(skillDir, {recursive: true});
  const destination = path.join(skillDir, "SKILL.md");
  await objectStore.downloadToFile(attachment.storagePath, destination);
}

function safeSlug(title: string, fallbackId: string, index: number): string {
  const source = title.trim().length > 0 ? title : fallbackId;
  const normalized = source
    .toLowerCase()
    .replace(/[^a-z0-9._-]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 80);
  if (normalized.length > 0) return `${index + 1}-${normalized}`;
  return `skill-${index + 1}`;
}
