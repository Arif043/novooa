import assert from "node:assert/strict";
import test from "node:test";
import {genkit} from "genkit/beta";
import {type PluginRunner} from "../../../../plugins/domain/repositories/plugin-runner.js";
import {taskDefinitionSchema} from "./task-definition.js";
import {executeTaskGraph} from "./task-graph-runner.js";

const silentLogger = {info() {}, error() {}, exception() {}, readableInfo() {}, readableError() {}};

const pluginNode = {
  id: "gruss", primitive: "plugin", title: "Gruß", description: "", outputName: "gruss",
  config: {primitive: "plugin", pluginId: "hallo", nodeType: "greet", settings: {name: "{{ereignis.kunde}}", times: 2}},
};

function taskWith(input: Record<string, unknown> | undefined) {
  return {
    taskDefinition: {id: "task-1", title: "Aufgabe", objective: "", nodes: [pluginNode], edges: []},
    context: "", teamId: "team-1", ...(input === undefined ? {} : {input}),
  } as never;
}

test("die Aufgabendefinition kennt den Plugin-Baustein", () => {
  const parsed = taskDefinitionSchema.parse({id: "t", title: "T", objective: "", nodes: [pluginNode], edges: []});
  assert.deepEqual(parsed.nodes[0]?.config, pluginNode.config);
  assert.throws(() => taskDefinitionSchema.parse({
    id: "t", title: "T", objective: "", edges: [],
    nodes: [{...pluginNode, config: {primitive: "plugin", pluginId: "", nodeType: "greet"}}],
  }));
});

test("ein Plugin-Ereignis liefert seine Daten als {{ereignis.feld}} in die Einstellungen des Bausteins", async () => {
  const received: unknown[] = [];
  const pluginRunner: PluginRunner = {
    runPrimitive: (run) => { received.push(run.settings); return Promise.resolve({value: {type: "string", value: "Hallo"}}); },
  };

  const result = await executeTaskGraph(
    genkit({}),
    taskWith({event: {source: "plugin", pluginId: "hallo", type: "tick", data: {kunde: "Anna"}}}),
    {logger: silentLogger, pluginRunner} as never,
  );

  assert.equal(result.isOk(), true);
  assert.deepEqual(received, [{name: "Anna", times: 2}]);
});

test("ohne Ereignis bleibt der Ausdruck unaufgelöst und ein fehlendes Plugin-Laufzeit überspringt den Baustein", async () => {
  const received: unknown[] = [];
  const pluginRunner: PluginRunner = {
    runPrimitive: (run) => { received.push(run.settings); return Promise.resolve({}); },
  };

  await executeTaskGraph(genkit({}), taskWith(undefined), {logger: silentLogger, pluginRunner} as never);
  assert.deepEqual(received, [{name: "{{ereignis.kunde}}", times: 2}]);

  const skipped = await executeTaskGraph(genkit({}), taskWith(undefined), {logger: silentLogger} as never);
  assert.equal(skipped.isOk(), true);
});
