import {createHash, randomBytes} from "node:crypto";
import {type LocalSqlDatabase, type SqlRow} from "./local-sql-database.js";

const tokenBytes = 32;
const sessionLifetimeMs = 30 * 24 * 60 * 60 * 1000; // 30 Tage

type SessionRow = SqlRow & {expires_at: string};

/**
 * Verwaltet Session-Tokens für den authentifizierten Fernzugriff. Es wird
 * nur der SHA-256-Hash des Tokens gespeichert, nie das Token selbst — analog
 * zum Passwort-Hashing im Credential-Store. Tokens haben hohe Entropie
 * (32 Zufallsbytes), daher genügt hier ein schneller Hash statt scrypt.
 */
export class LocalRuntimeSessionStore {
  constructor(private readonly database: LocalSqlDatabase) {}

  /** Erzeugt eine neue Session und liefert das Klartext-Token einmalig zurück. */
  async createSession(): Promise<string> {
    const token = randomBytes(tokenBytes).toString("hex");
    const expiresAt = new Date(Date.now() + sessionLifetimeMs).toISOString();
    await this.database.run(
      "INSERT INTO runtime_sessions (token_hash, expires_at) VALUES (?, ?)",
      [hashOf(token), expiresAt],
    );
    return token;
  }

  async verifySession(token: string): Promise<boolean> {
    const row = await this.database.get<SessionRow>(
      "SELECT expires_at FROM runtime_sessions WHERE token_hash = ?",
      [hashOf(token)],
    );
    if (row === null) return false;
    return new Date(row.expires_at).getTime() > Date.now();
  }
}

function hashOf(token: string): string {
  return createHash("sha256").update(token).digest("hex");
}
