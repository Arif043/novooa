import {ModelTagVocabulary} from "../../domain/entities/model-tag-vocabulary.js";
import {type ModelTagVocabularySource} from "../../domain/repositories/model-tag-vocabulary-source.js";
import {modelTagFromData} from "../model-tag-vocabulary-codec.js";
import {type RuntimeCollectionReader} from "./firebase-runtime-model-catalog.js";

/** Das globale Tag-Vokabular, wie es eine Runtime nach der Firebase-Anmeldung liest. */
export class FirebaseRuntimeModelTagVocabulary implements ModelTagVocabularySource {
  constructor(private readonly session: RuntimeCollectionReader) {}

  async load(): Promise<ModelTagVocabulary> {
    const documents = await this.session.listCollection("modelTags");
    return new ModelTagVocabulary(documents.map((document) => modelTagFromData(document.id, document.data)));
  }
}
