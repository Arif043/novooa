import {type FastifyPluginAsyncTypebox, Type} from "@fastify/type-provider-typebox";
import {ErrorResponse, IdParams, ItemsOf} from "../../../../shared/local/local-runtime-http-schemas.js";
import {languageModelProviders} from "../../domain/entities/language-model.js";
import {type LanguageModelConfigurationStore} from "../../domain/repositories/language-model-configuration-store.js";
import {type LanguageModelDiscovery, LocalLanguageModelDiscovery} from "./local-language-model-discovery.js";
import {connectionFrom, inputFrom, LocalLanguageModelRequestError} from "./local-language-model-request.js";

export type LanguageModelRoutesOptions = {
  store: LanguageModelConfigurationStore;
  notifier: {publish(topic: string): void};
  discovery?: LanguageModelDiscovery;
};

const Provider = Type.Enum(languageModelProviders);
const LanguageModelDto = Type.Object({
  id: Type.String(), teamId: Type.String(), connectionId: Type.String(), name: Type.String(), modelId: Type.String(),
  capabilities: Type.Object({
    textGeneration: Type.Boolean(), imageInput: Type.Boolean(), structuredOutput: Type.Boolean(),
    toolCalling: Type.Boolean(), imageGeneration: Type.Boolean(),
  }),
});
const ConnectionDto = Type.Object({
  id: Type.String(), teamId: Type.String(), name: Type.String(), provider: Provider, baseUrl: Type.Optional(Type.String()),
});
const ProviderAccess = {
  provider: Provider,
  baseUrl: Type.Optional(Type.String({maxLength: 2048})),
  apiKey: Type.Optional(Type.String({maxLength: 4096})),
};
const Connect = Type.Object(ProviderAccess);
const CreateModel = Type.Object({
  ...ProviderAccess,
  connectionName: Type.String({minLength: 1, maxLength: 120}),
  name: Type.String({minLength: 1, maxLength: 120}),
  languageModelId: Type.String({minLength: 1, maxLength: 200}),
});

export const languageModelRoutes: FastifyPluginAsyncTypebox<LanguageModelRoutesOptions> = async (app, options) => {
  const {store, notifier} = options;
  const discovery = options.discovery ?? new LocalLanguageModelDiscovery();

  app.get("/v1/language-model-connections", {schema: {response: {200: ItemsOf(ConnectionDto)}}},
    async (request) => ({items: await store.listConnections(request.workspace.teamId)}));

  app.get("/v1/language-models", {schema: {response: {200: ItemsOf(LanguageModelDto)}}},
    async (request) => ({items: await store.list(request.workspace.teamId)}));

  /** Prüft den Zugang, indem die Modelle beim Anbieter abgefragt werden. */
  app.post("/v1/language-model-connections", {
    schema: {body: Connect, response: {201: ItemsOf(LanguageModelDto), 400: ErrorResponse}},
  }, async (request, reply) => {
    try {
      const connection = connectionFrom(request.body, request.workspace.teamId);
      const models = await discovery.discover({provider: connection.connection.provider,
        baseUrl: connection.connection.baseUrl, apiKey: connection.apiKey});
      const saved = await store.saveConnection({...connection, models});
      notifier.publish("language-models");
      return reply.code(201).send({items: saved});
    } catch (error) {
      const message = error instanceof Error ? error.message : "Sprachmodell-Verbindung konnte nicht hergestellt werden.";
      return reply.code(400).send({error: message});
    }
  });

  app.delete("/v1/language-model-connections/:connectionId", {
    schema: {params: IdParams("connectionId"), response: {200: Type.Object({})}},
  }, async (request) => {
    await store.deleteConnection(request.workspace.teamId, request.params.connectionId);
    notifier.publish("language-models");
    return {};
  });

  app.post("/v1/language-models", {
    schema: {body: CreateModel, response: {201: LanguageModelDto, 400: ErrorResponse}},
  }, async (request, reply) => {
    try {
      const model = await store.save(inputFrom(request.body, request.workspace.teamId));
      notifier.publish("language-models");
      return reply.code(201).send(model);
    } catch (error) {
      if (!(error instanceof LocalLanguageModelRequestError)) throw error;
      return reply.code(400).send({error: error.message});
    }
  });
};
