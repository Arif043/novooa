import {AssistantActor} from "../../../assistant/domain/entities/assistant-actor.js";
import {AssistantExecutionContext} from "../../../assistant/domain/entities/assistant-execution-context.js";
import {type AssistantRequest} from "../../../assistant/domain/entities/assistant-request.js";
import {RemoteConfigAssistantModel} from "../../../language_models/infrastructure/firebase/remote-config-assistant-model.js";
import {resolveAssistantLanguageModel} from "../../../language_models/infrastructure/genkit/resolve-assistant-language-model.js";
import {SearchModelCatalog} from "../../../machine_learning/domain/usecases/search-model-catalog.js";
import {FirestoreModelCatalog} from "../../../machine_learning/infrastructure/firebase/firestore-model-catalog.js";
import {FirestoreModelTagVocabulary} from "../../../machine_learning/infrastructure/firebase/firestore-model-tag-vocabulary.js";
import {type TeamIdForActor} from "../../../machine_learning/infrastructure/genkit/model-catalog-search-tool.js";
import {createTaskBuilderAssistantResponder} from "../genkit/assistant/task-builder-assistant-responder.js";
import {createTaskBuilderAssistant} from "../genkit/task-builder-assistant.js";
import {logTaskBuilderAssistantProposal} from "./task-builder-assistant-audit-event.js";

const assistantModel = new RemoteConfigAssistantModel();
const modelCatalog = new FirestoreModelCatalog();
const searchModelCatalog = new SearchModelCatalog(modelCatalog, modelCatalog, new FirestoreModelTagVocabulary());

/**
 * Der Aufgabenstudio-Agent in der Cloud — gemeinsam für die App (Callable)
 * und die lokale Runtime (Relay). Das Modell legt Remote Config fest.
 * `teamIdForActor` liefert `null`, wenn kein Team bekannt ist (Relay); die
 * Modellsuche bleibt dann auf den globalen Katalog beschränkt.
 */
export async function runTaskBuilderAssistant(input: {
  request: AssistantRequest;
  actorId: string;
  teamIdForActor: TeamIdForActor;
}) {
  const {ai, model} = await resolveAssistantLanguageModel(assistantModel);
  const assistant = createTaskBuilderAssistant(
    createTaskBuilderAssistantResponder({
      ai, model, modelConfig: {},
      modelCatalogSearch: {searchModelCatalog, teamIdForActor: input.teamIdForActor},
    }),
  );
  const output = await assistant.ask(input.request, new AssistantExecutionContext(new AssistantActor(input.actorId)));
  logTaskBuilderAssistantProposal({
    uid: input.actorId,
    historyLength: input.request.history.length,
    commands: output.commands,
  });
  return output;
}
