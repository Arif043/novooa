import {type LocalSqlDatabase, type SqlRow} from "../../../../shared/local/local-sql-database.js";
import {type ModelCatalogEntry} from "../../domain/entities/model-catalog-entry.js";
import {type ModelCatalog} from "../../domain/repositories/model-catalog.js";
import {
  modelCatalogEntryData,
  modelCatalogEntryFromData,
} from "../model-catalog-entry-codec.js";

type ModelCatalogRow = SqlRow & {
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

export class SQLiteModelCatalog implements ModelCatalog {
  constructor(private readonly database: LocalSqlDatabase) {}

  async save(entry: ModelCatalogEntry): Promise<void> {
    const data = modelCatalogEntryData(entry);
    await this.database.run(saveEntrySql, saveParameters(data));
  }

  async listAvailableFor(teamId: string): Promise<readonly ModelCatalogEntry[]> {
    const rows = await this.database.all<ModelCatalogRow>(listAvailableSql, [teamId]);
    return rows.map(entryFromRow);
  }

  async findAvailableFor(
    teamId: string,
    modelId: string,
  ): Promise<ModelCatalogEntry | null> {
    const row = await this.database.get<ModelCatalogRow>(findAvailableSql, [modelId, teamId]);
    return row === null ? null : entryFromRow(row);
  }
}

const saveEntrySql = `INSERT INTO model_catalog(
  id, title, description, tags_json, scope, team_id, runtime, artifact_reference_json, contract_json
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
ON CONFLICT(id) DO UPDATE SET
  title = excluded.title,
  description = excluded.description,
  tags_json = excluded.tags_json,
  scope = excluded.scope,
  team_id = excluded.team_id,
  runtime = excluded.runtime,
  artifact_reference_json = excluded.artifact_reference_json,
  contract_json = excluded.contract_json,
  updated_at = CURRENT_TIMESTAMP`;

const listAvailableSql = `SELECT id, title, description, tags_json, scope, team_id,
  runtime, artifact_reference_json, contract_json FROM model_catalog
  WHERE scope = 'system' OR (scope = 'team' AND team_id = ?)
  ORDER BY title COLLATE NOCASE, id`;

const findAvailableSql = `SELECT id, title, description, tags_json, scope, team_id,
  runtime, artifact_reference_json, contract_json FROM model_catalog
  WHERE id = ? AND (scope = 'system' OR (scope = 'team' AND team_id = ?))`;

function saveParameters(data: ReturnType<typeof modelCatalogEntryData>) {
  return [
    data.id,
    data.title,
    data.description,
    JSON.stringify(data.tags),
    data.scope,
    data.teamId,
    data.runtime,
    JSON.stringify(data.artifactReference),
    JSON.stringify(data.contract),
  ];
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
