import {type Genkit, type ModelArgument, type ToolArgument, type z} from "genkit";
import {type LlmGateway, type LlmOutputSpec} from "../../../language_models/domain/prompting/llm-gateway.js";
import {ModelOutputSchemaError} from "../../../language_models/infrastructure/errors/language-model-errors.js";
import {type PromptBuilder} from "../../../language_models/domain/prompting/prompt-builder.js";
import {type GenkitLlmBinding} from "../../../language_models/infrastructure/genkit/llm/genkit-llm-binding.js";
import {silentLlmCallLog, type LlmCallLog} from "../../../language_models/infrastructure/genkit/llm/llm-call-log.js";
import {createLlmGateway} from "../../../language_models/infrastructure/genkit/llm/llm-gateway-factory.js";
import {type AssistantExecutionContext} from "../../domain/entities/assistant-execution-context.js";
import {type AssistantRequest} from "../../domain/entities/assistant-request.js";
import {type AssistantResponder} from "../../domain/repositories/assistant-responder.js";
import {genkitContextFrom} from "./assistant-genkit-context.js";
import {assistantPrompt} from "./assistant-prompt.js";
import {jsonFromText} from "./json-from-text.js";

export type GenkitAssistantResponderDependencies<TResponse> = {
  ai: Genkit;
  model: ModelArgument;
  /** Name im Protokoll, z. B. „Aufgabenstudio-Agent“. */
  label: string;
  /** Feste Anweisungen des Agenten (Systemteil); Frage, Verlauf und Sprache ergänzt der Responder. */
  instructions: PromptBuilder;
  tools: ToolArgument[];
  modelConfig: Record<string, unknown>;
  /**
   * Erzwingt Genkits eigenen strukturierten-Ausgabe-Pfad (wie beim
   * Prompt-Baustein) statt eines rohen `JSON.parse(response.text)`. Genkits
   * Extraktion findet das erste balancierte JSON-Objekt auch dann, wenn ein
   * schwaches lokales Modell es in ```json-Codezäune verpackt.
   */
  outputSchema: z.ZodTypeAny;
  /** Obergrenze der Tool-Runden; Orchestratoren mit Subagenten setzen sie niedriger. */
  maxTurns?: number;
  responseFromOutput: (output: unknown, text: string) => TResponse;
  log?: LlmCallLog;
};

/**
 * Ein Turn eines In-App-Agenten über das LLM-Framework. Zustandslos: Den Verlauf schickt der Client
 * mit jeder Frage, deshalb passt derselbe Responder in Runtime und Relay.
 */
export class GenkitAssistantResponder<TResponse> implements AssistantResponder<TResponse> {
  private readonly gateway: LlmGateway<GenkitLlmBinding>;

  constructor(private readonly dependencies: GenkitAssistantResponderDependencies<TResponse>) {
    this.gateway = createLlmGateway(dependencies.log ?? silentLlmCallLog);
  }

  async respond(request: AssistantRequest, context: AssistantExecutionContext): Promise<TResponse> {
    const {outputSchema, responseFromOutput} = this.dependencies;
    try {
      const response = await this.generate(request, context, {kind: "schema", schema: outputSchema});
      return responseFromOutput(response.data, response.text);
    } catch (error) {
      if (!(error instanceof ModelOutputSchemaError)) throw error;
      // Schwache lokale Modelle verfehlen das Schema oft ab der zweiten Frage; Genkit verwirft dann
      // die Antwort. Ein zweiter Versuch ohne Schema liest JSON tolerant und nimmt sonst den Text.
      const response = await this.generate(request, context, {kind: "text"});
      return responseFromOutput(jsonFromText(response.text), response.text);
    }
  }

  private generate(request: AssistantRequest, context: AssistantExecutionContext, output: LlmOutputSpec) {
    const {ai, model, label, instructions, tools, modelConfig, maxTurns} = this.dependencies;
    return this.gateway.generate({
      binding: {
        ai, model, config: modelConfig, logContext: {agent: label}, tools,
        maxTurns: maxTurns ?? 20, context: genkitContextFrom(context),
      },
      prompt: assistantPrompt(instructions, request),
      label,
      output,
    });
  }
}
