import assert from "node:assert/strict";
import {generateKeyPairSync, sign, type KeyObject} from "node:crypto";
import {mkdtemp, rm} from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import {zipSync} from "fflate";
import {testingRoutes} from "../../../../shared/local/local-runtime-http-test-support.js";
import {pluginDigest, pluginSignatureFile, type PluginFile} from "../../domain/entities/plugin-package.js";
import {PluginCatalogError} from "../../domain/entities/plugin-catalog.js";
import {type PluginCatalog} from "../../domain/repositories/plugin-catalog.js";
import {createPluginsModule} from "./plugins-composition.js";
import {pluginRoutes} from "./local-plugin-routes.js";
import {ProcessPluginRunner} from "./process-plugin-runner.js";
import {createPluginSettingsStore, createPluginStore, pluginsDirectoryFor} from "./plugins-composition.js";

const manifest = {
  schemaVersion: 1, id: "hallo", version: "1.0.0", name: "Hallo-Plugin", description: "grüßt",
  primitives: [{type: "greet", label: "Begrüßen", description: "", settings: [{key: "name", label: "Name", kind: "template"}], outputs: [{name: "text", label: "Gruß", type: "string"}]}],
  settingsPanels: [{id: "main", title: "Hallo", fields: [{key: "greeting", label: "Gruß", kind: "text", defaultValue: "Hallo"}, {key: "apiKey", label: "Schlüssel", kind: "text", secret: true}]}],
};
const text = (value: string) => new TextEncoder().encode(value);

function packageZip(privateKey: KeyObject | undefined, version = "1.0.0"): Buffer {
  const files: PluginFile[] = [
    {path: "plugin.json", bytes: text(JSON.stringify({...manifest, version}))},
    {path: "backend/index.mjs", bytes: text("export default {primitives: {greet: ({settings, panel}) => ({text: `${panel.greeting ?? 'Hallo'}, ${settings.name}!`})}};")},
  ];
  if (privateKey) files.push({path: pluginSignatureFile, bytes: sign(null, pluginDigest(files), privateKey)});
  return Buffer.from(zipSync(Object.fromEntries(files.map((file) => [file.path, file.bytes]))));
}

const zipHeaders = {"content-type": "application/zip"};
type Created = {installId: string; manifest: {name: string}; installedVersion?: string};

