import Fastify from "fastify";
import {configureValidation} from "../../../../shared/local/local-runtime-validation.js";
import {registerWorkspaceContext} from "../../../../shared/local/local-runtime-workspace-context.js";
import assert from "node:assert/strict";
import {createReadStream} from "node:fs";
import path from "node:path";
import test, {type TestContext} from "node:test";
import {runtimeTestDatabase} from "../../../../db/runtime-database-test-support.js";
import {testingRoutes, testWorkspace} from "../../../../shared/local/local-runtime-http-test-support.js";
import {workspaceTransferRoutes} from "./local-workspace-transfer-routes.js";
import {exportArchive, seedWorkspace, temporaryDirectory} from "./workspace-transfer-test-support.js";
import {workspaceTransferRoutesOptions} from "./workspace-transfer-composition.js";

async function transferHandler(t: TestContext) {
  const database = await runtimeTestDatabase(t);
  const runtimeRoot = await temporaryDirectory(t);
  await seedWorkspace(database, runtimeRoot);
  const published: string[] = [];
  const options = workspaceTransferRoutesOptions({database, runtimeRoot, notifier: {publish: (topic) => published.push(topic)}});
  return {database, runtimeRoot, options, published, routes: testingRoutes(workspaceTransferRoutes, options)};
}

test("streams a zip archive for the selected categories", async (t) => {
  const {options} = await transferHandler(t);
  const http = Fastify();
  configureValidation(http);
  registerWorkspaceContext(http, () => testWorkspace());
  await http.register(workspaceTransferRoutes, options);
  t.after(() => http.close());
  const response = await http.inject({method: "POST", url: "/v1/transfer/export", payload: {categories: ["files", "tasks"]}});
  assert.equal(response.statusCode, 200);
  assert.equal(response.headers["content-type"], "application/zip");
  assert.match(String(response.headers["content-disposition"]), /novooa-export-\d{4}-\d{2}-\d{2}\.zip/);
  assert.equal(response.rawPayload.subarray(0, 2).toString(), "PK");
});

test("rejects an export without a valid selection", async (t) => {
  const {routes} = await transferHandler(t);
  const response = await routes.handle({method: "POST", url: "/v1/transfer/export", body: {categories: ["triggers"]}});
  assert.equal(response?.statusCode, 400);
});

test("rejects an import upload that is not a zip file", async (t) => {
  const {routes} = await transferHandler(t);
  const response = await routes.handle({method: "POST", url: "/v1/transfer/imports", body: {}});
  assert.equal(response?.statusCode, 415);
});

test("rejects an uploaded zip that is not a novooa export", async (t) => {
  const {routes} = await transferHandler(t);
  const response = await routes.handleStream({method: "POST", url: "/v1/transfer/imports",
    headers: {"content-type": "application/zip"}, body: chunks(Buffer.from("kein zip"))});
  assert.equal(response?.statusCode, 422);
});

test("stages an import, shows its manifest and applies the selected categories", async (t) => {
  const {database, runtimeRoot, routes, published} = await transferHandler(t);
  const archivePath = path.join(await temporaryDirectory(t), "export.zip");
  await exportArchive(database, runtimeRoot, ["knowledge", "tasks"], archivePath);
  const staged = await routes.handleStream({method: "POST", url: "/v1/transfer/imports",
    headers: {"content-type": "application/zip"}, body: createReadStream(archivePath)});
  assert.equal(staged?.statusCode, 201);
  const {importId, manifest} = staged?.body as {importId: string; manifest: {counts: object}};
  assert.deepEqual(manifest.counts, {knowledge: 1, tasks: 1});
  const applied = await routes.handle({method: "POST", url: `/v1/transfer/imports/${importId}/apply`,
    body: {categories: ["knowledge"]}});
  assert.equal(applied?.statusCode, 200);
  assert.deepEqual(applied?.body, {imported: {knowledge: 1}});
  assert.deepEqual(published, ["knowledge-notes"]);
});

test("reports an unknown or already applied import as expired", async (t) => {
  const {routes} = await transferHandler(t);
  const response = await routes.handle({method: "POST", url: "/v1/transfer/imports/unbekannt/apply",
    body: {categories: ["files"]}});
  assert.equal(response?.statusCode, 404);
});

async function* chunks(content: Uint8Array): AsyncIterable<Uint8Array> {
  yield content;
}
