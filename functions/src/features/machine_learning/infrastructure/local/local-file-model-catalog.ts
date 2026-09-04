import {mkdir, readFile, readdir, rename, writeFile} from "node:fs/promises";
import path from "node:path";
import {type ModelCatalogEntry} from "../../domain/entities/model-catalog-entry.js";
import {type ModelCatalog} from "../../domain/repositories/model-catalog.js";
import {
  modelCatalogEntryData,
  modelCatalogEntryFromData,
  type ModelCatalogEntryData,
} from "../model-catalog-entry-codec.js";

export class LocalFileModelCatalog implements ModelCatalog {
  constructor(private readonly directory: string) {}

  async save(entry: ModelCatalogEntry): Promise<void> {
    await mkdir(this.directory, {recursive: true});
    const destination = this.pathFor(entry.id);
    const temporary = `${destination}.tmp`;
    await writeFile(temporary, JSON.stringify(modelCatalogEntryData(entry)), "utf8");
    await rename(temporary, destination);
  }

  async listAvailableFor(teamId: string): Promise<readonly ModelCatalogEntry[]> {
    const names = await catalogFileNames(this.directory);
    const entries = await Promise.all(names.map((name) => this.entryFromFile(name)));
    return entries.filter((entry) => availableFor(entry, teamId)).sort(compareEntries);
  }

  async findAvailableFor(teamId: string, modelId: string): Promise<ModelCatalogEntry | null> {
    const entry = await this.entryFromFile(this.fileNameFor(modelId)).catch(fileNotFoundAsNull);
    return entry !== null && availableFor(entry, teamId) ? entry : null;
  }

  private async entryFromFile(name: string): Promise<ModelCatalogEntry> {
    const content = await readFile(path.join(this.directory, name), "utf8");
    return modelCatalogEntryFromData(dataRecord(JSON.parse(content) as unknown));
  }

  private pathFor(modelId: string): string {
    return path.join(this.directory, this.fileNameFor(modelId));
  }

  private fileNameFor(modelId: string): string {
    return `${Buffer.from(modelId).toString("base64url")}.json`;
  }
}

async function catalogFileNames(directory: string): Promise<readonly string[]> {
  try {
    return (await readdir(directory)).filter((name) => name.endsWith(".json"));
  } catch (error) {
    if (fileMissing(error)) return [];
    throw error;
  }
}

function dataRecord(value: unknown): ModelCatalogEntryData {
  if (value === null || typeof value !== "object" || Array.isArray(value)) {
    throw new Error("Der lokale Modellkatalog enthält einen ungültigen Eintrag.");
  }
  return value as ModelCatalogEntryData;
}

function availableFor(entry: ModelCatalogEntry, teamId: string): boolean {
  return entry.scope.type === "system" || entry.scope.teamId === teamId;
}

function compareEntries(left: ModelCatalogEntry, right: ModelCatalogEntry): number {
  return left.title.localeCompare(right.title) || left.id.localeCompare(right.id);
}

function fileNotFoundAsNull(error: unknown): null {
  if (fileMissing(error)) return null;
  throw error;
}

function fileMissing(error: unknown): boolean {
  return typeof error === "object" && error !== null && "code" in error && error.code === "ENOENT";
}
