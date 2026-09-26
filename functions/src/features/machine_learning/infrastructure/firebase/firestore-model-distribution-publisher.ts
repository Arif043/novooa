import {getDatabase} from "../../../../shared/firebase/firestore-db.js";
import {type ModelArtifactDistribution} from "../model-artifact-distribution.js";

export class FirestoreModelDistributionPublisher {
  async publish(modelId: string, distribution: ModelArtifactDistribution): Promise<void> {
    await getDatabase().collection("modelCatalog").doc(modelId).set(
      {distribution: {...distribution}},
      {merge: true},
    );
  }
}
