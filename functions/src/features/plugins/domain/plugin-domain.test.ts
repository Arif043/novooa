import assert from "node:assert/strict";
import {generateKeyPairSync, sign} from "node:crypto";
import test from "node:test";
import {PluginPackageError} from "./entities/plugin-package-error.js";
import {parsePluginManifest} from "./entities/plugin-manifest.js";
import {pluginDigest, pluginPackageFrom, pluginSignatureFile, type PluginFile} from "./entities/plugin-package.js";
import {Ed25519PluginSignatureVerifier, pluginSignatureVerifierFrom} from "../infrastructure/local/ed25519-plugin-signature-verifier.js";
import {InMemoryStagedPluginInstalls} from "../infrastructure/local/in-memory-staged-plugin-installs.js";
import {CommitPluginInstall, PreviewPluginInstall} from "./usecases/plugin-install.js";
import {GetPluginSettings, SetPluginSettings} from "./usecases/plugin-settings.js";
import {type PluginStore} from "./repositories/plugin-store.js";
import {type PluginSettingsStore, type PluginSettingValues} from "./repositories/plugin-settings-store.js";
import {type StoredPlugin} from "./entities/stored-plugin.js";

const manifestJson = {
  schemaVersion: 1, id: "hallo", version: "1.0.0", name: "Hallo", description: "Sagt Hallo.",
  primitives: [{type: "greet", label: "Begrüßen", description: "Grüßt", settings: [{key: "name", label: "Name", kind: "text"}], outputs: [{name: "text", label: "Text", type: "string"}]}],
  triggers: [{type: "tick", label: "Tick", description: "Tickt", settings: []}],
  settingsPanels: [{id: "main", title: "Hallo", fields: [
    {key: "greeting", label: "Gruß", kind: "text", defaultValue: "Hallo"},
    {key: "apiKey", label: "Schlüssel", kind: "text", secret: true},
    {key: "mode", label: "Modus", kind: "choice", options: [{value: "a", label: "A"}]},
  ]}],
};

const encode = (value: unknown) => new TextEncoder().encode(JSON.stringify(value));
const baseFiles = (): PluginFile[] => [
  {path: "plugin.json", bytes: encode(manifestJson)},
  {path: "backend/index.mjs", bytes: new TextEncoder().encode("export default {};")},
];

function signedFiles() {
  const {privateKey, publicKey} = generateKeyPairSync("ed25519");
  const files = baseFiles();
  files.push({path: pluginSignatureFile, bytes: sign(null, pluginDigest(files), privateKey)});
  return {files, verifier: new Ed25519PluginSignatureVerifier(publicKey.export({type: "spki", format: "pem"}).toString())};
}

class MemoryStore implements PluginStore {
  readonly plugins = new Map<string, StoredPlugin>();
  list() { return Promise.resolve([...this.plugins.values()]); }
  find(id: string) { return Promise.resolve(this.plugins.get(id)); }
  save(plugin: {manifest: StoredPlugin["manifest"]}) {
    const stored = {id: plugin.manifest.id, version: plugin.manifest.version, name: plugin.manifest.name, description: plugin.manifest.description, manifest: plugin.manifest};
    this.plugins.set(stored.id, stored);
    return Promise.resolve(stored);
  }
  delete(id: string) { this.plugins.delete(id); return Promise.resolve(); }
  readFiles() { return Promise.resolve([]); }
}

class MemorySettings implements PluginSettingsStore {
  values: PluginSettingValues = {};
  read() { return Promise.resolve({...this.values}); }
  write(_id: string, values: PluginSettingValues) { this.values = values; return Promise.resolve(); }
  delete() { this.values = {}; return Promise.resolve(); }
}

test("ein gültiges Manifest wird gelesen und mit Standardwerten ergänzt", () => {
  const manifest = parsePluginManifest(JSON.stringify(manifestJson));
  assert.equal(manifest.entry, "backend/index.mjs");
  assert.deepEqual(manifest.network, []);
});

