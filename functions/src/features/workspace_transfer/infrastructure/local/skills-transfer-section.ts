import {z} from "zod";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {
  existingSkillFolder,
  SkillPackageError,
  type SkillFile,
  type SkillPackage,
} from "../../../skills/domain/entities/skill-package.js";
import {SkillNotFoundError} from "../../../skills/domain/entities/stored-skill.js";
import {type SkillStore} from "../../../skills/domain/repositories/skill-store.js";
import {InvalidTransferArchiveError} from "../../domain/entities/transfer-errors.js";
import {
  transferBlobEntry,
  transferDataEntry,
  type TransferArchiveReader,
  type TransferArchiveWriter,
} from "../../domain/repositories/transfer-archive.js";
import {type TransferSection} from "../../domain/repositories/transfer-section.js";
import {sectionPayload, type SqliteTransferSectionImporter, type StagedSectionImport} from "./sqlite-transfer-section-importer.js";

const skillsTransferPayload = z.object({
  skills: z.array(z.object({
    name: z.string().min(1).max(255),
    files: z.array(z.object({path: z.string().min(1).max(1000)})).min(1).max(1000),
  })).max(2000),
});

type SkillsTransferPayload = z.infer<typeof skillsTransferPayload>;

/** Blob-Einträge müssen mit `blobs/` beginnen, sonst hält der Reader `.json`-Dateien eines Skills für Archiv-JSON. */
const skillBlobEntry = (name: string, path: string): string => transferBlobEntry(`skills/${name}/${path}`);

type AppliedSkill = {name: string; backup?: SkillFile[]};

/**
 * Fähigkeiten im Export: je Skill ein Ordner mit allen Dateien. Der Skills-Ordner gehört der Anwendung und ist nicht
 * team-gebunden, deshalb braucht der Import kein Team-Mapping. Gleichnamige Skills werden ersetzt (wie gleiche IDs
 * bei den anderen Bereichen), andere bleiben unberührt; scheitert der Import, wird der alte Stand wiederhergestellt.
 */
export class SkillsTransferSection implements TransferSection, SqliteTransferSectionImporter {
  readonly category = "skills" as const;

  constructor(private readonly skills: SkillStore) {}

  async exportTo(writer: TransferArchiveWriter): Promise<number> {
    const payload = await this.payload();
    await writer.addJson(transferDataEntry("skills"), payload);
    for (const skill of payload.skills) {
      for (const file of await this.skills.readFiles(skill.name)) {
        await writer.addBlob(skillBlobEntry(skill.name, file.path), singleChunk(file.bytes));
      }
    }
    return payload.skills.length;
  }

  async stage(reader: TransferArchiveReader): Promise<StagedSectionImport> {
    const payload = await sectionPayload(reader, "skills", skillsTransferPayload);
    const packages = await this.packagesFrom(reader, payload);
    const applied: AppliedSkill[] = [];
    return {
      count: packages.length,
      commit: (_executor: RuntimeExecutor) => this.replace(packages, applied),
      rollback: () => this.restore(applied),
    };
  }

  /** Nur die Dateipfade; die Bytes werden pro Skill erst beim Schreiben gelesen, damit nie alles im Speicher liegt. */
  private async payload(): Promise<SkillsTransferPayload> {
    const skills: SkillsTransferPayload["skills"] = [];
    for (const skill of await this.skills.list()) {
      const files = await this.skills.readFiles(skill.name).catch(ignoreVanished);
      if (files !== undefined) skills.push({name: skill.name, files: files.map((file) => ({path: file.path}))});
    }
    return {skills};
  }

  private async packagesFrom(reader: TransferArchiveReader, payload: SkillsTransferPayload): Promise<SkillPackage[]> {
    const names = payload.skills.map((skill) => skill.name);
    if (new Set(names).size !== names.length) throw new InvalidTransferArchiveError("Der Export enthält einen Skill mehrfach.");
    const wanted = new Map(payload.skills.flatMap((skill) => skill.files.map((file) => [skillBlobEntry(skill.name, file.path), {skill: skill.name, path: file.path}] as const)));
    const collected = new Map<string, SkillFile[]>(names.map((name) => [name, []]));
    await reader.forEachBlob(new Set(wanted.keys()), async (entry, content) => {
      const target = wanted.get(entry);
      if (target === undefined) return;
      collected.get(target.skill)?.push({path: target.path, bytes: content});
      wanted.delete(entry);
    });
    if (wanted.size > 0) throw new InvalidTransferArchiveError("Im Export fehlen Dateiinhalte der Fähigkeiten.");
    return names.map((name) => validated(name, collected.get(name) ?? []));
  }

  private async replace(packages: readonly SkillPackage[], applied: AppliedSkill[]): Promise<void> {
    const existing = new Set((await this.skills.list()).map((skill) => skill.name));
    for (const skill of packages) {
      const entry: AppliedSkill = {name: skill.name};
      applied.push(entry);
      if (existing.has(skill.name)) {
        entry.backup = await this.skills.readFiles(skill.name);
        await this.skills.delete(skill.name);
      }
      await this.skills.save(skill);
    }
  }

  private async restore(applied: readonly AppliedSkill[]): Promise<void> {
    for (const entry of [...applied].reverse()) {
      await this.skills.delete(entry.name).catch(ignoreVanished);
      if (entry.backup !== undefined) await this.skills.save(existingSkillFolder(entry.name, entry.backup));
    }
  }
}

function validated(name: string, files: SkillFile[]): SkillPackage {
  try {
    return existingSkillFolder(name, files);
  } catch (error) {
    if (error instanceof SkillPackageError) throw new InvalidTransferArchiveError(error.message);
    throw error;
  }
}

async function* singleChunk(bytes: Uint8Array): AsyncGenerator<Uint8Array> {
  yield bytes;
}

function ignoreVanished(error: unknown): undefined {
  if (error instanceof SkillNotFoundError) return undefined;
  throw error;
}
