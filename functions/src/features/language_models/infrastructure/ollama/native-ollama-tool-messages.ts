import {type GenerateRequest, type Part} from "genkit/model";
import {
  type NativeOllamaChatResponse,
  type NativeOllamaMessage,
  type NativeOllamaTool,
} from "./native-ollama-chat-client.js";

type GenkitMessage = GenerateRequest["messages"][number];

/** Übersetzt Genkits Werkzeugdefinitionen in Ollamas `tools`. */
export function toolsForOllama(tools: GenerateRequest["tools"]): NativeOllamaTool[] {
  return (tools ?? []).map((tool) => ({
    type: "function",
    function: {name: tool.name, description: tool.description, parameters: tool.inputSchema ?? {type: "object"}},
  }));
}

/**
 * Übersetzt Genkits Verlauf in Ollamas Nachrichten. Werkzeugaufrufe des Modells werden `tool_calls`;
 * eine Genkit-Tool-Nachricht mit mehreren Ergebnissen wird je Ergebnis eine Ollama-`tool`-Nachricht.
 */
export function messagesForOllama(messages: GenkitMessage[]): NativeOllamaMessage[] {
  return messages.flatMap((message) => message.role === "tool" ? toolResultsFor(message) : [messageFor(message)]);
}

/** Die Antwort als Genkit-Teile: Text und Werkzeugaufrufe, die Genkits Werkzeugschleife ausführt. */
export function contentFromOllama(response: NativeOllamaChatResponse): Part[] {
  const text = response.content.length > 0 ? [{text: response.content}] : [];
  const toolRequests = response.toolCalls.map((call, index) => ({
    toolRequest: {name: call.name, ref: `call-${index}`, input: call.arguments},
  }));
  return [...text, ...toolRequests];
}

function messageFor(message: GenkitMessage): NativeOllamaMessage {
  const toolCalls = message.content.flatMap((part) => part.toolRequest
    ? [{name: part.toolRequest.name, arguments: argumentsOf(part.toolRequest.input)}]
    : []);
  return {
    role: message.role === "model" ? "assistant" : message.role,
    content: message.content.flatMap((part) => part.text ? [part.text] : []).join(""),
    mediaUrls: message.content.flatMap((part) => part.media ? [part.media.url] : []),
    ...(toolCalls.length > 0 ? {toolCalls} : {}),
  };
}

function toolResultsFor(message: GenkitMessage): NativeOllamaMessage[] {
  return message.content.flatMap((part) => part.toolResponse ? [{
    role: "tool" as const,
    content: contentOf(part.toolResponse.output),
    mediaUrls: [],
    toolName: part.toolResponse.name,
  }] : []);
}

function contentOf(output: unknown): string {
  return typeof output === "string" ? output : JSON.stringify(output ?? null);
}

function argumentsOf(input: unknown): Record<string, unknown> {
  return input !== null && typeof input === "object" && !Array.isArray(input) ? input as Record<string, unknown> : {};
}
