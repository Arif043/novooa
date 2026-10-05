import assert from "node:assert/strict";
import {mkdir, mkdtemp, rm, writeFile} from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import {PluginNotFoundError} from "../../domain/entities/stored-plugin.js";
import {PluginRunError} from "../../domain/repositories/plugin-runner.js";
import {pluginPackageFrom} from "../../domain/entities/plugin-package.js";
import {DirectoryPluginStore} from "./directory-plugin-store.js";
import {FilePluginSettingsStore} from "./file-plugin-settings-store.js";
import {ProcessPluginRunner, triggerResult} from "./process-plugin-runner.js";

const manifest = {
  schemaVersion: 1, id: "hallo", version: "1.0.0", name: "Hallo", description: "x",
  primitives: ["greet", "slow", "boom", "spy", "wrong"].map((type) => ({
    type, label: type, description: "", settings: [{key: "name", label: "Name", kind: "text"}],
    outputs: [{name: "text", label: "Text", type: "string"}],
  })),
  triggers: [{type: "tick", label: "Tick", description: "", settings: []}, {type: "boom", label: "Boom", description: "", settings: []}],
  settingsPanels: [{id: "main", title: "Hallo", fields: [{key: "greeting", label: "Gruß", kind: "text"}]}],
};

const entry = `
import {readFileSync} from "node:fs";
export default {triggers: {
  tick: ({state}) => ({events: [{context: "Tick " + ((state ?? 0) + 1), data: {n: (state ?? 0) + 1}}], state: (state ?? 0) + 1}),
  boom: () => ({events: "keine Liste"}),
}, primitives: {
  greet: ({settings, panel}) => ({text: panel.greeting + ", " + settings.name}),
  slow: () => new Promise(() => setInterval(() => {}, 1000)),
  boom: () => { throw new Error("kaputt"); },
  wrong: () => ({text: 42}),
  spy: async () => {
    const result = {};
    const actions = {
      write: () => writeFileSync("/tmp/plugin-spy-write", "x"),
      spawn: async () => (await import("node:child_process")).execSync("echo hi"),
      env: () => { if (Object.keys(process.env).length > 0) throw new Error("env leak"); },
    };
    for (const [key, action] of Object.entries(actions)) {
      try { await action(); result[key] = "erlaubt"; } catch (error) { result[key] = "blockiert:" + error.code; }
    }
    return {text: JSON.stringify(result)};
  },
}};
`.replace('import {readFileSync} from "node:fs";', 'import {writeFileSync} from "node:fs";');

async function setup() {
  const root = await mkdtemp(path.join(os.tmpdir(), "plugin-run-"));
  const directory = path.join(root, "plugins");
  const store = new DirectoryPluginStore(directory);
  await store.save(pluginPackageFrom([
    {path: "plugin.json", bytes: new TextEncoder().encode(JSON.stringify(manifest))},
    {path: "backend/index.mjs", bytes: new TextEncoder().encode(entry)},
  ]));
  const settings = new FilePluginSettingsStore(path.join(root, "settings"));
  await mkdir(path.join(root, "settings"), {recursive: true});
  await writeFile(path.join(root, "settings", "hallo.json"), JSON.stringify({greeting: "Moin"}));
  return {root, runner: new ProcessPluginRunner(store, settings, directory, {timeoutMilliseconds: 1500})};
}

test("führt einen Plugin-Baustein aus und typisiert die Ausgabe", async () => {
  const {root, runner} = await setup();
  try {
    assert.deepEqual(await runner.runPrimitive({pluginId: "hallo", nodeType: "greet", settings: {name: "Welt"}}), {text: {type: "string", value: "Moin, Welt"}});
  } finally {
    await rm(root, {recursive: true, force: true});
  }
});

test("Fehler, Zeitüberschreitung und falsche Typen werden als PluginRunError gemeldet", async () => {
  const {root, runner} = await setup();
  try {
    await assert.rejects(() => runner.runPrimitive({pluginId: "hallo", nodeType: "boom", settings: {}}), /kaputt/);
    await assert.rejects(() => runner.runPrimitive({pluginId: "hallo", nodeType: "slow", settings: {}}), /nicht innerhalb/);
    await assert.rejects(() => runner.runPrimitive({pluginId: "hallo", nodeType: "wrong", settings: {}}), PluginRunError);
    await assert.rejects(() => runner.runPrimitive({pluginId: "hallo", nodeType: "unbekannt", settings: {}}), /kennt den Baustein/);
    await assert.rejects(() => runner.runPrimitive({pluginId: "fehlt", nodeType: "greet", settings: {}}), PluginNotFoundError);
  } finally {
    await rm(root, {recursive: true, force: true});
  }
});

test("der Plugin-Prozess darf weder schreiben noch Prozesse starten noch die Umgebung sehen", async () => {
  const {root, runner} = await setup();
  try {
    const result = await runner.runPrimitive({pluginId: "hallo", nodeType: "spy", settings: {}});
    const report = JSON.parse((result.text as {value: string}).value) as Record<string, string>;
    assert.match(report.write ?? "", /^blockiert:ERR_ACCESS_DENIED/);
    assert.match(report.spawn ?? "", /^blockiert:ERR_ACCESS_DENIED/);
    assert.equal(report.env, "erlaubt");
  } finally {
    await rm(root, {recursive: true, force: true});
  }
});

test("ein Trigger meldet Ereignisse und übergibt seinen Zustand an den nächsten Aufruf", async () => {
  const {root, runner} = await setup();
  try {
    const first = await runner.pollTrigger({pluginId: "hallo", triggerType: "tick", settings: {}, state: undefined});
    assert.deepEqual(first, {events: [{context: "Tick 1", data: {n: 1}}], state: 1});

    const second = await runner.pollTrigger({pluginId: "hallo", triggerType: "tick", settings: {}, state: first.state});
    assert.deepEqual(second.events, [{context: "Tick 2", data: {n: 2}}]);
  } finally {
    await rm(root, {recursive: true, force: true});
  }
});

test("Trigger mit ungültiger Antwort, unbekannte Trigger und fehlende Plugins werden gemeldet", async () => {
  const {root, runner} = await setup();
  try {
    await assert.rejects(() => runner.pollTrigger({pluginId: "hallo", triggerType: "boom", settings: {}, state: undefined}), /events als Liste/);
    await assert.rejects(() => runner.pollTrigger({pluginId: "hallo", triggerType: "unbekannt", settings: {}, state: undefined}), /kennt den Trigger/);
    await assert.rejects(() => runner.pollTrigger({pluginId: "fehlt", triggerType: "tick", settings: {}, state: undefined}), PluginNotFoundError);
  } finally {
    await rm(root, {recursive: true, force: true});
  }
});

test("die Antwort eines Triggers wird geprüft und begrenzt", () => {
  assert.deepEqual(triggerResult(undefined, 7, "X"), {events: [], state: 7});
  assert.deepEqual(triggerResult({events: [{}]}, 7, "X"), {events: [{context: "Ereignis von X", data: {}}], state: 7});
  assert.throws(() => triggerResult("text", 0, "X"), /Objekt/);
  assert.throws(() => triggerResult({events: ["x"]}, 0, "X"), /muss ein Objekt sein/);
  assert.throws(() => triggerResult({events: [{data: []}]}, 0, "X"), /müssen ein Objekt sein/);
  assert.throws(() => triggerResult({events: Array.from({length: 51}, () => ({}))}, 0, "X"), /mehr als 50/);
  assert.throws(() => triggerResult({events: [], state: "x".repeat(200_000)}, 0, "X"), /zu groß/);
});
