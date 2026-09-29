import {
  type LocalRuntimeRequest,
  type LocalRuntimeRequestHandler,
  type LocalRuntimeResponse,
} from "../../../../shared/local/local-runtime-http-server.js";
import {type LocalRuntimeRealtimeNotifier} from "../../../../shared/local/local-runtime-realtime-notifier.js";
import {routeMatch} from "../../../../shared/local/local-runtime-route.js";
import {type LanguageModelDefaults} from "../../domain/entities/language-model-defaults.js";
import {type LanguageModelDefaultsStore} from "../../domain/repositories/language-model-defaults-store.js";

/**
 * Eigene, kleine Datei statt Erweiterung von `local-language-model-http-handler.ts`
 * (dort geht es um Modell-/Verbindungs-CRUD, hier nur um einen Vorgabe-Zeiger
 * auf bereits vorhandene Modelle — andere Zuständigkeit, kein Geheimnis).
 */
export class LocalLanguageModelDefaultsHttpHandler implements LocalRuntimeRequestHandler {
  constructor(
    private readonly store: LanguageModelDefaultsStore,
    private readonly teamId: string,
    private readonly notifier: LocalRuntimeRealtimeNotifier,
  ) {}

  async handle(request: LocalRuntimeRequest): Promise<LocalRuntimeResponse | null> {
    if (routeMatch(request, "GET", "/v1/language-model-defaults")) return this.load();
    if (routeMatch(request, "PUT", "/v1/language-model-defaults")) return this.save(request.body);
    return null;
  }

  private async load(): Promise<LocalRuntimeResponse> {
    const defaults = await this.store.loadDefaults(this.teamId);
    return {body: defaults, statusCode: 200};
  }

  private async save(body: unknown): Promise<LocalRuntimeResponse> {
    try {
      const defaults = defaultsFrom(body);
      await this.store.saveDefaults(this.teamId, defaults);
      this.notifier.publish("language-model-defaults");
      return {body: defaults, statusCode: 200};
    } catch (error) {
      const message = error instanceof Error
        ? error.message
        : "Die Vorgabe konnte nicht gespeichert werden.";
      return {body: {error: message}, statusCode: 400};
    }
  }
}

function defaultsFrom(body: unknown): LanguageModelDefaults {
  if (body === null || typeof body !== "object" || Array.isArray(body)) {
    throw new Error("Die Vorgabe erwartet ein Objekt.");
  }
  const value = body as Record<string, unknown>;
  return {
    blockModelId: optionalString(value.blockModelId, "blockModelId"),
    assistantModelId: optionalString(value.assistantModelId, "assistantModelId"),
  };
}

function optionalString(value: unknown, name: string): string | null {
  if (value === null || value === undefined) return null;
  if (typeof value === "string") return value.length > 0 ? value : null;
  throw new Error(`${name} muss ein String oder null sein.`);
}
