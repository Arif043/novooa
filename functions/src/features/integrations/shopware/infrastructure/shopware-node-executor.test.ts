import assert from "node:assert/strict";
import test from "node:test";
import {unusedGoogleTokens} from "../../integration-test-support.js";
import {genkit} from "genkit/beta";
import {type OutboundHttpClient, type OutboundHttpRequest} from "../../../connections/domain/repositories/outbound-http-client.js";
import {type TaskRunContext} from "../../../task_execution/domain/executors/node-executor.js";
import {taskDefinitionSchema} from "../../../task_execution/infrastructure/genkit/runner/task-definition.js";
import {createDefaultNodeExecutorRegistry} from "../../../task_execution/infrastructure/genkit/runner/node-executor-registry.js";
import {executeTaskGraph} from "../../../task_execution/infrastructure/genkit/runner/task-graph-runner.js";
import {registerIntegrationPlugins} from "../../index.js";
import {ShopwareActionRegistry} from "../domain/shopware-action.js";
import {createShopwareNodeExecutor} from "./shopware-node-executor.js";
import {succeeded} from "../../../task_execution/domain/executors/node-executor-test-support.js";

const silentLogger = {info() {}, error() {}, exception() {}, readableInfo() {}, readableError() {}};

const node = (config: Record<string, unknown>) =>
  ({id: "n1", primitive: "shopware", title: "Shopware", description: "", outputs: [{key: "value", name: "bestellungen", showOnCanvas: true}], config: {primitive: "shopware", ...config}}) as never;

function contextWith(client: OutboundHttpClient | undefined): TaskRunContext {
  return {
    teamId: "team-1", outboundHttpClient: client,
    templateExpressionResolver: {resolveText: (text: string) => text.replace("{{kunde}}", "Anna")},
  } as unknown as TaskRunContext;
}

const echoActions = () => new ShopwareActionRegistry().register({
  id: "echo",
  async execute({client, params, resolveText}) {
    const version = await client.version();
    return {value: {type: "string", value: `${resolveText(String(params.text))} (${version})`}, count: {type: "number", value: 1}};
  },
});

const versionClient = (sent: OutboundHttpRequest[] = []): OutboundHttpClient => ({
  send: (request) => {
    sent.push(request);
    return Promise.resolve({status: 200, headers: {}, body: '{"version":"6.6.10.2"}'});
  },
});

test("führt die gewählte Aktion mit Client, Parametern und Template-Auflösung aus", async () => {
  const sent: OutboundHttpRequest[] = [];
  const executor = createShopwareNodeExecutor(echoActions());

  const result = succeeded(await executor.execute(node({action: "echo", connectionId: "c1", params: {text: "Hallo {{kunde}}"}}), contextWith(versionClient(sent))));

  assert.deepEqual(result.outputs, {value: {type: "string", value: "Hallo Anna (6.6.10.2)"}, count: {type: "number", value: 1}});
  assert.equal(sent[0].connectionId, "c1");
  assert.equal(sent[0].teamId, "team-1");
});

test("meldet fehlende Voraussetzungen verständlich", async () => {
  const executor = createShopwareNodeExecutor(echoActions());

  await assert.rejects(() => executor.execute(node({action: "gibtEsNicht", connectionId: "c1", params: {}}), contextWith(versionClient())), /Aktion „gibtEsNicht“ ist unbekannt/);
  await assert.rejects(() => executor.execute(node({action: "echo", params: {}}), contextWith(versionClient())), /Verbindung zu deinem Shopware-Shop/);
  await assert.rejects(() => executor.execute(node({action: "echo", connectionId: "", params: {}}), contextWith(versionClient())), /Verbindung zu deinem Shopware-Shop/);
  await assert.rejects(() => executor.execute(node({action: "echo", connectionId: "c1", params: {}}), contextWith(undefined)), /nicht verfügbar/);
});

test("das Zod-Schema füllt Standardwerte und lehnt fehlende Aktionen ab", () => {
  const parse = (config: unknown) => taskDefinitionSchema.parse({
    id: "t", title: "T", nodes: [{id: "n", primitive: "shopware", title: "S", config}],
  }).nodes[0].config;

  assert.deepEqual(parse({primitive: "shopware", action: "searchOrders"}), {primitive: "shopware", action: "searchOrders", params: {}});
  assert.deepEqual(parse({primitive: "shopware", action: "x", connectionId: "c", params: {limit: 5}}), {primitive: "shopware", action: "x", connectionId: "c", params: {limit: 5}});
  assert.throws(() => parse({primitive: "shopware"}));
  assert.throws(() => parse({primitive: "shopware", action: ""}));
});

test("die Plugin-Executoren werden über die Registry im echten Runner ausgeführt, die eingebauten bleiben", async () => {
  const registry = registerIntegrationPlugins(createDefaultNodeExecutorRegistry(), {googleAccessTokens: unusedGoogleTokens});
  assert.equal(registry.resolve("shopware", {} as never)?.primitive, "shopware");
  assert.equal(registry.resolve("stringInput", {} as never)?.primitive, "stringInput");

  const taskDefinition = taskDefinitionSchema.parse({
    id: "t", title: "T", nodes: [{id: "n", primitive: "shopware", title: "S", outputs: [{key: "value", name: "s", showOnCanvas: true}], config: {primitive: "shopware", action: "gibtEsNicht", connectionId: "c1"}}],
  });
  const output = await executeTaskGraph(genkit({}), {taskDefinition, context: "", teamId: "team-1"}, {
    logger: silentLogger, outboundHttpClient: versionClient(), executorRegistry: registry,
  } as never);

  assert.equal(output.isErr(), true);
  assert.match(output._unsafeUnwrapErr().failedNode.message, /Aktion „gibtEsNicht“ ist unbekannt/);
});

test("ohne Plugin-Registry (Cloud) wird der Shopware-Baustein übersprungen statt auszuführen", async () => {
  const taskDefinition = taskDefinitionSchema.parse({
    id: "t", title: "T", nodes: [{id: "n", primitive: "shopware", title: "S", outputs: [{key: "value", name: "s", showOnCanvas: true}], config: {primitive: "shopware", action: "x", connectionId: "c1"}}],
  });
  const output = await executeTaskGraph(genkit({}), {taskDefinition, context: "", teamId: "team-1"}, {logger: silentLogger} as never);

  assert.equal(output.isOk(), true);
  assert.equal(JSON.stringify(output._unsafeUnwrap()).includes("unbekannt"), false);
});
