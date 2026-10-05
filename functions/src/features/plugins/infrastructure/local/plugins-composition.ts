import path from "node:path";
import {CommitPluginInstall, PreviewPluginInstall} from "../../domain/usecases/plugin-install.js";
import {ListPlugins, UninstallPlugin} from "../../domain/usecases/plugin-library.js";
import {GetPluginSettings, SetPluginSettings} from "../../domain/usecases/plugin-settings.js";
import {DirectoryPluginStore} from "./directory-plugin-store.js";
import {pluginSignatureVerifierFrom} from "./ed25519-plugin-signature-verifier.js";
import {FilePluginSettingsStore} from "./file-plugin-settings-store.js";
import {InMemoryStagedPluginInstalls} from "./in-memory-staged-plugin-installs.js";
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

export function createPluginsModule(runtimeRoot: string, notifier: PluginRoutesOptions["notifier"]): PluginRoutesOptions {
  const store = createPluginStore(runtimeRoot);
  const settings = createPluginSettingsStore(runtimeRoot);
  const staged = new InMemoryStagedPluginInstalls();
  return {
    list: new ListPlugins(store),
    uninstall: new UninstallPlugin(store, settings),
    preview: new PreviewPluginInstall(store, pluginSignatureVerifierFrom(), staged),
    commit: new CommitPluginInstall(store, staged),
    getSettings: new GetPluginSettings(store, settings),
    setSettings: new SetPluginSettings(store, settings),
    notifier,
  };
}
