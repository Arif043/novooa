import {and, eq, or, sql} from "drizzle-orm";
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
  tags_json: string;
  scope: string;
  team_id: string | null;
  runtime: string;
  artifact_reference_json: string;
  contract_json: string;
};

export class SQLiteModelCatalog implements TeamModelCatalog {
  constructor(private readonly database: RuntimeExecutor) {}

  async save(entry: ModelCatalogEntry): Promise<void> {
    const data = modelCatalogEntryData(entry);
    const values = {id: data.id, title: data.title, description: data.description, tags_json: JSON.stringify(data.tags),
      scope: data.scope, team_id: data.teamId, runtime: data.runtime,
      artifact_reference_json: JSON.stringify(data.artifactReference), contract_json: JSON.stringify(data.contract)};
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
      .where(and(eq(modelCatalog.id, modelId), eq(modelCatalog.scope, "team"), eq(modelCatalog.team_id, teamId)))
      .returning({id: modelCatalog.id});
    return removed.length > 0;
  }
}

function availableFor(teamId: string) {
  return or(eq(modelCatalog.scope, "system"), and(eq(modelCatalog.scope, "team"), eq(modelCatalog.team_id, teamId)));
}

function entryFromRow(row: ModelCatalogRow): ModelCatalogEntry {
  return modelCatalogEntryFromData({
    id: row.id,
    title: row.title,
    description: row.description,
    tags: parseJson(row.tags_json, "Die gespeicherten Modell-Tags sind ungültig."),
    scope: row.scope,
    teamId: row.team_id,
    runtime: row.runtime,
    artifactReference: parseJson(
      row.artifact_reference_json,
      "Die gespeicherte Modell-Artefakt-Referenz ist ungültig.",
    ),
    contract: parseJson(row.contract_json, "Der gespeicherte Modellvertrag ist ungültig."),
  });
}

function parseJson(value: string, message: string): unknown {
  try {
    return JSON.parse(value) as unknown;
  } catch {
    throw new Error(message);
  }
}
