import {FieldValue} from "firebase-admin/firestore";
import {getDatabase} from "../../../../shared/firebase/firestore-db.js";
import {ModelTagVocabulary} from "../../domain/entities/model-tag-vocabulary.js";
import {type ModelTagVocabularySource} from "../../domain/repositories/model-tag-vocabulary-source.js";
import {modelTagData, modelTagFromData} from "../model-tag-vocabulary-codec.js";

/**
 * Das globale Tag-Vokabular in `modelTags/{key}`. Schreiben darf nur der Betreiber über
 * `models:tags:publish`; Tags werden nur angelegt oder aktualisiert, nie gelöscht, weil
 * veröffentlichte Einträge auf sie verweisen können.
 */
export class FirestoreModelTagVocabulary implements ModelTagVocabularySource {
  async load(): Promise<ModelTagVocabulary> {
    const snapshot = await tagsReference().get();
    return new ModelTagVocabulary(snapshot.docs.map((document) => modelTagFromData(document.id, document.data())));
  }

  async save(vocabulary: ModelTagVocabulary): Promise<void> {
    const batch = getDatabase().batch();
    for (const tag of vocabulary.tags) {
      batch.set(tagsReference().doc(tag.key), {...modelTagData(tag), updatedAt: FieldValue.serverTimestamp()});
    }
    await batch.commit();
  }
}

function tagsReference() {
  return getDatabase().collection("modelTags");
}
