import assert from "node:assert/strict";
import test from "node:test";
import {type LocalSqlDatabase, type SqlRow} from "../../../../shared/local/local-sql-database.js";
import {SQLiteModelCatalog} from "./sqlite-model-catalog.js";

test("lists system and team models available to a team", async () => {
  const database = databaseWith([modelRow("system", null), modelRow("team", "team-1")]);
  const catalog = new SQLiteModelCatalog(database);

  const entries = await catalog.listAvailableFor("team-1");

  assert.deepEqual(entries.map((entry) => entry.scope.type), ["system", "team"]);
  assert.deepEqual(database.parameters, [["team-1"]]);
});

test("writes logical artifacts instead of physical storage paths", async () => {
  const database = databaseWith([]);
  const catalog = new SQLiteModelCatalog(database);

  await catalog.save(modelEntry());

  const serializedArtifact = database.writeParameters[0]?.[7] ?? "";
  assert.equal(String(serializedArtifact).includes("artifact-1"), true);
  assert.equal(String(serializedArtifact).includes("storagePath"), false);
});

function databaseWith(rows: SqlRow[]): RecordingDatabase {
  return new RecordingDatabase(rows);
}

class RecordingDatabase implements LocalSqlDatabase {
  parameters: ReadonlyArray<readonly (string | number | null)[]> = [];
  writeParameters: ReadonlyArray<readonly (string | number | null)[]> = [];

  constructor(private readonly rows: SqlRow[]) {}

  async get<T extends SqlRow>(): Promise<T | null> {
    return null;
  }

  async all<T extends SqlRow>(
    _sql: string,
    parameters: readonly (string | number | null)[] = [],
  ): Promise<T[]> {
    this.parameters = [...this.parameters, parameters];
    return this.rows as T[];
  }

  async run(
    _sql: string,
    parameters: readonly (string | number | null)[] = [],
  ): Promise<void> {
    this.writeParameters = [...this.writeParameters, parameters];
  }

  async transaction<T>(operation: () => Promise<T>): Promise<T> {
    return operation();
  }
}

function modelRow(scope: "system" | "team", teamId: string | null): SqlRow {
  return {
    id: `${scope}-model`,
    title: `${scope} model`,
    description: "Ein Testmodell.",
    tags_json: "[\"bild\"]",
    scope,
    team_id: teamId,
    runtime: "onnx",
    artifact_reference_json: JSON.stringify(artifact()),
    contract_json: JSON.stringify(contract()),
  };
}

function modelEntry() {
  return {
    id: "system-model",
    title: "Systemmodell",
    description: "Ein Testmodell.",
    tags: ["bild"],
    scope: {type: "system" as const},
    runtime: "onnx" as const,
    artifactReference: artifact(),
    contract: contract(),
  };
}

function artifact() {
  return {
    artifactId: "artifact-1",
    versionId: "version-1",
    format: "onnx" as const,
    contentType: "application/onnx",
    sizeBytes: 128,
    sha256: "b".repeat(64),
  };
}

function contract() {
  return {
    inputs: [{
      name: "input",
      source: "image" as const,
      dataType: "float32" as const,
      shape: ["dynamic" as const, 3, 16, 16],
      preprocessing: [],
    }],
    outputs: [{
      name: "output",
      dataType: "float32" as const,
      shape: ["dynamic" as const, 2],
      semantic: "classification.scores",
      postprocessing: [],
    }],
  };
}
