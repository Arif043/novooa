import { type FastifyInstance, type FastifyReply } from "fastify";
import { type SignedRuntimeLicense } from "../../../licensing/domain/entities/runtime-license-lease.js";
import { type RuntimeMailRelayClient } from "./runtime-mail-relay-client.js";
export class LocalMailRelayHttpHandler {
  static registerRoutes(http: FastifyInstance, current: () => LocalMailRelayHttpHandler): void {
    http.post("/v1/mail-connectors/microsoft/authorization", (request, reply) => current().beginAuthorization(reply));
    http.get("/v1/mail-relay/dead-letters", (request, reply) => current().deadLetters(reply));
    http.post<{
      Params: {
        eventId: string;
      };
    }>("/v1/mail-relay/dead-letters/:eventId/replay", (request, reply) => current().replay(request.params.eventId, reply));
  }
  constructor(private readonly signedLicense: () => SignedRuntimeLicense | null, private readonly relay: RuntimeMailRelayClient) { }
  private async beginAuthorization(reply: FastifyReply): Promise<FastifyReply> {
    const license = this.activeLicense();
    const authorization = await this.relay.beginMicrosoftAuthorization(license);
    return reply.code(200).send(authorization);
  }
  private async deadLetters(reply: FastifyReply): Promise<FastifyReply> {
    const items = await this.relay.listDeadLetters(this.activeLicense());
    return reply.code(200).send({ items });
  }
  private async replay(eventId: string, reply: FastifyReply): Promise<FastifyReply> {
    await this.relay.replayDeadLetter(this.activeLicense(), eventId);
    return reply.code(200).send({ status: "ok" });
  }
  private activeLicense(): SignedRuntimeLicense {
    const license = this.signedLicense();
    if (license === null)
      throw new Error("Die lokale Runtime hat keine aktive Lizenz.");
    return license;
  }
}
