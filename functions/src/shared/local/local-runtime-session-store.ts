import {eq, lte, ne} from "drizzle-orm";
import {createHash, randomBytes} from "node:crypto";
import {type RuntimeExecutor} from "../../db/database.js";
import {runtimeSessions} from "../../db/schema.js";

const tokenBytes = 32;
/** Eine Sitzung läuft ab, wenn sie so lange nicht genutzt wurde; jede Nutzung startet die Frist neu. */
const idleLifetimeMs = 7 * 24 * 60 * 60 * 1000;
/** Verlängert wird höchstens einmal pro Stunde, damit nicht jede Anfrage schreibt. */
const extensionIntervalMs = 60 * 60 * 1000;

/**
 * Verwaltet Session-Tokens für den authentifizierten Fernzugriff. Es wird
 * nur der SHA-256-Hash des Tokens gespeichert, nie das Token selbst — analog
 * zum Passwort-Hashing im Credential-Store. Tokens haben hohe Entropie
 * (32 Zufallsbytes), daher genügt hier ein schneller Hash statt scrypt.
 */
export class LocalRuntimeSessionStore {
  constructor(
    private readonly database: RuntimeExecutor,
    private readonly now: () => number = Date.now,
  ) {}

  /** Erzeugt eine neue Session und liefert das Klartext-Token einmalig zurück. */
  async createSession(): Promise<string> {
    await this.database.delete(runtimeSessions).where(lte(runtimeSessions.expires_at, this.isoIn(0)));
    const token = randomBytes(tokenBytes).toString("hex");
    await this.database.insert(runtimeSessions).values({token_hash: hashOf(token), expires_at: this.isoIn(idleLifetimeMs)});
    return token;
  }

  /** Prüft die Session und verlängert sie bei Nutzung. */
  async verifySession(token: string): Promise<boolean> {
    const expiresAtMs = await this.expiresAtMs(token);
    if (expiresAtMs === null || expiresAtMs <= this.now()) return false;
    if (expiresAtMs - this.now() < idleLifetimeMs - extensionIntervalMs) {
      await this.database.update(runtimeSessions).set({expires_at: this.isoIn(idleLifetimeMs)})
        .where(eq(runtimeSessions.token_hash, hashOf(token)));
    }
    return true;
  }

  /** Prüft die Session, ohne sie zu verlängern — für offene Realtime-Verbindungen. */
  async isActive(token: string): Promise<boolean> {
    const expiresAtMs = await this.expiresAtMs(token);
    return expiresAtMs !== null && expiresAtMs > this.now();
  }

  async deleteSession(token: string): Promise<void> {
    await this.database.delete(runtimeSessions).where(eq(runtimeSessions.token_hash, hashOf(token)));
  }

  /** Beendet alle Sessions außer [currentToken] und liefert, wie viele es waren. */
  async deleteOtherSessions(currentToken: string): Promise<number> {
    const deleted = await this.database.delete(runtimeSessions)
      .where(ne(runtimeSessions.token_hash, hashOf(currentToken))).returning({token_hash: runtimeSessions.token_hash});
    return deleted.length;
  }

  private async expiresAtMs(token: string): Promise<number | null> {
    const row = await this.database.select({expires_at: runtimeSessions.expires_at}).from(runtimeSessions)
      .where(eq(runtimeSessions.token_hash, hashOf(token))).get();
    return row === undefined ? null : new Date(row.expires_at).getTime();
  }

  private isoIn(offsetMs: number): string {
    return new Date(this.now() + offsetMs).toISOString();
  }
}

function hashOf(token: string): string {
  return createHash("sha256").update(token).digest("hex");
}
