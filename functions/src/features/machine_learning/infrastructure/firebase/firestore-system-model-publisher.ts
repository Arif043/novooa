import {type ModelCatalogEntry} from "../../domain/entities/model-catalog-entry.js";
import {type PublishSystemModelRequest} from "../../domain/usecases/publish-system-model.js";
import {FirestoreModelCatalog} from "./firestore-model-catalog.js";

export class FirestoreSystemModelPublisher {
  constructor(private readonly catalog = new FirestoreModelCatalog()) {}

  async execute(request: PublishSystemModelRequest): Promise<ModelCatalogEntry> {
    await this.catalog.save(request.entry);
    return request.entry;
  }
}
