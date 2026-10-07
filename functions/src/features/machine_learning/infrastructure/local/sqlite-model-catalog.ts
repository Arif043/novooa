import {and, eq, isNull, or, sql} from "drizzle-orm";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {modelCatalog} from "../../../../db/schema.js";
import {type ModelCatalogEntry} from "../../domain/entities/model-catalog-entry.js";
import {type TeamModelCatalog} from "../../domain/repositories/model-catalog.js";
import {
  modelCatalogEntryData,
  modelCatalogEntryFromData,
} from "../model-catalog-entry-codec.js";

type ModelCatalogRow = {
  id: string;
  title: string;
  description: string;
  translations_json: string;
  task: string;
  languages_json: string;
  tags_json: string;
  team_id: string | null;
  artifact_reference_json: string;
  contract_json: string;
  origin: "catalog" | "import";
};

export class SQLiteModelCatalog implements TeamModelCatalog {
  constructor(private readonly database: RuntimeExecutor) {}

  async save(entry: ModelCatalogEntry): Promise<void> {
    const data = modelCatalogEntryData(entry);
    modelCatalogEntryFromData(data);
    const values = {id: data.id, title: data.title, description: data.description,
      translations_json: JSON.stringify(data.translations), tags_json: JSON.stringify(data.tags),
      task: data.task, languages_json: JSON.stringify(data.languages),
      team_id: data.teamId,
      artifact_reference_json: JSON.stringify(data.artifactReference), contract_json: JSON.stringify(data.contract),
      origin: data.origin ?? "import"};
    await this.database.insert(modelCatalog).values(values)
      .onConflictDoUpdate({target: modelCatalog.id, set: {...values, updated_at: sql`CURRENT_TIMESTAMP`}});
  }

  async listAvailableFor(teamId: string): Promise<readonly ModelCatalogEntry[]> {
    const rows = await this.database.select().from(modelCatalog).where(availableFor(teamId))
      .orderBy(sql`${modelCatalog.title} COLLATE NOCASE`, modelCatalog.id);
    return rows.map(entryFromRow);
  }

  async findAvailableFor(
    teamId: string,
    modelId: string,
  ): Promise<ModelCatalogEntry | null> {
    const row = await this.database.select().from(modelCatalog).where(and(eq(modelCatalog.id, modelId), availableFor(teamId))).get();
    return row === undefined ? null : entryFromRow(row);
  }

  async removeTeamEntry(teamId: string, modelId: string): Promise<boolean> {
    const removed = await this.database.delete(modelCatalog)
      .where(and(eq(modelCatalog.id, modelId), eq(modelCatalog.team_id, teamId)))
      .returning({id: modelCatalog.id});
    return removed.length > 0;
  }
}

function availableFor(teamId: string) {
  return or(isNull(modelCatalog.team_id), eq(modelCatalog.team_id, teamId));
}

function entryFromRow(row: ModelCatalogRow): ModelCatalogEntry {
  return modelCatalogEntryFromData({
    id: row.id,
    title: row.title,
    description: row.description,
    translations: parseJson(row.translations_json, "Die gespeicherten Modellübersetzungen sind ungültig."),
    task: row.task,
    languages: parseJson(row.languages_json, "Die gespeicherten Modellsprachen sind ungültig."),
    tags: parseJson(row.tags_json, "Die gespeicherten Modell-Tags sind ungültig."),
    scope: row.team_id === null ? "system" : "team",
    teamId: row.team_id,
    runtime: "onnx",
    artifactReference: parseJson(
      row.artifact_reference_json,
      "Die gespeicherte Modell-Artefakt-Referenz ist ungültig.",
    ),
    contract: parseJson(row.contract_json, "Der gespeicherte Modellvertrag ist ungültig."),
    // Systemeinträge ohne Team haben keine lokale Herkunft.
    ...(row.team_id === null ? {} : {origin: row.origin}),
  });
}

function parseJson(value: string, message: string): unknown {
  try {
    return JSON.parse(value) as unknown;
  } catch {
    throw new Error(message);
  }
}
