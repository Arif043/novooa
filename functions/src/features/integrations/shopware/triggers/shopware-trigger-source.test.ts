import assert from "node:assert/strict";
import test from "node:test";
import {unusedGoogleTokens} from "../../integration-test-support.js";
import {EventTriggerSourceRegistry} from "../../../scheduling/domain/entities/event-trigger-source-registry.js";
import {createDefaultNodeExecutorRegistry} from "../../../task_execution/infrastructure/genkit/runner/node-executor-registry.js";
import {integrationWebhookInterpreters, registerIntegrationPlugins} from "../../index.js";
import {shopwarePlugin} from "../shopware-plugin.js";

test("das Plugin meldet die Quelle „shopware“ an; der Server vergibt das Token und verlangt keine Signatur", () => {
  const sources = new EventTriggerSourceRegistry();
  registerIntegrationPlugins(createDefaultNodeExecutorRegistry(), {googleAccessTokens: unusedGoogleTokens}, [shopwarePlugin], sources);

  assert.equal(sources.has("shopware"), true);
  assert.equal(sources.usesWebhook("shopware"), true);
  const config = {source: "shopware", target: {kind: "any" as const}, fileKinds: [], filter: "", params: {event: "stockLow", connectionId: "c1", threshold: 4, fremd: 1}};
  assert.equal(sources.problem(config), null);
  assert.match(sources.problem({...config, params: {event: "stockLow"}}) ?? "", /Verbindung/);
  const prepared = sources.prepare({...config, webhook: {token: "vom-client", verification: {kind: "none"}, validationParameter: ""}});
  assert.notEqual(prepared.webhook?.token, "vom-client");
  assert.ok((prepared.webhook?.token.length ?? 0) >= 40);
  assert.deepEqual(prepared.webhook?.verification, {kind: "none"});
  assert.equal(prepared.params?.fremd, undefined);
  assert.equal(prepared.params?.threshold, 4);
});

test("der Interpreter ist unter der Quelle abrufbar", () => {
  const interpreters = integrationWebhookInterpreters({send: () => Promise.reject(new Error("nicht gebraucht"))}, [shopwarePlugin]);

  assert.deepEqual([...interpreters.keys()], ["shopware"]);
});
