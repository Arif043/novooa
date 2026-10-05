import {type PluginPackage} from "../entities/plugin-package.js";

/** Geprüfte, noch nicht installierte Pakete zwischen Vorschau und Bestätigung. */
export interface StagedPluginInstalls {
  add(plugin: PluginPackage): string;
  find(installId: string): PluginPackage | undefined;
  discard(installId: string): void;
}
