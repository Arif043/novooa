import {type RuntimeExecutor} from "../../../../db/database.js";
import {modelTags} from "../../../../db/schema.js";
import {ModelTagVocabulary} from "../../domain/entities/model-tag-vocabulary.js";
import {type ModelTagVocabularySource} from "../../domain/repositories/model-tag-vocabulary-source.js";
import {modelTagData, modelTagFromData} from "../model-tag-vocabulary-codec.js";

/** Der lokale Spiegel des globalen Tag-Vokabulars; ersetzt wird er immer als Ganzes. */
export class SQLiteModelTagVocabulary implements ModelTagVocabularySource {
  constructor(private readonly database: RuntimeExecutor) {}

  async load(): Promise<ModelTagVocabulary> {
    const rows = await this.database.select().from(modelTags).orderBy(modelTags.key);
    return new ModelTagVocabulary(rows.map((row) => modelTagFromData(row.key, {
      parent: row.parent, labels: JSON.parse(row.labels_json) as unknown, synonyms: JSON.parse(row.synonyms_json) as unknown,
    })));
  }

  async replaceAll(vocabulary: ModelTagVocabulary): Promise<void> {
    const rows = vocabulary.tags.map((tag) => {
      const data = modelTagData(tag);
      return {key: tag.key, parent: data.parent, labels_json: JSON.stringify(data.labels), synonyms_json: JSON.stringify(data.synonyms)};
    });
    await this.database.transaction(async (transaction) => {
      await transaction.delete(modelTags);
      if (rows.length > 0) await transaction.insert(modelTags).values(rows);
    });
  }
}
