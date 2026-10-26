import {type ModelTagVocabulary} from "../entities/model-tag-vocabulary.js";
import {type ModelTagVocabularySource} from "../repositories/model-tag-vocabulary-source.js";

/** Wohin der Betreiber das Vokabular veröffentlicht; legt an und aktualisiert, löscht aber nie. */
export interface ModelTagVocabularyStore {
  save(vocabulary: ModelTagVocabulary): Promise<void>;
}

/** Überträgt das gepflegte Vokabular (Repo-Datei) in den globalen Katalog. */
export class PublishModelTagVocabulary {
  constructor(
    private readonly source: ModelTagVocabularySource,
    private readonly store: ModelTagVocabularyStore,
  ) {}

  /** Liest und prüft das Vokabular; ohne `dryRun` wird es veröffentlicht. */
  async execute(options: {dryRun: boolean}): Promise<ModelTagVocabulary> {
    const vocabulary = await this.source.load();
    if (!options.dryRun) await this.store.save(vocabulary);
    return vocabulary;
  }
}
