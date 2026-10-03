import {AssistantActor} from "../../../assistant/domain/entities/assistant-actor.js";
import {AssistantExecutionContext} from "../../../assistant/domain/entities/assistant-execution-context.js";
import {type AssistantRequest} from "../../../assistant/domain/entities/assistant-request.js";
import {RemoteConfigAssistantModel} from "../../../language_models/infrastructure/firebase/remote-config-assistant-model.js";
import {resolveAssistantLanguageModel} from "../../../language_models/infrastructure/genkit/resolve-assistant-language-model.js";
import {createTaskBuilderAssistantResponder} from "../genkit/assistant/task-builder-assistant-responder.js";
import {createTaskBuilderAssistant} from "../genkit/task-builder-assistant.js";
import {logTaskBuilderAssistantProposal} from "./task-builder-assistant-audit-event.js";

const assistantModel = new RemoteConfigAssistantModel();

/**
 * Der Aufgabenstudio-Agent in der Cloud — gemeinsam für die App (Callable)
 * und die lokale Runtime (Relay). Das Modell legt Remote Config fest.
 */
export async function runTaskBuilderAssistant(input: {
  request: AssistantRequest;
  actorId: string;
}) {
  const {ai, model} = await resolveAssistantLanguageModel(assistantModel);
  const assistant = createTaskBuilderAssistant(
    createTaskBuilderAssistantResponder({ai, model, modelConfig: {}}),
  );
  const output = await assistant.ask(input.request, new AssistantExecutionContext(new AssistantActor(input.actorId)));
  logTaskBuilderAssistantProposal({
    uid: input.actorId,
    historyLength: input.request.history.length,
    commands: output.commands,
  });
  return output;
}