test("Installation per ZIP: Vorschau, Bestätigen, Einstellungen, Ausführen, Deinstallieren", async () => {
  const root = await mkdtemp(path.join(os.tmpdir(), "plugin-routes-"));
  const {privateKey, publicKey} = generateKeyPairSync("ed25519");
  const original = process.env.NOVOOA_PLUGIN_PUBLIC_KEY;
  process.env.NOVOOA_PLUGIN_PUBLIC_KEY = publicKey.export({type: "spki", format: "pem"}).toString();
  try {
    const published: string[] = [];
    const routes = testingRoutes(pluginRoutes, createPluginsModule(root, {publish: (topic) => { published.push(topic); }}, () => null));

    const unsigned = await routes.handle({method: "POST", url: "/v1/plugins/installs/archive", body: {}, headers: zipHeaders}, packageZip(undefined));
    assert.equal(unsigned?.statusCode, 400);
    assert.match((unsigned?.body as {error: string}).error, /Signatur/);

    const preview = await routes.handle({method: "POST", url: "/v1/plugins/installs/archive", body: {}, headers: zipHeaders}, packageZip(privateKey));
    assert.equal(preview?.statusCode, 201);
    const created = preview?.body as Created;
    assert.equal(created.manifest.name, "Hallo-Plugin");
    assert.deepEqual((await routes.handle({url: "/v1/plugins", body: {}}))?.body, {items: []});

    const committed = await routes.handle({method: "POST", url: `/v1/plugins/installs/${created.installId}/commit`, body: {}});
    assert.equal(committed?.statusCode, 201);
    assert.equal(((await routes.handle({url: "/v1/plugins", body: {}}))?.body as {items: unknown[]}).items.length, 1);
    assert.deepEqual(published, ["plugins"]);

    const update = await routes.handle({method: "POST", url: "/v1/plugins/installs/archive", body: {}, headers: zipHeaders}, packageZip(privateKey, "1.1.0"));
    assert.equal((update?.body as Created).installedVersion, "1.0.0");

    const saved = await routes.handle({method: "PUT", url: "/v1/plugins/hallo/settings", body: {values: {greeting: "Moin", apiKey: "geheim"}}});
    assert.equal(saved?.statusCode, 200);
    assert.deepEqual((await routes.handle({url: "/v1/plugins/hallo/settings", body: {}}))?.body, {values: {greeting: "Moin"}, secretsSet: ["apiKey"]});
    assert.equal((await routes.handle({method: "PUT", url: "/v1/plugins/hallo/settings", body: {values: {fremd: "x"}}}))?.statusCode, 400);

    const runner = new ProcessPluginRunner(createPluginStore(root), createPluginSettingsStore(root), pluginsDirectoryFor(root));
    assert.deepEqual(await runner.runPrimitive({pluginId: "hallo", nodeType: "greet", settings: {name: "Welt"}}), {text: {type: "string", value: "Moin, Welt!"}});

    assert.equal((await routes.handle({method: "DELETE", url: "/v1/plugins/hallo", body: {}}))?.statusCode, 200);
    assert.equal((await routes.handle({method: "DELETE", url: "/v1/plugins/hallo", body: {}}))?.statusCode, 404);
    assert.equal((await routes.handle({url: "/v1/plugins/hallo/settings", body: {}}))?.statusCode, 404);
  } finally {
    if (original === undefined) delete process.env.NOVOOA_PLUGIN_PUBLIC_KEY;
    else process.env.NOVOOA_PLUGIN_PUBLIC_KEY = original;
    await rm(root, {recursive: true, force: true});
  }
});

test("Katalog: ohne Relay 503, sonst Liste und Installation aus dem Katalog", async () => {
  const root = await mkdtemp(path.join(os.tmpdir(), "plugin-catalog-"));
  const {privateKey, publicKey} = generateKeyPairSync("ed25519");
  const original = process.env.NOVOOA_PLUGIN_PUBLIC_KEY;
  process.env.NOVOOA_PLUGIN_PUBLIC_KEY = publicKey.export({type: "spki", format: "pem"}).toString();
  try {
    const base = createPluginsModule(root, {publish: () => undefined}, () => null);
    const without = testingRoutes(pluginRoutes, base);
    const unavailable = await without.handle({url: "/v1/plugins/catalog", body: {}});
    assert.equal(unavailable?.statusCode, 503);
    assert.match((unavailable?.body as {error: string}).error, /nicht eingerichtet/);

    const catalog: PluginCatalog = {
      list: () => Promise.resolve([{id: "hallo", name: "Hallo-Plugin", description: "grüßt", version: "1.0.0", sizeBytes: 10}]),
      download: (id) => id === "hallo" ? Promise.resolve(packageZip(privateKey)) : Promise.reject(new PluginCatalogError("Nicht gefunden.", "not_found")),
    };
    const routes = testingRoutes(pluginRoutes, {...base, catalog});
    assert.equal(((await routes.handle({url: "/v1/plugins/catalog", body: {}}))?.body as {items: unknown[]}).items.length, 1);
    const preview = await routes.handle({method: "POST", url: "/v1/plugins/installs/catalog", body: {id: "hallo"}});
    assert.equal(preview?.statusCode, 201);
    assert.equal((await routes.handle({method: "POST", url: "/v1/plugins/installs/catalog", body: {id: "fehlt"}}))?.statusCode, 404);
  } finally {
    if (original === undefined) delete process.env.NOVOOA_PLUGIN_PUBLIC_KEY;
    else process.env.NOVOOA_PLUGIN_PUBLIC_KEY = original;
    await rm(root, {recursive: true, force: true});
  }
});
