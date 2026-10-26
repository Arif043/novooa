import assert from "node:assert/strict";
import test from "node:test";
import {testingRoutes} from "../../../../shared/local/local-runtime-http-test-support.js";
import {requiresAdmin} from "../../../../shared/local/local-runtime-role-policy.js";
import {type PluginActivationStore} from "../../domain/repositories/plugin-activation-store.js";
import {ListPlugins, SetPluginEnabled} from "../../domain/usecases/plugin-usecases.js";
import {pluginRoutes} from "./local-plugin-routes.js";

function routes() {
  const enabled = new Map<string, string>();
  const published: string[] = [];
  const store: PluginActivationStore = {
    enabledPlugins: async () => enabled,
    isEnabled: async (_team, id) => enabled.has(id),
    enable: async (_team, id) => { enabled.set(id, "2026-10-26T10:00:00.000Z"); },
    disable: async (_team, id) => { enabled.delete(id); },
  };
  const catalog = ["shopware", "googleDrive"];
  const handler = testingRoutes(pluginRoutes, {
    list: new ListPlugins(catalog, store), setEnabled: new SetPluginEnabled(catalog, store),
    notifier: {publish: (topic: string) => published.push(topic)},
  });
  return {handler, published};
}

test("lists every plugin with its state and switches one on", async () => {
  const {handler, published} = routes();

  const switched = await handler.handle({method: "PUT", url: "/v1/plugins/googleDrive", body: {enabled: true}});
  const listed = await handler.handle({method: "GET", url: "/v1/plugins", body: undefined});

  assert.deepEqual(switched, {statusCode: 200, body: {id: "googleDrive", enabled: true, enabledAt: "2026-10-26T10:00:00.000Z"}});
  assert.deepEqual(listed?.body, {items: [
    {id: "shopware", enabled: false, enabledAt: null},
    {id: "googleDrive", enabled: true, enabledAt: "2026-10-26T10:00:00.000Z"},
  ]});
  assert.deepEqual(published, ["plugins"]);
});

test("an unknown plugin answers 404 and publishes nothing", async () => {
  const {handler, published} = routes();

  const response = await handler.handle({method: "PUT", url: "/v1/plugins/fremd", body: {enabled: true}});

  assert.equal(response?.statusCode, 404);
  assert.equal((response?.body as {code?: string}).code, "plugin_not_found");
  assert.deepEqual(published, []);
});

test("members read plugins, only admins switch them", () => {
  assert.equal(requiresAdmin("GET", "/v1/plugins"), false);
  assert.equal(requiresAdmin("PUT", "/v1/plugins/googleDrive"), true);
});
