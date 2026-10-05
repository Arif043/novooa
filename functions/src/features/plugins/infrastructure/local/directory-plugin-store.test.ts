import assert from "node:assert/strict";
import {mkdtemp, readdir, rm} from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import {pluginPackageFrom} from "../../domain/entities/plugin-package.js";
import {PluginNotFoundError} from "../../domain/entities/stored-plugin.js";
import {DirectoryPluginStore} from "./directory-plugin-store.js";
import {FilePluginSettingsStore} from "./file-plugin-settings-store.js";

const pluginOf = (version: string) => pluginPackageFrom([
  {path: "plugin.json", bytes: new TextEncoder().encode(JSON.stringify({schemaVersion: 1, id: "hallo", version, name: "Hallo", description: "x"}))},
  {path: "backend/index.mjs", bytes: new TextEncoder().encode(`// ${version}`)},
]);

test("installieren, ersetzen, lesen und löschen", async () => {
  const root = await mkdtemp(path.join(os.tmpdir(), "plugins-"));
  try {
    const store = new DirectoryPluginStore(path.join(root, "plugins"));
    assert.deepEqual(await store.list(), []);
    await store.save(pluginOf("1.0.0"));
    assert.equal((await store.save(pluginOf("1.1.0"))).version, "1.1.0");
    assert.equal((await store.list()).length, 1);
    assert.deepEqual((await readdir(path.join(root, "plugins"))).sort(), ["hallo"]);
    assert.equal(new TextDecoder().decode((await store.readFiles("hallo")).find((file) => file.path === "backend/index.mjs")!.bytes), "// 1.1.0");
    await store.delete("hallo");
    await assert.rejects(() => store.delete("hallo"), PluginNotFoundError);
    await assert.rejects(() => store.readFiles("../etc"), PluginNotFoundError);
  } finally {
    await rm(root, {recursive: true, force: true});
  }
});

test("Einstellungen überleben ein Update und lassen sich löschen", async () => {
  const root = await mkdtemp(path.join(os.tmpdir(), "plugin-settings-"));
  try {
    const settings = new FilePluginSettingsStore(root);
    assert.deepEqual(await settings.read("hallo"), {});
    await settings.write("hallo", {a: "b", n: 1});
    assert.deepEqual(await settings.read("hallo"), {a: "b", n: 1});
    await settings.delete("hallo");
    assert.deepEqual(await settings.read("hallo"), {});
    await assert.rejects(() => settings.read("../x"), /Ungültige/);
  } finally {
    await rm(root, {recursive: true, force: true});
  }
});
