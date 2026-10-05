import {getStorage} from "firebase-admin/storage";
import {getDatabase, initializeAdminApp} from "../../../../shared/firebase/firestore-db.js";
import {PluginCatalogError, type PluginCatalogEntry} from "../../domain/entities/plugin-catalog.js";
import {type PluginCatalog} from "../../domain/repositories/plugin-catalog.js";

export const pluginCatalogCollection = "pluginCatalog";
const maximumPackageBytes = 15 * 1024 * 1024;

/**
 * Katalog in Firestore (`pluginCatalog/{id}`), Pakete in Storage (`plugins/{id}/{version}/package.zip`).
 * Beides beschreibt nur das Veröffentlichungs-Skript; die Client-Regeln verweigern jeden Zugriff.
 */
export class FirebasePluginCatalog implements PluginCatalog {
  async list(): Promise<PluginCatalogEntry[]> {
    const snapshot = await getDatabase().collection(pluginCatalogCollection).get();
    return snapshot.docs.flatMap((document): PluginCatalogEntry[] => {
      const data = document.data() as Partial<PluginCatalogEntry>;
      if (typeof data.version !== "string" || typeof data.name !== "string") return [];
      return [{id: document.id, name: data.name, description: data.description ?? "", version: data.version, sizeBytes: data.sizeBytes ?? 0}];
    }).sort((a, b) => a.name.localeCompare(b.name, "de"));
  }

  async download(id: string, version?: string): Promise<Uint8Array> {
    const entry = await getDatabase().collection(pluginCatalogCollection).doc(id).get();
    if (!entry.exists) throw new PluginCatalogError(`Das Plugin „${id}“ gibt es im Katalog nicht.`, "not_found");
    const resolved = version ?? (entry.data() as {version?: string}).version;
    if (resolved === undefined) throw new PluginCatalogError(`Das Plugin „${id}“ hat keine veröffentlichte Version.`, "not_found");
    initializeAdminApp();
    const file = getStorage().bucket().file(`plugins/${id}/${resolved}/package.zip`);
    const [exists] = await file.exists();
    if (!exists) throw new PluginCatalogError(`Version ${resolved} von „${id}“ gibt es nicht.`, "not_found");
    const [metadata] = await file.getMetadata();
    if (Number(metadata.size) > maximumPackageBytes) throw new PluginCatalogError("Das Plugin ist zu groß.", "invalid");
    const [bytes] = await file.download();
    return new Uint8Array(bytes);
  }
}
