import {type FastifyPluginAsyncTypebox, Type} from "@fastify/type-provider-typebox";
import {type LanguageModelDefaultsStore} from "../../domain/repositories/language-model-defaults-store.js";

export type LanguageModelDefaultsRoutesOptions = {
  store: LanguageModelDefaultsStore;
  notifier: {publish(topic: string): void};
};

const OptionalModelId = Type.Union([Type.String({maxLength: 200}), Type.Null()]);
const LanguageModelDefaultsSchema = Type.Object({blockModelId: OptionalModelId, knowledgeAssistantModelId: OptionalModelId});

/**
 * Eigenes Plugin statt Teil von `local-language-model-routes.ts`: Hier geht
 * es nur um einen Vorgabe-Zeiger auf bereits vorhandene Modelle — andere
 * Zuständigkeit, kein Geheimnis.
 */
export const languageModelDefaultsRoutes: FastifyPluginAsyncTypebox<LanguageModelDefaultsRoutesOptions> = async (app, {store, notifier}) => {
  app.get("/v1/language-model-defaults", {
    schema: {response: {200: LanguageModelDefaultsSchema}},
  }, async (request) => store.loadDefaults(request.workspace.teamId));

  app.put("/v1/language-model-defaults", {
    schema: {
      body: Type.Object({
        blockModelId: Type.Optional(OptionalModelId), knowledgeAssistantModelId: Type.Optional(OptionalModelId),
      }),
      response: {200: LanguageModelDefaultsSchema},
    },
  }, async (request) => {
    const defaults = {
      blockModelId: request.body.blockModelId || null,
      knowledgeAssistantModelId: request.body.knowledgeAssistantModelId || null,
    };
    await store.saveDefaults(request.workspace.teamId, defaults);
    notifier.publish("language-model-defaults");
    return defaults;
  });
};
