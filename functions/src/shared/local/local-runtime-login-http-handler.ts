import {
  type LocalRuntimeRequest,
  type LocalRuntimeRequestHandler,
  type LocalRuntimeResponse,
} from "./local-runtime-http-server.js";
import {type LocalRuntimeAccessCredentialStore} from "./local-runtime-access-credential-store.js";
import {type LocalRuntimeSessionStore} from "./local-runtime-session-store.js";

/**
 * `POST /v1/auth/login` — tauscht das Betreiber-Passwort gegen ein
 * Session-Token. Bleibt bewusst außerhalb des
 * `LocalRuntimeSessionAuthGate` (sonst käme niemand an ein Token).
 * Läuft auf dem regulären, öffentlich erreichbaren API-Port — im
 * Unterschied zu `/v1/setup`, das ausschließlich über den separaten,
 * host-loopback-gebundenen Port erreichbar ist.
 */
export class LocalRuntimeLoginHttpHandler implements LocalRuntimeRequestHandler {
  constructor(
    private readonly credentials: LocalRuntimeAccessCredentialStore,
    private readonly sessions: LocalRuntimeSessionStore,
  ) {}

  async handle(request: LocalRuntimeRequest): Promise<LocalRuntimeResponse | null> {
    if (request.url !== "/v1/auth/login" || request.method !== "POST") return null;
    const password = passwordFromOrNull(request.body);
    const valid = password !== null && await this.credentials.verifyPassword(password);
    if (!valid) return {body: {error: "Passwort ist ungültig."}, statusCode: 401};
    const token = await this.sessions.createSession();
    return {body: {token}, statusCode: 200};
  }
}

function passwordFromOrNull(value: unknown): string | null {
  if (value === null || typeof value !== "object" || Array.isArray(value)) return null;
  const password = (value as Record<string, unknown>).password;
  return typeof password === "string" && password.length > 0 ? password : null;
}
