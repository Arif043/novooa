import {genkitPlugin, type GenkitPlugin} from "genkit/plugin";
import {
  GenerationCommonConfigSchema,
  getBasicUsageStats,
  type GenerateRequest,
} from "genkit/model";
import {
  NativeOllamaChatClient,
  type NativeOllamaChatRequest,
} from "./native-ollama-chat-client.js";

export interface OllamaChatClient {
  chat(input: NativeOllamaChatRequest): Promise<string>;
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
      const message = await messageFor(request, options);
      return {message, usage: getBasicUsageStats(request.messages, message), finishReason: "stop"};
    });
  });
}

function modelDefinitionFor(options: NativeOllamaPluginOptions) {
  return {
    name: `${options.name}/${options.modelId}`,
    label: `Ollama - ${options.modelId}`,
    configSchema: GenerationCommonConfigSchema,
    supports: {multiturn: true, media: true, systemRole: true, output: ["text", "json"], constrained: "all" as const},
  };
}

async function messageFor(
  request: GenerateRequest,
  options: NativeOllamaPluginOptions,
) {
  const content = await (options.chatClient ?? new NativeOllamaChatClient()).chat({
    baseUrl: options.serverAddress,
    modelId: options.modelId,
    messages: request.messages.map(messageForOllama),
    format: jsonSchemaFor(request),
  });
  return {role: "model" as const, content: [{text: content}]};
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

function jsonSchemaFor(request: GenerateRequest): Record<string, unknown> | undefined {
  const schema = request.output?.schema;
  return isRecord(schema) ? schema : undefined;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}
