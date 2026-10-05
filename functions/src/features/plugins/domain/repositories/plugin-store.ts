import {type PluginFile, type PluginPackage} from "../entities/plugin-package.js";
import {type StoredPlugin} from "../entities/stored-plugin.js";

/** Der Plugin-Ordner der Runtime: jedes Plugin ist ein Unterordner mit `plugin.json`. */
export interface PluginStore {
  list(): Promise<StoredPlugin[]>;
  find(id: string): Promise<StoredPlugin | undefined>;
  /** Installiert das Plugin oder ersetzt eine ältere Version atomar. */
  save(plugin: PluginPackage): Promise<StoredPlugin>;
  delete(id: string): Promise<void>;
  /** Alle Dateien des Plugins (Pfade relativ, mit `/`); wirft `PluginNotFoundError`. */
  readFiles(id: string): Promise<PluginFile[]>;
}
