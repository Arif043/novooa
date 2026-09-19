export type NativeOllamaChatRequest = {
  baseUrl: string;
  modelId: string;
  messages: NativeOllamaMessage[];
  format?: Record<string, unknown>;
};

export type NativeOllamaMessage = {
  role: "system" | "user" | "assistant" | "tool";
  content: string;
  mediaUrls: string[];
};

export class NativeOllamaChatClient {
  constructor(private readonly request: typeof fetch = fetch) {}

  async chat(input: NativeOllamaChatRequest): Promise<string> {
    const response = await this.request(chatUrl(input.baseUrl), requestFor(input));
    if (!response.ok) throw new Error(await errorMessageFor(response));
    return contentFrom(await response.json());
  }
}

function chatUrl(baseUrl: string): string {
  const url = new URL(baseUrl);
  url.pathname = "/api/chat";
  url.search = "";
  return url.toString();
}

function requestFor(input: NativeOllamaChatRequest): RequestInit {
  return {
    method: "POST",
    headers: {"content-type": "application/json"},
    body: JSON.stringify({
      model: input.modelId,
      messages: input.messages.map(messageFor),
      stream: false,
      ...(input.format ? {format: input.format} : {}),
    }),
    signal: AbortSignal.timeout(120000),
  };
}

function messageFor(message: NativeOllamaMessage) {
  const images = message.mediaUrls.map(imageFor);
  return {
    role: message.role,
    content: message.content,
    ...(images.length > 0 ? {images} : {}),
  };
}

function imageFor(mediaUrl: string): string {
  const match = /^data:image\/[a-z0-9.+-]+;base64,([a-z0-9+/=\r\n]+)$/i.exec(mediaUrl);
  if (!match) throw new Error("Ollama erwartet Bilddaten als Data-URL.");
  return match[1].replace(/[\r\n]/g, "");
}

async function errorMessageFor(response: Response): Promise<string> {
  const body = await response.text();
  return `Ollama-Anfrage fehlgeschlagen (${response.status}): ${body || response.statusText}`;
}

function contentFrom(value: unknown): string {
  if (!isRecord(value) || !isRecord(value.message) || typeof value.message.content !== "string") {
    throw new Error("Ollama lieferte keine Textantwort.");
  }
  return value.message.content;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}
