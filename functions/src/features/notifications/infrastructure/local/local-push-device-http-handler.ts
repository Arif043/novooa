import { type FastifyInstance, type FastifyReply } from "fastify";
import { type SignedRuntimeLicense } from "../../../licensing/domain/entities/runtime-license-lease.js";
import { type RuntimePushRelayClient, } from "./runtime-push-relay-client.js";
export class LocalPushDeviceHttpHandler {
  static registerRoutes(http: FastifyInstance, current: () => LocalPushDeviceHttpHandler): void {
    http.post("/v1/push-devices", (request, reply) => current().register(request.body, reply));
    http.post("/v1/push-devices/remove", (request, reply) => current().remove(request.body, reply));
  }
  constructor(private readonly signedLicense: () => SignedRuntimeLicense | null, private readonly relay: RuntimePushRelayClient) { }
  private async register(body: unknown, reply: FastifyReply): Promise<FastifyReply> {
    try {
      await this.relay.register(this.requiredLicense(), deviceFrom(body));
      return reply.code(200).send({ status: "registered" });
    }
    catch (error) {
      return errorResponse(error, reply);
    }
  }
  private async remove(body: unknown, reply: FastifyReply): Promise<FastifyReply> {
    try {
      await this.relay.remove(this.requiredLicense(), tokenFrom(body));
      return reply.code(200).send({ status: "removed" });
    }
    catch (error) {
      return errorResponse(error, reply);
    }
  }
  private requiredLicense(): SignedRuntimeLicense {
    const license = this.signedLicense();
    if (license === null)
      throw new LocalPushDeviceRequestError("Die lokale Runtime benötigt eine gültige Lizenz.");
    return license;
  }
}
function deviceFrom(value: unknown): {
  token: string;
  platform: string;
} {
  const input = record(value);
  return { token: text(input.token, "token", 4096, 16), platform: text(input.platform, "platform", 40) };
}
function tokenFrom(value: unknown): string {
  return text(record(value).token, "token", 4096, 16);
}
function record(value: unknown): Record<string, unknown> {
  if (value !== null && typeof value === "object" && !Array.isArray(value)) {
    return value as Record<string, unknown>;
  }
  throw new LocalPushDeviceRequestError("Die Push-Geräteanfrage ist ungültig.");
}
function text(value: unknown, name: string, max: number, min = 1): string {
  if (typeof value !== "string" || value.trim().length < min || value.length > max) {
    throw new LocalPushDeviceRequestError(`${name} ist ungültig.`);
  }
  return value.trim();
}
function errorResponse(error: unknown, reply: FastifyReply): FastifyReply {
  const message = error instanceof Error ? error.message : "Das Push-Gerät konnte nicht registriert werden.";
  const statusCode = error instanceof LocalPushDeviceRequestError ? 400 : 503;
  return reply.code(statusCode).send({ error: message });
}
class LocalPushDeviceRequestError extends Error {
}
