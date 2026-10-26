import {getApps, initializeApp} from "firebase-admin/app";
import {PublishModelTagVocabulary} from "../../domain/usecases/publish-model-tag-vocabulary.js";
import {FileModelTagVocabulary} from "../file-model-tag-vocabulary.js";
import {FirestoreModelTagVocabulary} from "../firebase/firestore-model-tag-vocabulary.js";
import {cliErrorMessage} from "./cli-error-message.js";
import {tagPublishOptionsFromArguments, tagPublishUsage} from "./tag-publish-options.js";

async function main(): Promise<void> {
  if (process.argv.includes("--help")) return console.info(tagPublishUsage);
  const options = tagPublishOptionsFromArguments(process.argv.slice(2));
  if (getApps().length === 0) initializeApp({projectId: options.projectId});
  const useCase = new PublishModelTagVocabulary(new FileModelTagVocabulary(options.tagsPath), new FirestoreModelTagVocabulary());
  const vocabulary = await useCase.execute({dryRun: options.dryRun});
  const count = vocabulary.tags.length;
  console.info(options.dryRun ? `Trockenlauf erfolgreich: ${count} Tags sind gültig.` : `${count} Tags veröffentlicht.`);
}

void main().catch((error: unknown) => {
  console.error(cliErrorMessage(error, "Die Veröffentlichung der Tags ist fehlgeschlagen."));
  process.exitCode = 1;
});
