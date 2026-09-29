import {z, type Genkit, type ModelArgument, type ToolArgument} from "genkit";
import {type AssistantExecutionContext} from "../../domain/entities/assistant-execution-context.js";
import {type AssistantMessage} from "../../domain/entities/assistant-message.js";
import {type AssistantRequest} from "../../domain/entities/assistant-request.js";
import {type AssistantResponder} from "../../domain/repositories/assistant-responder.js";
import {genkitContextFrom} from "./assistant-genkit-context.js";

export type GenkitAssistantResponderDependencies<TResponse> = {
  ai: Genkit;
  model: ModelArgument;
  systemPrompt: string;
  tools: ToolArgument[];
  modelConfig: Record<string, unknown>;
  /**
   * Erzwingt Genkits eigenen strukturierten-Ausgabe-Pfad (wie beim
   * Prompt-Baustein) statt eines rohen `JSON.parse(response.text)`. Genkits
   * Extraktion findet das erste balancierte JSON-Objekt auch dann, wenn ein
   * schwaches lokales Modell es in ```json-Codezäune verpackt.
   */
  outputSchema: z.ZodTypeAny;
  promptFromRequest?: (request: AssistantRequest) => string;
  responseFromOutput: (output: unknown, text: string) => TResponse;
};

export class GenkitAssistantResponder<TResponse>
  implements AssistantResponder<TResponse> {
  constructor(
    private readonly dependencies: GenkitAssistantResponderDependencies<TResponse>,
  ) {}

  async respond(
    request: AssistantRequest,
    context: AssistantExecutionContext,
  ): Promise<TResponse> {
    const response = await this.dependencies.ai.generate({
      model: this.dependencies.model,
      system: this.dependencies.systemPrompt,
      messages: request.history.map(messageForModel),
      prompt: this.promptFor(request),
      tools: this.dependencies.tools,
      context: genkitContextFrom(context),
      maxTurns: 20,
      config: this.dependencies.modelConfig,
      output: {schema: this.dependencies.outputSchema},
    });
    return this.dependencies.responseFromOutput(response.output, response.text);
  }

  private promptFor(request: AssistantRequest): string {
    return this.dependencies.promptFromRequest?.(request) ?? request.question;
  }
}

function messageForModel(message: AssistantMessage) {
  return {
    role: message.role === "agent" ? "model" as const : "user" as const,
    content: [{text: message.text}],
  };
}