test("ungültige Manifeste werden mit deutscher Meldung abgelehnt", () => {
  assert.throws(() => parsePluginManifest("{"), /kein gültiges JSON/);
  assert.throws(() => parsePluginManifest(JSON.stringify({...manifestJson, id: "Ungültig!"})), /Plugin-ID/);
  assert.throws(() => parsePluginManifest(JSON.stringify({...manifestJson, primitives: [manifestJson.primitives[0], manifestJson.primitives[0]]})), /doppelt/);
  const choiceWithoutOptions = {...manifestJson, triggers: [{type: "t", label: "T", description: "", settings: [{key: "x", label: "X", kind: "choice"}]}]};
  assert.throws(() => parsePluginManifest(JSON.stringify(choiceWithoutOptions)), /options/);
});

test("Pakete mit unsicheren Pfaden oder fehlendem Einstieg werden abgelehnt", () => {
  assert.throws(() => pluginPackageFrom([...baseFiles(), {path: "../böse.js", bytes: new Uint8Array()}]), PluginPackageError);
  assert.throws(() => pluginPackageFrom([...baseFiles(), {path: "node_modules/x.js", bytes: new Uint8Array()}]), PluginPackageError);
  assert.throws(() => pluginPackageFrom(baseFiles().slice(0, 1)), /Einstiegsdatei/);
  assert.throws(() => pluginPackageFrom(baseFiles().slice(1)), /plugin\.json/);
});

test("die Prüfsumme hängt nicht von der Reihenfolge ab und ignoriert die Signatur", () => {
  const files = baseFiles();
  assert.deepEqual(pluginDigest(files), pluginDigest([...files].reverse()));
  assert.deepEqual(pluginDigest(files), pluginDigest([...files, {path: pluginSignatureFile, bytes: new Uint8Array([1])}]));
  assert.notDeepEqual(pluginDigest(files), pluginDigest([{path: "plugin.json", bytes: encode({...manifestJson, version: "2.0.0"})}, files[1]]));
});

test("Vorschau und Commit installieren nur signierte, unveränderte Pakete", async () => {
  const {files, verifier} = signedFiles();
  const store = new MemoryStore();
  const staged = new InMemoryStagedPluginInstalls();
  const preview = new PreviewPluginInstall(store, verifier, staged);
  const result = await preview.execute(files);
  assert.equal(result.manifest.id, "hallo");
  assert.equal(store.plugins.size, 0);
  assert.equal((await new CommitPluginInstall(store, staged).execute(result.installId)).version, "1.0.0");
  assert.equal((await preview.execute(files)).installedVersion, "1.0.0");

  const tampered = files.map((file) => file.path === "backend/index.mjs" ? {...file, bytes: new TextEncoder().encode("evil")} : file);
  await assert.rejects(() => preview.execute(tampered), /Signatur/);
  await assert.rejects(() => preview.execute(baseFiles()), /Signatur/);
  await assert.rejects(() => new CommitPluginInstall(store, staged).execute("unbekannt"), /abgelaufen/);
});

test("ohne Schlüssel wird nichts installiert, außer die Entwicklung erlaubt es ausdrücklich", () => {
  assert.equal(pluginSignatureVerifierFrom({}).verify(new Uint8Array(), undefined), false);
  assert.equal(pluginSignatureVerifierFrom({NOVOOA_PLUGIN_ALLOW_UNSIGNED: "true"}).verify(new Uint8Array(), undefined), true);
});

test("Einstellungen werden geprüft; Geheimnisse verlassen das Backend nicht", async () => {
  const store = new MemoryStore();
  await store.save(pluginPackageFrom(baseFiles()));
  const settings = new MemorySettings();
  const set = new SetPluginSettings(store, settings);
  const get = new GetPluginSettings(store, settings);

  assert.deepEqual(await get.execute("hallo"), {values: {greeting: "Hallo"}, secretsSet: []});
  await set.execute("hallo", {greeting: "Moin", apiKey: "geheim"});
  assert.deepEqual(await get.execute("hallo"), {values: {greeting: "Moin"}, secretsSet: ["apiKey"]});
  await set.execute("hallo", {apiKey: ""});
  assert.equal(settings.values.apiKey, "geheim");

  await assert.rejects(() => set.execute("hallo", {unbekannt: "x"}), /gehört nicht/);
  await assert.rejects(() => set.execute("hallo", {mode: "z"}), /ungültig/);
  await assert.rejects(() => set.execute("fehlt", {}), /nicht installiert/);
});
