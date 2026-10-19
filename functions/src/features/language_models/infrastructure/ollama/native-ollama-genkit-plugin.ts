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
import {contentFromOllama, messagesForOllama, toolsForOllama} from "./native-ollama-tool-messages.js";
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
      const message = {role: "model" as const, content: contentFromOllama(response)};
      return {message, usage: getBasicUsageStats(request.messages, message), finishReason: finishReasonFor(response)};
    });
  });
}

function modelDefinitionFor(options: NativeOllamaPluginOptions) {
  return {
    name: `${options.name}/${options.modelId}`,
    label: `Ollama - ${options.modelId}`,
    configSchema: ollamaConfigSchema,
    // `no-tools`: Mit Werkzeugen simuliert Genkit die strukturierte Ausgabe über Prompt-Anweisungen, denn eine
    // `format`-Grammatik ließe das Modell keine Werkzeuge mehr aufrufen.
    supports: {
      multiturn: true, media: true, systemRole: true, tools: true,
      output: ["text", "json"], constrained: "no-tools" as const,
    },
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
    messages: messagesForOllama(request.messages),
    tools: toolsForOllama(request.tools),
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
