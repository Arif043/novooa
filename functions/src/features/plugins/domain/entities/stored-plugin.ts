import {type PluginManifest} from "./plugin-manifest.js";

export type StoredPlugin = {
  id: string;
  version: string;
  name: string;
  description: string;
  manifest: PluginManifest;
};

export class PluginNotFoundError extends Error {
  constructor(readonly pluginId: string) {
    super(`Das Plugin „${pluginId}“ ist nicht installiert.`);
    this.name = "PluginNotFoundError";
  }
}

/** Der Plugin-Ordner lässt sich nicht beschreiben (Rechte, schreibgeschützt). */
export class PluginStorageError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "PluginStorageError";
  }
}
