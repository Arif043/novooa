import {type FastifyPluginAsyncTypebox, Type} from "@fastify/type-provider-typebox";
import {type FastifyReply} from "fastify";
import {ErrorResponse, StatusResponse} from "../../../../shared/local/local-runtime-http-schemas.js";
import {type SignedRuntimeLicense} from "../../../licensing/domain/entities/runtime-license-lease.js";
import {type RuntimePushRelayClient} from "./runtime-push-relay-client.js";

export type PushDeviceRoutesOptions = {
  signedLicense: () => SignedRuntimeLicense | null;
  relay: Pick<RuntimePushRelayClient, "register" | "remove">;
};

const PushToken = Type.String({minLength: 16, maxLength: 4096});
const responses = {200: StatusResponse, 400: ErrorResponse, 503: ErrorResponse};

/** Registriert FCM-Geräte über den novooa-Relay; der Relay prüft die signierte Lizenz. */
export const pushDeviceRoutes: FastifyPluginAsyncTypebox<PushDeviceRoutesOptions> = async (app, {signedLicense, relay}) => {
  app.post("/v1/push-devices", {
    schema: {body: Type.Object({token: PushToken, platform: Type.String({minLength: 1, maxLength: 40})}), response: responses},
  }, async (request, reply) => withLicense(signedLicense, reply, async (license) => {
    await relay.register(license, {token: request.body.token.trim(), platform: request.body.platform.trim()});
    return reply.code(200).send({status: "registered"});
  }));

  app.post("/v1/push-devices/remove", {
    schema: {body: Type.Object({token: PushToken}), response: responses},
  }, async (request, reply) => withLicense(signedLicense, reply, async (license) => {
    await relay.remove(license, request.body.token.trim());
    return reply.code(200).send({status: "removed"});
  }));
};

async function withLicense(
  signedLicense: () => SignedRuntimeLicense | null,
  reply: FastifyReply,
  action: (license: SignedRuntimeLicense) => Promise<FastifyReply>,
): Promise<FastifyReply> {
  const license = signedLicense();
  if (license === null) return reply.code(400).send({error: "Die lokale Runtime benötigt eine gültige Lizenz."});
  try {
    return await action(license);
  } catch (error) {
    const message = error instanceof Error ? error.message : "Das Push-Gerät konnte nicht registriert werden.";
    return reply.code(503).send({error: message});
  }
}
