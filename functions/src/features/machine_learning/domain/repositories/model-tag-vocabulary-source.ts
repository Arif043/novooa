import {type ModelTagVocabulary} from "../entities/model-tag-vocabulary.js";

/** Woher das Tag-Vokabular kommt: Repo-Datei, globaler Katalog oder der Spiegel der Runtime. */
export interface ModelTagVocabularySource {
  load(): Promise<ModelTagVocabulary>;
}
