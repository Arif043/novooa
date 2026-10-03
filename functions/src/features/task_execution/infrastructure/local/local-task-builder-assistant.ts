import {type AssistantExecutionContext} from "../../../assistant/domain/entities/assistant-execution-context.js";
import {type AssistantRequest} from "../../../assistant/domain/entities/assistant-request.js";
import {type AssistantResponder} from "../../../assistant/domain/repositories/assistant-responder.js";
import {type SignedRuntimeLicense} from "../../../licensing/domain/entities/runtime-license-lease.js";
import {type TaskBuilderAssistantResponse} from "../../domain/entities/task-builder-assistant-response.js";
import {type TaskBuilderAssistant} from "../../domain/usecases/task-builder-assistant.js";
import {createTaskBuilderAssistant} from "../genkit/task-builder-assistant.js";
import {type RuntimeTaskBuilderRelayClient} from "./runtime-task-builder-relay-client.js";

/**
 * Der Aufgabenstudio-Agent läuft ausschließlich in der Cloud (mit dem Modell
 * aus Remote Config); die Runtime reicht Frage und Verlauf über das Relay
 * weiter und weist sich mit ihrer Lizenz aus.
 */
class CloudTaskBuilderResponder implements AssistantResponder<TaskBuilderAssistantResponse> {
  constructor(
    private readonly signedLicense: () => SignedRuntimeLicense | null,
    private readonly relay: RuntimeTaskBuilderRelayClient,
  ) {}

  async respond(request: AssistantRequest, _context: AssistantExecutionContext): Promise<TaskBuilderAssistantResponse> {
    const license = this.signedLicense();
    if (license === null) throw new Error("Die lokale Runtime hat keine aktive Lizenz.");
    return this.relay.ask(license, {
      question: request.question,
      history: request.history.map(({role, text}) => ({role, text})),
    });
  }
}

export function createLocalTaskBuilderAssistant(
  signedLicense: () => SignedRuntimeLicense | null,
  relay: RuntimeTaskBuilderRelayClient,
): TaskBuilderAssistant {
  return createTaskBuilderAssistant(new CloudTaskBuilderResponder(signedLicense, relay));
}
