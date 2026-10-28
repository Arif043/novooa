import {type Part, type z} from "genkit";
import {type LlmMessage} from "../../../domain/prompting/llm-prompt.js";
import {type LlmGateway, type LlmOutputSpec, type LlmRequest, type LlmResponse} from "../../../domain/prompting/llm-gateway.js";
import {type PromptRenderer} from "../../../domain/prompting/prompt-renderer.js";
import {type GenkitLlmBinding} from "./genkit-llm-binding.js";
import {choiceSchemaFor, structuredSchemaFor} from "./llm-output-schema.js";

type GenkitResult = {text: string; output?: unknown; media?: {url?: string} | null; messages?: unknown};

/**
 * Der einzige Ort, der für das Framework `ai.generate` aufruft: rendert den Prompt in `system`,
 * `messages` und `prompt` (Text plus Medienteile) und leitet das Ausgabeschema aus `LlmOutputSpec` ab.
 */
export class GenkitLlmGateway implements LlmGateway<GenkitLlmBinding> {
  constructor(private readonly renderer: PromptRenderer) {}

  async generate(request: LlmRequest<GenkitLlmBinding>): Promise<LlmResponse> {
    const {ai, model, config, use, tools, maxTurns, continuation, context} = request.binding;
    const rendered = this.renderer.render(request.prompt);
    const result: GenkitResult = await ai.generate({
      model, use, tools, maxTurns, context,
      // Ein fortgesetztes Gespräch trägt seinen Systemteil schon in sich.
      system: continuation ? undefined : rendered.system,
      messages: continuation ?? messagesFor(request.prompt.history),
      prompt: userContentFor(rendered.user, request.prompt.mediaUrls),
      output: outputFor(request.output),
      config: request.output.kind === "image" ? {responseModalities: ["IMAGE"]} : config,
    });
    return responseFor(request.output, result);
  }
}

function messagesFor(history: readonly LlmMessage[]) {
  if (history.length === 0) return undefined;
  return history.map((message) => ({role: message.role, content: [{text: message.text}]}));
}

/** Ohne Bilder ein einfacher Text; mit Bildern Text plus je ein Medienteil. */
function userContentFor(text: string, mediaUrls: readonly string[]): string | Part[] {
  if (mediaUrls.length === 0) return text;
  return [{text}, ...mediaUrls.map((url) => ({media: {url}}))];
}

function outputFor(spec: LlmOutputSpec) {
  switch (spec.kind) {
    case "choice": return {schema: choiceSchemaFor(spec.choices)};
    case "structured": return {schema: structuredSchemaFor(spec.fields)};
    case "schema": return {schema: spec.schema as z.ZodTypeAny};
    default: return undefined;
  }
}

function responseFor(spec: LlmOutputSpec, result: GenkitResult): LlmResponse {
  const conversation = result.messages;
  switch (spec.kind) {
    case "choice": return {text: result.text, data: answerOf(result.output), conversation};
    case "structured":
    case "schema": return {text: result.text, data: result.output ?? undefined, conversation};
    case "image": return {text: result.text ?? "", mediaUrl: result.media?.url, conversation};
    default: return {text: result.text, conversation};
  }
}

function answerOf(output: unknown): unknown {
  return typeof output === "object" && output !== null && "answer" in output ? output.answer : undefined;
}
