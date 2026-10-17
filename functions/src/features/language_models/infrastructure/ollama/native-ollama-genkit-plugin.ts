import {z} from "genkit";
import {genkitPlugin, type GenkitPlugin} from "genkit/plugin";
import {
  GenerationCommonConfigSchema,
  getBasicUsageStats,
  type GenerateRequest,
} from "genkit/model";
import {
  NativeOllamaChatClient,
  type NativeOllamaChatRequest,
  type NativeOllamaChatResponse,
  type OllamaRuntimeOptions,
} from "./native-ollama-chat-client.js";
import {ollamaResponseProblem} from "./ollama-response-problem.js";

/** Genkit-Konfiguration für Ollama: die gemeinsamen Felder plus Kontextfenster und Nachdenken. */
export const ollamaConfigSchema = GenerationCommonConfigSchema.extend({
  numCtx: z.number().int().positive().optional(),
  think: z.union([z.boolean(), z.enum(["low", "medium", "high"])]).optional(),
});

export type OllamaGenkitConfig = z.infer<typeof ollamaConfigSchema>;

export interface OllamaChatClient {
  chat(input: NativeOllamaChatRequest): Promise<NativeOllamaChatResponse>;
}

export type NativeOllamaPluginOptions = {
  name: string;
  serverAddress: string;
  modelId: string;
  chatClient?: OllamaChatClient;
};

export function nativeOllamaPlugin(options: NativeOllamaPluginOptions): GenkitPlugin {
  return genkitPlugin(options.name, async (ai) => {
    ai.defineModel(modelDefinitionFor(options), async (request) => {
      const response = await chatFor(request, options);
      const message = {role: "model" as const, content: [{text: response.content}]};
      return {message, usage: getBasicUsageStats(request.messages, message), finishReason: finishReasonFor(response)};
    });
  });
}

function modelDefinitionFor(options: NativeOllamaPluginOptions) {
  return {
    name: `${options.name}/${options.modelId}`,
    label: `Ollama - ${options.modelId}`,
    configSchema: ollamaConfigSchema,
    supports: {multiturn: true, media: true, systemRole: true, output: ["text", "json"], constrained: "all" as const},
  };
}

async function chatFor(
  request: GenerateRequest<typeof ollamaConfigSchema>,
  options: NativeOllamaPluginOptions,
): Promise<NativeOllamaChatResponse> {
  const format = jsonSchemaFor(request);
  const response = await (options.chatClient ?? new NativeOllamaChatClient()).chat({
    baseUrl: options.serverAddress,
    modelId: options.modelId,
    messages: request.messages.map(messageForOllama),
    format,
    options: runtimeOptionsFor(request.config),
    think: request.config?.think,
  });
  // Vor Genkits Schemaprüfung scheitern, damit der Fehler die echte Ursache nennt.
  const problem = ollamaResponseProblem(response, format !== undefined);
  if (problem) throw problem;
  return response;
}

function runtimeOptionsFor(config: OllamaGenkitConfig | undefined): OllamaRuntimeOptions {
  return {
    num_ctx: config?.numCtx,
    num_predict: config?.maxOutputTokens,
    temperature: config?.temperature,
    top_k: config?.topK,
    top_p: config?.topP,
    stop: config?.stopSequences,
  };
}

function finishReasonFor(response: NativeOllamaChatResponse): "stop" | "length" {
  return response.doneReason === "length" ? "length" : "stop";
}

function messageForOllama(message: GenerateRequest["messages"][number]) {
  const mediaUrls = message.content
    .flatMap((part) => part.media ? [part.media.url] : []);
  const text = message.content
    .flatMap((part) => part.text ? [part.text] : [])
    .join("");
  return {role: roleForOllama(message.role), content: text, mediaUrls};
}

function roleForOllama(role: "system" | "user" | "model" | "tool"): "system" | "user" | "assistant" | "tool" {
  return role === "model" ? "assistant" : role;
}

// Genkit erzeugt offene Objekte (`additionalProperties: true`). Ollama macht
// aus dem Schema eine Grammatik; offen erfindet das Modell weitere Felder und
// verbraucht dafür Tokens. Geschlossen entsteht nur, was verlangt ist.
function jsonSchemaFor(request: GenerateRequest): Record<string, unknown> | undefined {
  const schema = request.output?.schema;
  if (!isRecord(schema)) return undefined;
  return schema.type === "object" ? {...schema, additionalProperties: false} : schema;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}
