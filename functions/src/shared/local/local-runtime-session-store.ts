import {eq} from "drizzle-orm";
import {createHash, randomBytes} from "node:crypto";
import {type RuntimeExecutor} from "../../db/database.js";
import {runtimeSessions} from "../../db/schema.js";

const tokenBytes = 32;
const sessionLifetimeMs = 30 * 24 * 60 * 60 * 1000; // 30 Tage

/**
 * Verwaltet Session-Tokens für den authentifizierten Fernzugriff. Es wird
 * nur der SHA-256-Hash des Tokens gespeichert, nie das Token selbst — analog
 * zum Passwort-Hashing im Credential-Store. Tokens haben hohe Entropie
 * (32 Zufallsbytes), daher genügt hier ein schneller Hash statt scrypt.
 */
export class LocalRuntimeSessionStore {
  constructor(private readonly database: RuntimeExecutor) {}

  /** Erzeugt eine neue Session und liefert das Klartext-Token einmalig zurück. */
  async createSession(): Promise<string> {
    const token = randomBytes(tokenBytes).toString("hex");
    const expiresAt = new Date(Date.now() + sessionLifetimeMs).toISOString();
    await this.database.insert(runtimeSessions).values({token_hash: hashOf(token), expires_at: expiresAt});
    return token;
  }

  async verifySession(token: string): Promise<boolean> {
    const row = await this.database.select({expires_at: runtimeSessions.expires_at}).from(runtimeSessions)
      .where(eq(runtimeSessions.token_hash, hashOf(token))).get();
    if (!row) return false;
    return new Date(row.expires_at).getTime() > Date.now();
  }
}

function hashOf(token: string): string {
  return createHash("sha256").update(token).digest("hex");
}
