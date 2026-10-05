import assert from "node:assert/strict";
import test from "node:test";
import {PluginNotFoundError} from "../../../plugins/domain/entities/stored-plugin.js";
import {PluginRunError, type PluginPrimitiveRun, type PluginRunner} from "../../../plugins/domain/repositories/plugin-runner.js";
import {type TaskRunContext} from "./node-executor.js";
import {createPluginNodeExecutor} from "./plugin-node-executor.js";

const node = {
  id: "n1", primitive: "plugin" as const, title: "Gruß", description: "", outputName: "gruss",
  config: {primitive: "plugin" as const, pluginId: "hallo", nodeType: "greet", settings: {name: "{{kunde}}", count: 2}},
};
const context = {templateExpressionResolver: {resolveText: (text: string) => text.replace("{{kunde}}", "Anna")}} as unknown as TaskRunContext;

test("löst Templates in Texteinstellungen auf und übernimmt die Ausgaben des Plugins", async () => {
  let received: PluginPrimitiveRun | undefined;
  const runner: PluginRunner = {runPrimitive: (run) => { received = run; return Promise.resolve({text: {type: "string", value: "Hallo Anna"}}); }};
  const result = await createPluginNodeExecutor(runner).execute(node, context);
  assert.equal(result.status, "executed");
  assert.deepEqual(received?.settings, {name: "Anna", count: 2});
  assert.deepEqual(result.outputs, {text: {type: "string", value: "Hallo Anna"}});
});

test("ein fehlendes Plugin überspringt den Baustein mit Hinweis statt die Aufgabe abzubrechen", async () => {
  const runner: PluginRunner = {runPrimitive: () => Promise.reject(new PluginNotFoundError("hallo"))};
  const result = await createPluginNodeExecutor(runner).execute(node, context);
  assert.equal(result.status, "skipped");
  assert.match(result.message ?? "", /nicht installiert/);
});

test("ohne Plugin-Laufzeit (Cloud) wird der Baustein übersprungen; Plugin-Fehler brechen ab", async () => {
  assert.equal((await createPluginNodeExecutor(undefined).execute(node, context)).status, "skipped");
  const runner: PluginRunner = {runPrimitive: () => Promise.reject(new PluginRunError("kaputt"))};
  await assert.rejects(() => createPluginNodeExecutor(runner).execute(node, context), /kaputt/);
});
