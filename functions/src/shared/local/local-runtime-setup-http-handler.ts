import {
  type LocalRuntimeRequest,
  type LocalRuntimeRequestHandler,
  type LocalRuntimeResponse,
} from "./local-runtime-http-server.js";
import {
  LocalRuntimeAccessCredentialStore,
  RuntimeAccessCredentialAlreadySetError,
} from "./local-runtime-access-credential-store.js";
import {type LocalRuntimeSetupCode} from "./local-runtime-setup-code.js";
import {reachableAddresses} from "./local-runtime-reachable-addresses.js";

export type LocalRuntimeSetupHttpHandlerOptions = {
  credentials: LocalRuntimeAccessCredentialStore;
  setupCode: LocalRuntimeSetupCode;
  /**
   * Auf dem regulären Port ersetzt der Kopplungscode die fehlende
   * Netzwerkgrenze. Auf dem host-loopback-gebundenen Setup-Port ist er
   * nicht nötig — dort *ist* die Netzwerkgrenze der Schutz.
   */
  requiresCode: boolean;
};

/**
 * `GET`/`POST /v1/setup` — einmaliges Setzen des Betreiber-Passworts.
 *
 * Erreichbar auf zwei Wegen mit unterschiedlichem Schutz:
 *
 * - **Regulärer Port**: verlangt den Kopplungscode aus dem Start-Log. Damit
 *   lässt sich eine headless installierte Runtime von jedem Client aus
 *   einrichten, ohne SSH-Portweiterleitung.
 * - **Setup-Port (`127.0.0.1`)**: ohne Code. Dieser Handler prüft
 *   absichtlich NICHT die Quell-IP — Docker-NAT liefert je nach Runtime
 *   unterschiedliche, teils mit echten LAN-Bereichen überlappende
 *   Absenderadressen. Die Beschränkung passiert eine Ebene tiefer über die
 *   Port-Publizierung `127.0.0.1:<port>:<port>` des Docker-Hosts
 *   (`local-runtime-entrypoint.ts`), nicht durch App-Code.
 */
export class LocalRuntimeSetupHttpHandler implements LocalRuntimeRequestHandler {
  constructor(private readonly options: LocalRuntimeSetupHttpHandlerOptions) {}

  async handle(request: LocalRuntimeRequest): Promise<LocalRuntimeResponse | null> {
    if (request.url !== "/v1/setup") return null;
    if (request.method === "GET") return this.status(request);
    if (request.method === "POST") return this.setup(request.body);
    return null;
  }

  /**
   * Der Port kommt aus dem `Host`-Header der Anfrage, nicht aus der
   * Konfiguration: Im Container lauscht die Runtime auf 8080, Clients
   * sprechen aber den vom Docker-Host veröffentlichten 8090 an. Der
   * Browser weiß als Einziger verlässlich, welcher es war.
   */
  private async status(request: LocalRuntimeRequest): Promise<LocalRuntimeResponse> {
    const needsSetup = !(await this.options.credentials.hasCredential());
    return {
      body: {
        needsSetup,
        requiresCode: this.options.requiresCode,
        addresses: reachableAddresses(requestPortFrom(request.headers)),
      },
      statusCode: 200,
    };
  }

  private async setup(body: unknown): Promise<LocalRuntimeResponse> {
    if (this.options.requiresCode && !this.options.setupCode.matches(codeFrom(body))) {
      return {
        body: {error: "Der Einrichtungscode stimmt nicht."},
        statusCode: 403,
      };
    }
    try {
      await this.options.credentials.setPassword(passwordFrom(body));
      // Nach erfolgreicher Einrichtung hat der Code keinen Zweck mehr und
      // wäre nur noch Angriffsfläche.
      this.options.setupCode.consume();
      return {body: {status: "configured"}, statusCode: 204};
    } catch (error) {
      if (error instanceof RuntimeAccessCredentialAlreadySetError) {
        return {body: {error: error.message}, statusCode: 409};
      }
      return {body: {error: messageFrom(error)}, statusCode: 400};
    }
  }
}

/** Fällt auf den veröffentlichten Standardport zurück, wenn kein Port im
 * `Host`-Header steht (etwa hinter einem Reverse Proxy auf 443). */
function requestPortFrom(
  headers: Readonly<Record<string, string | readonly string[] | undefined>> | undefined,
): number {
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
    if (typeof password === "string" && password.length > 0) return password;
  }
  throw new Error("password muss ein nicht leerer String sein.");
}

function messageFrom(error: unknown): string {
  return error instanceof Error ? error.message : "Die Anfrage konnte nicht verarbeitet werden.";
}
