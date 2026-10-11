import assert from "node:assert/strict";
import {mkdtemp, readFile, rm} from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import {testingRoutes} from "../../../../shared/local/local-runtime-http-test-support.js";
import {LocalRuntimeRealtimeNotifier} from "../../../../shared/local/local-runtime-realtime-notifier.js";
import {type ModelCatalogEntry} from "../../domain/entities/model-catalog-entry.js";
import {type TeamModelCatalog} from "../../domain/repositories/model-catalog.js";
import {LocalModelArtifactPublisher} from "./local-model-artifact-publisher.js";
import {type FreeBytes, LocalModelArtifactUploadStore} from "./local-model-artifact-upload-store.js";
import {modelCatalogRoutes} from "./local-model-catalog-routes.js";

test("installs a model with its weight file next to it and records both", async () => {
  await withRoutes(undefined, async ({handler, catalog, directory}) => {
    const importId = await createImport(handler);
    const weights = await put(handler, `/v1/ml-models/imports/${importId}/external-data/model.onnx.data`, "weights");
    const installed = await put(handler, `/v1/ml-models/imports/${importId}/artifact`, "onnx");

    assert.equal(weights?.statusCode, 201);
    assert.equal(installed?.statusCode, 201);
    assert.equal(catalog.entries[0]?.origin, "import");
    assert.deepEqual(catalog.entries[0]?.artifactReference.externalData?.map((file) => [file.name, file.sizeBytes]), [["model.onnx.data", 7]]);
    const version = path.join(directory, "model-artifacts/example-model/versions/1");
    assert.equal(await readFile(path.join(version, "model.onnx.data"), "utf8"), "weights");
    await assert.rejects(readFile(path.join(directory, "model-imports", importId, "model.onnx")));
  });
});

test("rejects a weight file named like the model", async () => {
  await withRoutes(undefined, async ({handler}) => {
    const importId = await createImport(handler);

    const response = await put(handler, `/v1/ml-models/imports/${importId}/external-data/model.onnx`, "weights");

    assert.equal(response?.statusCode, 400);
  });
});

test("refuses an upload larger than the free space before writing it", async () => {
  await withRoutes(async () => 1, async ({handler}) => {
    const importId = await createImport(handler);

    const response = await put(handler, `/v1/ml-models/imports/${importId}/artifact`, "onnx");

    assert.equal(response?.statusCode, 400);
    assert.deepEqual(response?.body, {error: "Für diese Modelldatei ist nicht genug Speicherplatz frei."});
  });
});

type Routes = {handler: ReturnType<typeof testingRoutes>; catalog: Catalog; directory: string};

async function withRoutes(freeBytes: FreeBytes | undefined, action: (routes: Routes) => Promise<void>): Promise<void> {
  const directory = await mkdtemp(path.join(os.tmpdir(), "novooa-model-import-"));
  const catalog = new Catalog();
  const handler = testingRoutes(modelCatalogRoutes, {
    catalog, artifactPublisher: new LocalModelArtifactPublisher(directory),
    uploadStore: new LocalModelArtifactUploadStore(directory, null, freeBytes),
    contractValidator: {validate: async () => undefined}, notifier: new LocalRuntimeRealtimeNotifier(),
  }, {teamId: "team-1"});
  try {
    await action({handler, catalog, directory});
  } finally {
    await rm(directory, {recursive: true, force: true});
  }
}

async function createImport(handler: ReturnType<typeof testingRoutes>): Promise<string> {
  const response = await handler.handle({method: "POST", url: "/v1/ml-models/imports", body: {manifest: manifest()}});
  return (response?.body as {importId: string}).importId;
}

function put(handler: ReturnType<typeof testingRoutes>, url: string, content: string) {
  return handler.handleStream({
    method: "PUT", url, headers: {"content-type": "application/onnx", "content-length": String(content.length)},
    body: (async function* () { yield Buffer.from(content); })(),
  });
}

class Catalog implements TeamModelCatalog {
  entries: ModelCatalogEntry[] = [];
  async save(entry: ModelCatalogEntry): Promise<void> { this.entries = [...this.entries.filter((item) => item.id !== entry.id), entry]; }
  async listAvailableFor(): Promise<readonly ModelCatalogEntry[]> { return this.entries; }
  async findAvailableFor(_teamId: string, modelId: string): Promise<ModelCatalogEntry | null> {
    return this.entries.find((entry) => entry.id === modelId) ?? null;
  }
  async removeTeamEntry(): Promise<boolean> { return false; }
}

function manifest() {
  return {
    id: "example-model", title: "Beispielmodell", description: "Ein lokales Testmodell.", task: "image-classification",
    languages: [], tags: ["test"], artifact: {artifactId: "example-model", versionId: "1"},
    contract: {
      inputs: [{name: "input", source: "tensor", dataType: "uint8", shape: [1], transformations: []}],
      outputs: [{name: "output", dataType: "uint8", shape: [1], semantic: "classification.scores", transformations: [], workflowOutput: {name: "value", type: "json", mapping: "$tensor"}}],
    },
  };
}
