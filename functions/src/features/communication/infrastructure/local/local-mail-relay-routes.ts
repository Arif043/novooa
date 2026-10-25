import {type FastifyPluginAsyncTypebox, Type} from "@fastify/type-provider-typebox";
import {IdParams, ItemsOf, StatusResponse} from "../../../../shared/local/local-runtime-http-schemas.js";
import {type SignedRuntimeLicense} from "../../../licensing/domain/entities/runtime-license-lease.js";
import {type RelayListCache} from "../../../../shared/local/relay-list-cache.js";
import {type MailConnectorSummary} from "../../domain/entities/mail-connector-summary.js";
import {type RuntimeMailRelayClient} from "./runtime-mail-relay-client.js";

export type MailRelayRoutesOptions = {
  signedLicense: () => SignedRuntimeLicense | null;
  relay: Pick<RuntimeMailRelayClient, "beginMicrosoftAuthorization" | "listConnectors" | "listDeadLetters" | "replayDeadLetter">;
  connectorCache: RelayListCache<MailConnectorSummary>;
};

const DeadLetter = Type.Object({
  eventId: Type.String(), connectorId: Type.String(), event: Type.Unknown(), createdAt: Type.String(),
  attempts: Type.Integer(), failedAt: Type.String(), lastError: Type.String(),
  replayedAt: Type.Union([Type.String(), Type.Null()]),
});

const MailConnector = Type.Object({
  id: Type.String(), teamId: Type.String(), emailAddress: Type.String(), displayName: Type.String(),
  status: Type.Union([Type.Literal("active"), Type.Literal("reauthorizationRequired"), Type.Literal("disconnected")]),
});

export const mailRelayRoutes: FastifyPluginAsyncTypebox<MailRelayRoutesOptions> = async (app, {signedLicense, relay, connectorCache}) => {
  const activeLicense = (): SignedRuntimeLicense => {
    const license = signedLicense();
    if (license === null) throw new Error("Die lokale Runtime hat keine aktive Lizenz.");
    return license;
  };

  app.post("/v1/mail-connectors/microsoft/authorization", {
    schema: {response: {200: Type.Object({authorizationUrl: Type.String()})}},
  }, async () => relay.beginMicrosoftAuthorization(activeLicense()));

  app.get("/v1/mail-connectors", {
    schema: {response: {200: ItemsOf(MailConnector)}},
  }, async () => {
    const license = activeLicense();
    return {items: await connectorCache.list(license, () => relay.listConnectors(license))};
  });

  app.get("/v1/mail-relay/dead-letters", {
    schema: {response: {200: ItemsOf(DeadLetter)}},
  }, async () => ({items: await relay.listDeadLetters(activeLicense())}));

  app.post("/v1/mail-relay/dead-letters/:eventId/replay", {
    schema: {params: IdParams("eventId"), response: {200: StatusResponse}},
  }, async (request) => {
    await relay.replayDeadLetter(activeLicense(), request.params.eventId);
    return {status: "ok"};
  });
};
