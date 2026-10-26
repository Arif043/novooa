import {readFile} from "node:fs/promises";
import {type ModelTagVocabulary} from "../domain/entities/model-tag-vocabulary.js";
import {type ModelTagVocabularySource} from "../domain/repositories/model-tag-vocabulary-source.js";
import {modelTagVocabularyFromFileData} from "./model-tag-vocabulary-codec.js";

/** Das Vokabular aus der Repo-Datei `models/tags.json`, der Quelle für Betreiber und Tests. */
export class FileModelTagVocabulary implements ModelTagVocabularySource {
  constructor(private readonly path: string) {}

  async load(): Promise<ModelTagVocabulary> {
    return modelTagVocabularyFromFileData(JSON.parse(await readFile(this.path, "utf8")));
  }
}
