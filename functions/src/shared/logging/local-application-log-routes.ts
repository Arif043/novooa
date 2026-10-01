import {type FastifyPluginAsyncTypebox, Type} from "@fastify/type-provider-typebox";
import {randomUUID} from "node:crypto";
import {ErrorResponse, ItemsOf, JsonObject} from "../local/local-runtime-http-schemas.js";
import {type LocalApplicationLogStore} from "./local-application-log-store.js";

export type ApplicationLogRoutesOptions = {
  store: LocalApplicationLogStore;
  notifier: {publish(topic: string): void};
};

const maximumDataLength = 16000;

const ApplicationLog = Type.Object({
  id: Type.String(), source: Type.String(), level: Type.String(), event: Type.String(),
  message: Type.Union([Type.String(), Type.Null()]), data: JsonObject, occurredAt: Type.String(),
});
const ClientLog = Type.Object({
  level: Type.Union([Type.Literal("info"), Type.Literal("error")]),
  event: Type.String({pattern: "^[a-z0-9._-]{1,120}$"}),
  message: Type.Optional(Type.Union([Type.String({maxLength: 4000}), Type.Null()])),
  data: Type.Optional(JsonObject),
});

export const applicationLogRoutes: FastifyPluginAsyncTypebox<ApplicationLogRoutesOptions> = async (app, {store, notifier}) => {
  app.get("/v1/application-logs", {schema: {response: {200: ItemsOf(ApplicationLog)}}}, async (request) => {
    const logs = await store.recent(request.workspace.teamId, 100);
    return {items: logs.map(({id, source, level, event, message, data, occurredAt}) =>
      ({id, source, level, event, message, data, occurredAt}))};
  });

  /** Quelle, ID und Zeitstempel vergibt die Runtime — der Client liefert nur den Inhalt. */
  app.post("/v1/application-logs", {
    schema: {body: ClientLog, response: {202: Type.Object({}), 400: ErrorResponse}},
  }, async (request, reply) => {
    const data = request.body.data ?? {};
    if (JSON.stringify(data).length > maximumDataLength) {
      return reply.code(400).send({error: "Die Protokolldaten sind zu groß."});
    }
    await store.append({
      id: randomUUID(), teamId: request.workspace.teamId, source: "client", level: request.body.level,
      event: request.body.event, message: request.body.message ?? null, data, occurredAt: new Date().toISOString(),
    });
    notifier.publish("application-logs");
    return reply.code(202).send({});
  });
};
