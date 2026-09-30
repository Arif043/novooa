import { type FastifyInstance, type FastifyReply } from "fastify";
import { type LocalRuntimeRealtimeNotifier } from "../../../../shared/local/local-runtime-realtime-notifier.js";
import { type LanguageModelDefaults } from "../../domain/entities/language-model-defaults.js";
import { type LanguageModelDefaultsStore } from "../../domain/repositories/language-model-defaults-store.js";
/**
 * Eigene, kleine Datei statt Erweiterung von `local-language-model-http-handler.ts`
 * (dort geht es um Modell-/Verbindungs-CRUD, hier nur um einen Vorgabe-Zeiger
 * auf bereits vorhandene Modelle — andere Zuständigkeit, kein Geheimnis).
 */
export class LocalLanguageModelDefaultsHttpHandler {
  static registerRoutes(http: FastifyInstance, current: () => LocalLanguageModelDefaultsHttpHandler): void {
    http.get("/v1/language-model-defaults", (request, reply) => current().load(reply));
    http.put("/v1/language-model-defaults", (request, reply) => current().save(request.body, reply));
  }
  constructor(private readonly store: LanguageModelDefaultsStore, private readonly teamId: string, private readonly notifier: LocalRuntimeRealtimeNotifier) { }
  private async load(reply: FastifyReply): Promise<FastifyReply> {
    const defaults = await this.store.loadDefaults(this.teamId);
    return reply.code(200).send(defaults);
  }
  private async save(body: unknown, reply: FastifyReply): Promise<FastifyReply> {
    try {
      const defaults = defaultsFrom(body);
      await this.store.saveDefaults(this.teamId, defaults);
      this.notifier.publish("language-model-defaults");
      return reply.code(200).send(defaults);
    }
    catch (error) {
      const message = error instanceof Error
        ? error.message
        : "Die Vorgabe konnte nicht gespeichert werden.";
      return reply.code(400).send({ error: message });
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
  if (value === null || value === undefined)
    return null;
  if (typeof value === "string")
    return value.length > 0 ? value : null;
  throw new Error(`${name} muss ein String oder null sein.`);
}
