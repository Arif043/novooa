import { type FastifyInstance, type FastifyReply, type FastifyRequest } from "fastify";
import { LocalRuntimeAccessCredentialStore, RuntimeAccessCredentialAlreadySetError, } from "./local-runtime-access-credential-store.js";
import { type LocalRuntimeSetupCode } from "./local-runtime-setup-code.js";
import { reachableAddresses } from "./local-runtime-reachable-addresses.js";
export type LocalRuntimeSetupHttpHandlerOptions = {
  credentials: LocalRuntimeAccessCredentialStore;
  setupCode: LocalRuntimeSetupCode;
};
/**
 * `GET`/`POST /v1/setup` — einmaliges Setzen des Betreiber-Passworts, über
 * den regulären Port. Verlangt dafür den Kopplungscode aus dem Start-Log
 * (`docker compose logs`) — der Vertrauensanker ist damit **Besitz eines
 * Geheimnisses**, nicht Netzwerkposition. Das erlaubt die Einrichtung einer
 * headless installierten Runtime (VPS, NAS, Raspberry Pi) von jedem Client
 * aus, ohne SSH-Portweiterleitung.
 */
export class LocalRuntimeSetupHttpHandler {
  static registerRoutes(http: FastifyInstance, current: () => LocalRuntimeSetupHttpHandler): void {
    http.get("/v1/setup", (request, reply) => current().status(request, reply));
    http.post("/v1/setup", (request, reply) => current().setup(request.body, reply));
  }
  constructor(private readonly options: LocalRuntimeSetupHttpHandlerOptions) { }
  /**
   * Der Port kommt aus dem `Host`-Header der Anfrage, nicht aus der
   * Konfiguration: Im Container lauscht die Runtime auf 8080, Clients
   * sprechen aber den vom Docker-Host veröffentlichten 8090 an. Der
   * Browser weiß als Einziger verlässlich, welcher es war.
   */
  private async status(request: FastifyRequest, reply: FastifyReply): Promise<FastifyReply> {
    const needsSetup = !(await this.options.credentials.hasCredential());
    return reply.code(200).send({
      needsSetup,
      addresses: reachableAddresses(requestPortFrom(request.headers)),
    });
  }
  private async setup(body: unknown, reply: FastifyReply): Promise<FastifyReply> {
    if (!this.options.setupCode.matches(codeFrom(body))) {
      return reply.code(403).send({ error: "Der Einrichtungscode stimmt nicht." });
    }
    try {
      await this.options.credentials.setPassword(passwordFrom(body));
      // Nach erfolgreicher Einrichtung hat der Code keinen Zweck mehr und
      // wäre nur noch Angriffsfläche.
      this.options.setupCode.consume();
      return reply.code(204).send();
    }
    catch (error) {
      if (error instanceof RuntimeAccessCredentialAlreadySetError) {
        return reply.code(409).send({ error: error.message });
      }
      return reply.code(400).send({ error: messageFrom(error) });
    }
  }
}
/** Fällt auf den veröffentlichten Standardport zurück, wenn kein Port im
 * `Host`-Header steht (etwa hinter einem Reverse Proxy auf 443). */
function requestPortFrom(headers: Readonly<Record<string, string | readonly string[] | undefined>> | undefined): number {
  const value = headers?.host;
  const host = Array.isArray(value) ? value[0] : value;
  const port = typeof host === "string" ? Number(host.split(":")[1]) : NaN;
  return Number.isSafeInteger(port) && port > 0 ? port : defaultPublishedPort;
}
const defaultPublishedPort = 8090;
function codeFrom(value: unknown): unknown {
  if (value !== null && typeof value === "object" && !Array.isArray(value)) {
    return (value as Record<string, unknown>).code;
  }
  return undefined;
}
function passwordFrom(value: unknown): string {
  if (value !== null && typeof value === "object" && !Array.isArray(value)) {
    const password = (value as Record<string, unknown>).password;
    if (typeof password === "string" && password.length > 0)
      return password;
  }
  throw new Error("password muss ein nicht leerer String sein.");
}
function messageFrom(error: unknown): string {
  return error instanceof Error ? error.message : "Die Anfrage konnte nicht verarbeitet werden.";
}
