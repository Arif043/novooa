import {type PluginCatalogEntry} from "../entities/plugin-catalog.js";

/** Der Katalog der vom Admin veröffentlichten Plugins — in Firebase die Quelle, in der Runtime der Client dafür. */
export interface PluginCatalog {
  list(): Promise<PluginCatalogEntry[]>;
  /** Das ZIP-Paket; ohne `version` die aktuelle. */
  download(id: string, version?: string): Promise<Uint8Array>;
}
