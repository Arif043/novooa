import {randomUUID} from "node:crypto";
import {cp, mkdir, readdir, readFile, rename, rm, stat, writeFile} from "node:fs/promises";
import path from "node:path";
import {canonicalSkillMarkdown, parseSkillManifest} from "../../domain/entities/skill-manifest.js";
import {skillEntryFile, type SkillPackage} from "../../domain/entities/skill-package.js";
import {SkillAlreadyExistsError, SkillNotFoundError, SkillStorageError, type StoredSkill} from "../../domain/entities/stored-skill.js";
import {type SkillStore} from "../../domain/repositories/skill-store.js";

/**
 * Der Skills-Ordner liegt im Dateisystem: `<ordner>/<skill-name>/SKILL.md` (+ `scripts/`, `references/`, `assets/`).
 * Er ist die einzige Quelle der Wahrheit — Ordner, die der Nutzer von Hand hineinlegt, sind sofort Skills.
 */
export class DirectorySkillStore implements SkillStore {
  constructor(readonly location: string) {}

  async list(): Promise<StoredSkill[]> {
    const entries = await readdir(this.location, {withFileTypes: true}).catch(ignoreMissing([]));
    const skills = await Promise.all(entries.filter((entry) => entry.isDirectory() && isSafeFolderName(entry.name)).map((entry) => this.read(entry.name)));
    return skills.filter((skill): skill is StoredSkill => skill !== null).sort((a, b) => a.name.localeCompare(b.name, "de"));
  }

  async save(skill: SkillPackage): Promise<StoredSkill> {
    const target = this.folderOf(skill.name);
    if (await exists(target)) throw new SkillAlreadyExistsError(skill.name);
    await mkdir(this.location, {recursive: true});
    const staging = path.join(this.location, `.incoming-${randomUUID()}`);
    try {
      for (const file of skill.files) await writeInside(staging, file.path, file.bytes);
      await rename(staging, target);
    } catch (error) {
      await rm(staging, {recursive: true, force: true});
      if (isPermissionError(error)) {
        throw new SkillStorageError(`In den Skills-Ordner „${this.location}“ kann nicht geschrieben werden. Prüfe die Rechte des Ordners.`);
      }
      throw error;
    }
    return (await this.read(skill.name))!;
  }

  async delete(name: string): Promise<void> {
    const folder = this.folderOf(name);
    if (!(await exists(folder))) throw new SkillNotFoundError(name);
    await rm(folder, {recursive: true, force: true});
  }

  async copyTo(name: string, directory: string): Promise<void> {
    const source = this.folderOf(name);
    const entry = path.join(source, skillEntryFile);
    if (!(await exists(entry))) throw new SkillNotFoundError(name);
    const target = path.join(directory, name);
    await cp(source, target, {recursive: true});
    const markdown = await readFile(path.join(target, skillEntryFile), "utf8");
    await writeFile(path.join(target, skillEntryFile), canonicalSkillMarkdown(markdown, name));
  }

  private folderOf(name: string): string {
    if (!isSafeFolderName(name)) throw new SkillNotFoundError(name);
    return path.join(this.location, name);
  }

  private async read(name: string): Promise<StoredSkill | null> {
    const folder = path.join(this.location, name);
    const markdown = await readFile(path.join(folder, skillEntryFile), "utf8").catch(ignoreMissing(null));
    if (markdown === null) return null;
    const manifest = parseSkillManifest(markdown);
    const warnings: string[] = [];
    if (manifest.description === undefined) warnings.push("Es fehlt die Beschreibung (description) im Kopf der SKILL.md; das Modell kann den Skill so kaum auswählen.");
    if (manifest.name !== undefined && manifest.name !== name) warnings.push(`Der Name im Kopf („${manifest.name}“) weicht vom Ordnernamen ab; maßgeblich ist der Ordnername „${name}“.`);
    return {
      name,
      description: manifest.description ?? "",
      ...(manifest.license ? {license: manifest.license} : {}),
      ...(manifest.compatibility ? {compatibility: manifest.compatibility} : {}),
      fileCount: await countFiles(folder),
      warnings,
    };
  }
}

function isPermissionError(error: unknown): boolean {
  const code = (error as NodeJS.ErrnoException | null)?.code;
  return code === "EACCES" || code === "EPERM" || code === "EROFS";
}

/** Ein einzelner Ordnername ohne Pfadtrenner; versteckte Ordner (`.incoming-…`) sind keine Skills. */
export function isSafeFolderName(name: string): boolean {
  return name.length > 0 && name.length <= 255 && !name.startsWith(".") && !/[\\/\0]/.test(name);
}

async function writeInside(root: string, relativePath: string, bytes: Uint8Array): Promise<void> {
  const destination = path.resolve(root, relativePath);
  if (!destination.startsWith(path.resolve(root) + path.sep)) throw new Error(`Ungültiger Dateipfad: ${relativePath}`);
  await mkdir(path.dirname(destination), {recursive: true});
  await writeFile(destination, bytes);
}

async function countFiles(folder: string): Promise<number> {
  const entries = await readdir(folder, {withFileTypes: true});
  const counts = await Promise.all(entries.map((entry) => entry.isDirectory() ? countFiles(path.join(folder, entry.name)) : Promise.resolve(1)));
  return counts.reduce((sum, count) => sum + count, 0);
}

async function exists(target: string): Promise<boolean> {
  return stat(target).then(() => true, () => false);
}

function ignoreMissing<Fallback>(fallback: Fallback) {
  return (error: NodeJS.ErrnoException): Fallback => {
    if (error.code === "ENOENT" || error.code === "ENOTDIR") return fallback;
    throw error;
  };
}
