import {modelCatalogEntryFromData} from "../model-catalog-entry-codec.js";
import {type RuntimeSystemModel, type RuntimeSystemModelCatalog} from "./runtime-system-model-catalog.js";

export interface RuntimeCollectionReader {
  listCollection(collectionName: string): Promise<readonly {id: string; data: Record<string, unknown>}[]>;
}

export class FirebaseRuntimeModelCatalog implements RuntimeSystemModelCatalog {
  constructor(private readonly session: RuntimeCollectionReader) {}

  async list(): Promise<readonly RuntimeSystemModel[]> {
    const documents = await this.session.listCollection("modelCatalog");
    return documents
      .map((document) => this.entryFrom(document.id, document.data))
      .filter((entry): entry is RuntimeSystemModel => entry !== null);
  }

  async find(modelId: string): Promise<RuntimeSystemModel | null> {
    const entry = (await this.list()).find((item) => item.entry.id === modelId);
    return entry ?? null;
  }

  private entryFrom(id: string, data: Record<string, unknown>): RuntimeSystemModel | null {
    if (data.scope !== "system") return null;
    return {entry: modelCatalogEntryFromData({...data, id} as Parameters<typeof modelCatalogEntryFromData>[0])};
  }
}
