import {type FastifyPluginAsyncTypebox, Type} from "@fastify/type-provider-typebox";
import {type FastifyReply} from "fastify";
import {ErrorResponse, IdParams, ItemsOf} from "../../../../shared/local/local-runtime-http-schemas.js";
import {connectionInputFrom, connectionSecretFrom} from "../../domain/entities/connection-request.js";
import {ConnectionNotFoundError, ConnectionRequestError} from "../../domain/entities/connection.js";
import {type ConnectionStore} from "../../domain/repositories/connection-store.js";

export type ConnectionRoutesOptions = {
  store: ConnectionStore;
  notifier: {publish(topic: string): void};
};

const Auth = Type.Object({
  kind: Type.String({maxLength: 40}),
  headerName: Type.Optional(Type.String({maxLength: 100})),
  tokenUrl: Type.Optional(Type.String({maxLength: 2048})),
  clientId: Type.Optional(Type.String({maxLength: 500})),
  scope: Type.Optional(Type.String({maxLength: 500})),
});
const ConnectionDto = Type.Object({
  id: Type.String(), name: Type.String(), baseUrl: Type.String(), auth: Auth, updatedAt: Type.String(),
});
const ConnectionBody = Type.Object({
  name: Type.String({maxLength: 200}),
  baseUrl: Type.String({maxLength: 2048}),
  auth: Auth,
  /** Beim Anlegen Pflicht; beim Ändern nur zum Ersetzen. */
  secret: Type.Optional(Type.String({maxLength: 5000})),
});
const failures = {400: ErrorResponse, 404: ErrorResponse};

export const connectionRoutes: FastifyPluginAsyncTypebox<ConnectionRoutesOptions> = async (app, options) => {
  const {store, notifier} = options;

  app.get("/v1/connections", {schema: {response: {200: ItemsOf(ConnectionDto)}}},
    async (request) => ({items: await store.list(request.workspace.teamId)}));

  app.post("/v1/connections", {schema: {body: ConnectionBody, response: {...failures, 201: ConnectionDto}}},
    async (request, reply) => {
      try {
        const created = await store.create(request.workspace.teamId, connectionInputFrom(request.body), connectionSecretFrom(request.body.secret));
        notifier.publish("connections");
        return reply.code(201).send(created);
      } catch (error) {
        return failure(error, reply);
      }
    });

  app.put("/v1/connections/:connectionId", {
    schema: {params: IdParams("connectionId"), body: ConnectionBody, response: {...failures, 200: ConnectionDto}},
  }, async (request, reply) => {
    try {
      const secret = (request.body.secret ?? "").trim() === "" ? undefined : connectionSecretFrom(request.body.secret);
      const updated = await store.update(request.workspace.teamId, request.params.connectionId, connectionInputFrom(request.body), secret);
      notifier.publish("connections");
      return updated;
    } catch (error) {
      return failure(error, reply);
    }
  });

  app.delete("/v1/connections/:connectionId", {
    schema: {params: IdParams("connectionId"), response: {200: Type.Object({})}},
  }, async (request) => {
    await store.delete(request.workspace.teamId, request.params.connectionId);
    notifier.publish("connections");
    return {};
  });
};

function failure(error: unknown, reply: FastifyReply): FastifyReply {
  if (error instanceof ConnectionRequestError) return reply.code(400).send({error: error.message});
  if (error instanceof ConnectionNotFoundError) return reply.code(404).send({error: error.message});
  throw error;
}
