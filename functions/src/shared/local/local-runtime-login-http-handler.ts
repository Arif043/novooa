import { type FastifyInstance, type FastifyReply } from "fastify";
import { type LocalRuntimeAccessCredentialStore } from "./local-runtime-access-credential-store.js";
import { type LocalRuntimeSessionStore } from "./local-runtime-session-store.js";
/**
 * `POST /v1/auth/login` — tauscht das Betreiber-Passwort gegen ein
 * Session-Token. Bleibt bewusst außerhalb des
 * Session-Hooks (sonst käme niemand an ein Token).
 * Login und Setup verwenden den regulären API-Port; Setup verlangt
 * zusätzlich den prozessgebundenen Pairing-Code.
 */
export class LocalRuntimeLoginHttpHandler {
  static registerRoutes(http: FastifyInstance, current: () => LocalRuntimeLoginHttpHandler): void { http.post("/v1/auth/login", (request, reply) => current().login(request.body, reply)); }
  constructor(private readonly credentials: Pick<LocalRuntimeAccessCredentialStore, "verifyPassword">, private readonly sessions: Pick<LocalRuntimeSessionStore, "createSession">) { }
  private async login(body: unknown, reply: FastifyReply): Promise<FastifyReply> {
    const password = passwordFromOrNull(body);
    const valid = password !== null && await this.credentials.verifyPassword(password);
    if (!valid)
      return reply.code(401).send({ error: "Passwort ist ungültig." });
    const token = await this.sessions.createSession();
    return reply.code(200).send({ token });
  }
}
function passwordFromOrNull(value: unknown): string | null {
  if (value === null || typeof value !== "object" || Array.isArray(value))
    return null;
  const password = (value as Record<string, unknown>).password;
  return typeof password === "string" && password.length > 0 ? password : null;
}
