import {
  type LocalRuntimeRequest,
  type LocalRuntimeRequestHandler,
  type LocalRuntimeResponse,
} from "./local-runtime-http-server.js";
import {
  LocalRuntimeAccessCredentialStore,
  RuntimeAccessCredentialAlreadySetError,
} from "./local-runtime-access-credential-store.js";

/**
 * `GET`/`POST /v1/setup` — einmaliges Setzen des Betreiber-Passworts.
 *
 * Dieser Handler prüft absichtlich NICHT die Quell-IP der Anfrage: Docker-
 * NAT liefert je nach Runtime (Docker Desktop, OrbStack, natives Linux
 * Bridging) unterschiedliche, teils mit echten LAN-Bereichen überlappende
 * Absenderadressen — IP-basierte "ist das localhost"-Prüfung im Code ist
 * dadurch unzuverlässig. Die Zugriffsbeschränkung passiert stattdessen eine
 * Ebene tiefer: Dieser Handler wird ausschließlich über einen zweiten
 * HTTP-Server verdrahtet, den der Entrypoint nur an `127.0.0.1` bindet
 * (`local-runtime-entrypoint.ts`) — durchgesetzt vom Docker-Host selbst über
 * die Port-Publizierung `127.0.0.1:<port>:<port>`, nicht durch App-Code.
 */
export class LocalRuntimeSetupHttpHandler implements LocalRuntimeRequestHandler {
  constructor(private readonly credentials: LocalRuntimeAccessCredentialStore) {}

  async handle(request: LocalRuntimeRequest): Promise<LocalRuntimeResponse | null> {
    if (request.url !== "/v1/setup") return null;
    if (request.method === "GET") return this.status();
    if (request.method === "POST") return this.setup(request.body);
    return null;
  }

  private async status(): Promise<LocalRuntimeResponse> {
    const needsSetup = !(await this.credentials.hasCredential());
    return {body: {needsSetup}, statusCode: 200};
  }

  private async setup(body: unknown): Promise<LocalRuntimeResponse> {
    try {
      await this.credentials.setPassword(passwordFrom(body));
      return {body: {status: "configured"}, statusCode: 204};
    } catch (error) {
      if (error instanceof RuntimeAccessCredentialAlreadySetError) {
        return {body: {error: error.message}, statusCode: 409};
      }
      return {body: {error: messageFrom(error)}, statusCode: 400};
    }
  }
}

function passwordFrom(value: unknown): string {
  if (value !== null && typeof value === "object" && !Array.isArray(value)) {
    const password = (value as Record<string, unknown>).password;
    if (typeof password === "string" && password.length > 0) return password;
  }
  throw new Error("password muss ein nicht leerer String sein.");
}

function messageFrom(error: unknown): string {
  return error instanceof Error ? error.message : "Die Anfrage konnte nicht verarbeitet werden.";
}
