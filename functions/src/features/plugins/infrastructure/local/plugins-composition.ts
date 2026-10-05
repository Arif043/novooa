import path from "node:path";
import {CommitPluginInstall, PreviewPluginInstall} from "../../domain/usecases/plugin-install.js";
import {ListPlugins, UninstallPlugin} from "../../domain/usecases/plugin-library.js";
import {GetPluginSettings, SetPluginSettings} from "../../domain/usecases/plugin-settings.js";
import {type SignedRuntimeLicense} from "../../../licensing/domain/entities/runtime-license-lease.js";
import {type PluginCatalog} from "../../domain/repositories/plugin-catalog.js";
import {LicenseRelayPluginCatalog} from "./license-relay-plugin-catalog.js";
import {DirectoryPluginStore} from "./directory-plugin-store.js";
import {pluginSignatureVerifierFrom} from "./ed25519-plugin-signature-verifier.js";
import {FilePluginSettingsStore} from "./file-plugin-settings-store.js";
import {InMemoryStagedPluginInstalls} from "./in-memory-staged-plugin-installs.js";
import {ProcessPluginRunner} from "./process-plugin-runner.js";
import {type PluginRoutesOptions} from "./local-plugin-routes.js";

/** Der Plugin-Ordner: `NOVOOA_PLUGINS_DIR` oder `<runtimeRoot>/plugins`. */
export function pluginsDirectoryFor(runtimeRoot: string, environment: NodeJS.ProcessEnv = process.env): string {
  const configured = environment.NOVOOA_PLUGINS_DIR?.trim();
  return configured ? path.resolve(configured) : path.join(runtimeRoot, "plugins");
}

export function createPluginStore(runtimeRoot: string): DirectoryPluginStore {
  return new DirectoryPluginStore(pluginsDirectoryFor(runtimeRoot));
}

export function createPluginSettingsStore(runtimeRoot: string): FilePluginSettingsStore {
  return new FilePluginSettingsStore(path.join(runtimeRoot, "plugin-settings"));
}

export function createPluginRunner(runtimeRoot: string): ProcessPluginRunner {
  return new ProcessPluginRunner(createPluginStore(runtimeRoot), createPluginSettingsStore(runtimeRoot), pluginsDirectoryFor(runtimeRoot));
}

/** `PLUGINS_RELAY_URL` — Relay in Firebase (`localRuntimePluginsRelay`); leer = kein Katalog. */
export function pluginCatalogFrom(license: () => SignedRuntimeLicense | null, environment: NodeJS.ProcessEnv = process.env): PluginCatalog | undefined {
  const relayUrl = environment.PLUGINS_RELAY_URL?.trim();
  return relayUrl ? new LicenseRelayPluginCatalog(relayUrl, license) : undefined;
}

export function createPluginsModule(
  runtimeRoot: string,
  notifier: PluginRoutesOptions["notifier"],
  license: () => SignedRuntimeLicense | null,
): PluginRoutesOptions {
  const store = createPluginStore(runtimeRoot);
  const settings = createPluginSettingsStore(runtimeRoot);
  const staged = new InMemoryStagedPluginInstalls();
  const catalog = pluginCatalogFrom(license);
  return {
    list: new ListPlugins(store),
    uninstall: new UninstallPlugin(store, settings),
    preview: new PreviewPluginInstall(store, pluginSignatureVerifierFrom(), staged),
    commit: new CommitPluginInstall(store, staged),
    getSettings: new GetPluginSettings(store, settings),
    setSettings: new SetPluginSettings(store, settings),
    ...(catalog === undefined ? {} : {catalog}),
    notifier,
  };
}
