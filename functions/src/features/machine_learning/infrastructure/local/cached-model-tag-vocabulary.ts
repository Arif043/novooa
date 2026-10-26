import {type ModelTagVocabulary} from "../../domain/entities/model-tag-vocabulary.js";
import {type ModelTagVocabularySource} from "../../domain/repositories/model-tag-vocabulary-source.js";

export interface ModelTagVocabularyMirror extends ModelTagVocabularySource {
  replaceAll(vocabulary: ModelTagVocabulary): Promise<void>;
}

/**
 * Liest das globale Vokabular und spiegelt es lokal. Ohne Firebase-Sitzung oder bei einem Fehler
 * gilt der letzte Spiegel, damit Suche und Import auch offline dieselben Tags kennen.
 */
export class CachedModelTagVocabulary implements ModelTagVocabularySource {
  constructor(
    private readonly remote: ModelTagVocabularySource | undefined,
    private readonly mirror: ModelTagVocabularyMirror,
    private readonly onRemoteFailure: (error: unknown) => void = () => undefined,
  ) {}

  async load(): Promise<ModelTagVocabulary> {
    if (this.remote === undefined) return this.mirror.load();
    try {
      const vocabulary = await this.remote.load();
      await this.mirror.replaceAll(vocabulary);
      return vocabulary;
    } catch (error) {
      this.onRemoteFailure(error);
      return this.mirror.load();
    }
  }
}
