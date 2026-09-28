import {
  type LocalRuntimeRequest,
  type LocalRuntimeRequestHandler,
  type LocalRuntimeResponse,
  type LocalRuntimeStreamRequest,
  type LocalRuntimeStreamRequestHandler,
} from "./local-runtime-http-server.js";
import {type LocalRuntimeSessionStore} from "./local-runtime-session-store.js";

const unauthenticatedPaths = new Set(["/v1/auth/login", "/v1/setup"]);

/**
 * Verlangt für jede Anfrage ein gültiges `Authorization: Bearer <token>`.
 * Wrapt den fertigen Composition-Router — Passwort-Pflicht gilt
 * ausnahmslos, auch im LAN (bewusster Breaking Change).
 *
 * Zwei Ausnahmen, beide notwendig und anders geschützt:
 * - `/v1/auth/login` erzeugt die Session überhaupt erst.
 * - `/v1/setup` setzt das Passwort, das man für eine Session bräuchte —
 *   Henne und Ei. Dort schützt stattdessen der Kopplungscode aus dem
 *   Start-Log (siehe `LocalRuntimeSetupHttpHandler`).
 */
export class LocalRuntimeSessionAuthGate
implements LocalRuntimeRequestHandler, LocalRuntimeStreamRequestHandler {
  constructor(
    private readonly sessions: LocalRuntimeSessionStore,
    private readonly inner: LocalRuntimeRequestHandler,
  ) {}

  async handle(request: LocalRuntimeRequest): Promise<LocalRuntimeResponse | null> {
    if (unauthenticatedPaths.has(request.url ?? "")) return this.inner.handle(request);
    const unauthorized = await this.rejectionFor(bearerTokenFrom(request.headers));
    if (unauthorized) return unauthorized;
    return this.inner.handle(request);
  }

  async handleStream(request: LocalRuntimeStreamRequest): Promise<LocalRuntimeResponse | null> {
    if (!isStreamHandler(this.inner)) return null;
    const unauthorized = await this.rejectionFor(bearerTokenFrom(request.headers));
    if (unauthorized) return unauthorized;
    return this.inner.handleStream(request);
  }

  private async rejectionFor(token: string | null): Promise<LocalRuntimeResponse | null> {
    const valid = token !== null && await this.sessions.verifySession(token);
    return valid ? null : {body: {error: "Anmeldung erforderlich."}, statusCode: 401};
  }
}

function bearerTokenFrom(
  headers: Readonly<Record<string, string | readonly string[] | undefined>> | undefined,
): string | null {
  const value = headers?.authorization;
  const header = Array.isArray(value) ? value[0] : value;
  if (typeof header !== "string" || !header.startsWith("Bearer ")) return null;
  const token = header.slice("Bearer ".length).trim();
  return token.length > 0 ? token : null;
}

function isStreamHandler(
  handler: LocalRuntimeRequestHandler,
): handler is LocalRuntimeRequestHandler & LocalRuntimeStreamRequestHandler {
  return "handleStream" in handler;
}
