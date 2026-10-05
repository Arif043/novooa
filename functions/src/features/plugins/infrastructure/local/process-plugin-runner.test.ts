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
import {ProcessPluginRunner} from "./process-plugin-runner.js";

const manifest = {
  schemaVersion: 1, id: "hallo", version: "1.0.0", name: "Hallo", description: "x",
  primitives: ["greet", "slow", "boom", "spy", "wrong"].map((type) => ({
    type, label: type, description: "", settings: [{key: "name", label: "Name", kind: "text"}],
    outputs: [{name: "text", label: "Text", type: "string"}],
  })),
  settingsPanels: [{id: "main", title: "Hallo", fields: [{key: "greeting", label: "Gruß", kind: "text"}]}],
};

const entry = `
import {readFileSync} from "node:fs";
export default {primitives: {
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
