import {randomUUID} from "node:crypto";
import {mkdir, readdir, readFile, rename, rm, stat, writeFile} from "node:fs/promises";
import path from "node:path";
import {parsePluginManifest} from "../../domain/entities/plugin-manifest.js";
import {pluginManifestFile, type PluginFile, type PluginPackage} from "../../domain/entities/plugin-package.js";
import {PluginNotFoundError, PluginStorageError, type StoredPlugin} from "../../domain/entities/stored-plugin.js";
import {type PluginStore} from "../../domain/repositories/plugin-store.js";

const safeId = /^[a-z][a-z0-9-]{1,39}$/;

/** `<ordner>/<plugin-id>/plugin.json` + Dateien. Der Ordner ist die einzige Quelle der Wahrheit. */
export class DirectoryPluginStore implements PluginStore {
  constructor(private readonly location: string) {}

  async list(): Promise<StoredPlugin[]> {
    const entries = await readdir(this.location, {withFileTypes: true}).catch(ignoreMissing([]));
    const plugins = await Promise.all(entries.filter((entry) => entry.isDirectory() && safeId.test(entry.name)).map((entry) => this.find(entry.name)));
    return plugins.filter((plugin): plugin is StoredPlugin => plugin !== undefined).sort((a, b) => a.name.localeCompare(b.name, "de"));
  }

  async find(id: string): Promise<StoredPlugin | undefined> {
    if (!safeId.test(id)) return undefined;
    const text = await readFile(path.join(this.location, id, pluginManifestFile), "utf8").catch(ignoreMissing(null));
    if (text === null) return undefined;
    try {
      const manifest = parsePluginManifest(text);
      if (manifest.id !== id) return undefined;
      return {id, version: manifest.version, name: manifest.name, description: manifest.description, manifest};
    } catch {
      return undefined;
    }
  }

  async save(plugin: PluginPackage): Promise<StoredPlugin> {
    const id = plugin.manifest.id;
    const target = path.join(this.location, id);
    const staging = path.join(this.location, `.incoming-${randomUUID()}`);
    const previous = path.join(this.location, `.replaced-${randomUUID()}`);
    await mkdir(this.location, {recursive: true});
    try {
      for (const file of plugin.files) await writeInside(staging, file.path, file.bytes);
      const replacing = await exists(target);
      if (replacing) await rename(target, previous);
      try {
        await rename(staging, target);
      } catch (error) {
        if (replacing) await rename(previous, target);
        throw error;
      }
      await rm(previous, {recursive: true, force: true});
    } catch (error) {
      await rm(staging, {recursive: true, force: true});
      if (isPermissionError(error)) {
        throw new PluginStorageError(`In den Plugin-Ordner „${this.location}“ kann nicht geschrieben werden. Prüfe die Rechte des Ordners.`);
      }
      throw error;
    }
    return (await this.find(id))!;
  }

  async delete(id: string): Promise<void> {
    if (!safeId.test(id) || !(await exists(path.join(this.location, id)))) throw new PluginNotFoundError(id);
    await rm(path.join(this.location, id), {recursive: true, force: true});
  }

  async readFiles(id: string): Promise<PluginFile[]> {
    if (!safeId.test(id) || (await this.find(id)) === undefined) throw new PluginNotFoundError(id);
    return readTree(path.join(this.location, id), "");
  }
}

async function writeInside(root: string, relativePath: string, bytes: Uint8Array): Promise<void> {
  const destination = path.resolve(root, relativePath);
  if (!destination.startsWith(path.resolve(root) + path.sep)) throw new Error(`Ungültiger Dateipfad: ${relativePath}`);
  await mkdir(path.dirname(destination), {recursive: true});
  await writeFile(destination, bytes);
}

/** Symlinks werden übersprungen, damit nichts außerhalb des Ordners gelesen wird. */
async function readTree(root: string, relative: string): Promise<PluginFile[]> {
  const entries = await readdir(path.join(root, relative), {withFileTypes: true});
  const files = await Promise.all(entries.map(async (entry): Promise<PluginFile[]> => {
    const entryPath = relative === "" ? entry.name : `${relative}/${entry.name}`;
    if (entry.isDirectory()) return readTree(root, entryPath);
    if (!entry.isFile()) return [];
    return [{path: entryPath, bytes: new Uint8Array(await readFile(path.join(root, entryPath)))}];
  }));
  return files.flat();
}

function isPermissionError(error: unknown): boolean {
  const code = (error as NodeJS.ErrnoException | null)?.code;
  return code === "EACCES" || code === "EPERM" || code === "EROFS";
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
