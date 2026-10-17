import {
  ModelProviderUnavailableError,
  ModelRequestRejectedError,
  ModelTimeoutError,
} from "../errors/language-model-errors.js";

/** Laufzeitoptionen von Ollama (`options` in `/api/chat`); fehlende Werte bestimmt das Modell. */
export type OllamaRuntimeOptions = {
  num_ctx?: number;
  num_predict?: number;
  temperature?: number;
  top_k?: number;
  top_p?: number;
  stop?: string[];
};

/** `true`/`false` schaltet Nachdenken; Stufen verstehen nur Modelle, die sie anbieten. */
export type OllamaThinking = boolean | "low" | "medium" | "high";

export type NativeOllamaChatRequest = {
  baseUrl: string;
  modelId: string;
  messages: NativeOllamaMessage[];
  format?: Record<string, unknown>;
  options?: OllamaRuntimeOptions;
  think?: OllamaThinking;
};

export type NativeOllamaMessage = {
  role: "system" | "user" | "assistant" | "tool";
  content: string;
  mediaUrls: string[];
};

export type NativeOllamaChatResponse = {
  content: string;
  thinking: string;
  /** `stop` = fertig, `length` = Kontextfenster oder `num_predict` erschöpft. */
  doneReason: string;
};

// Lokale Modelle mit Nachdenken brauchen für ein Bild schnell mehrere tausend
// Tokens; bei ~50 Tokens/s sind zwei Minuten zu knapp.
const requestTimeoutMs = 600000;

export class NativeOllamaChatClient {
  constructor(private readonly request: typeof fetch = fetch) {}

  async chat(input: NativeOllamaChatRequest): Promise<NativeOllamaChatResponse> {
    const response = await this.send(input);
    if (!response.ok) throw await httpErrorFor(response);
    return chatResponseFrom(await response.json());
  }

  private async send(input: NativeOllamaChatRequest): Promise<Response> {
    const init = requestFor(input);
    try {
      return await this.request(chatUrl(input.baseUrl), init);
    } catch (error) {
      if (isTimeout(error)) {
        throw new ModelTimeoutError(`Ollama hat nicht innerhalb von ${requestTimeoutMs / 1000} s geantwortet.`, error);
      }
      throw new ModelProviderUnavailableError("Ollama ist nicht erreichbar.", error);
    }
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
      ...(hasOptions(input.options) ? {options: input.options} : {}),
      ...(input.think === undefined ? {} : {think: input.think}),
    }),
    signal: AbortSignal.timeout(requestTimeoutMs),
  };
}

function hasOptions(options: OllamaRuntimeOptions | undefined): options is OllamaRuntimeOptions {
  return options !== undefined && Object.values(options).some((value) => value !== undefined);
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
  if (!match) throw new ModelRequestRejectedError("Ollama erwartet Bilddaten als Data-URL.");
  return match[1].replace(/[\r\n]/g, "");
}

async function httpErrorFor(response: Response): Promise<Error> {
  const body = await response.text();
  const message = `Ollama-Anfrage fehlgeschlagen (${response.status}): ${body || response.statusText}`;
  return response.status >= 500
    ? new ModelProviderUnavailableError(message)
    : new ModelRequestRejectedError(message);
}

function chatResponseFrom(value: unknown): NativeOllamaChatResponse {
  if (!isRecord(value) || !isRecord(value.message) || typeof value.message.content !== "string") {
    throw new ModelProviderUnavailableError("Ollama lieferte keine Textantwort.");
  }
  return {
    content: value.message.content,
    thinking: typeof value.message.thinking === "string" ? value.message.thinking : "",
    doneReason: typeof value.done_reason === "string" ? value.done_reason : "stop",
  };
}

function isTimeout(error: unknown): boolean {
  return error instanceof Error && (error.name === "TimeoutError" || error.name === "AbortError");
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}
