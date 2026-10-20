import {and, eq, lte, ne} from "drizzle-orm";
import {createHash, randomBytes} from "node:crypto";
import {type RuntimeExecutor} from "../../db/database.js";
import {runtimeSessions, teamMembers} from "../../db/schema.js";
import {isRuntimeRole, type RuntimeActor} from "../../features/runtime_users/domain/entities/runtime-user.js";

const tokenBytes = 32;
/** Eine Sitzung läuft ab, wenn sie so lange nicht genutzt wurde; jede Nutzung startet die Frist neu. */
const idleLifetimeMs = 7 * 24 * 60 * 60 * 1000;
/** Verlängert wird höchstens einmal pro Stunde, damit nicht jede Anfrage schreibt. */
const extensionIntervalMs = 60 * 60 * 1000;

/**
 * Verwaltet Session-Tokens der Konten. Es wird
 * nur der SHA-256-Hash des Tokens gespeichert, nie das Token selbst — analog
 * zum Passwort-Hashing im Credential-Store. Tokens haben hohe Entropie
 * (32 Zufallsbytes), daher genügt hier ein schneller Hash statt scrypt.
 */
export class LocalRuntimeSessionStore {
  constructor(
    private readonly database: RuntimeExecutor,
    /** Team des aktiven Arbeitsbereichs; die Rolle eines Kontos gilt je Team. */
    private readonly activeTeamId: () => string | null,
    private readonly now: () => number = Date.now,
  ) {}

  /** Erzeugt eine neue Session für das Konto und liefert das Klartext-Token einmalig zurück. */
  async createSession(uid: string): Promise<string> {
    await this.database.delete(runtimeSessions).where(lte(runtimeSessions.expires_at, this.isoIn(0)));
    const token = randomBytes(tokenBytes).toString("hex");
    await this.database.insert(runtimeSessions).values({token_hash: hashOf(token), uid, expires_at: this.isoIn(idleLifetimeMs)});
    return token;
  }

  /**
   * Prüft die Session, verlängert sie bei Nutzung und liefert, wer anfragt. Ohne Mitgliedschaft im aktiven
   * Team gilt die Sitzung nicht. Die Rolle wird bei jeder Anfrage gelesen; eine Änderung wirkt sofort.
   */
  async verifySession(token: string): Promise<RuntimeActor | null> {
    const session = await this.sessionOf(token);
    if (session === null || session.expiresAtMs <= this.now()) return null;
    if (session.expiresAtMs - this.now() < idleLifetimeMs - extensionIntervalMs) {
      await this.database.update(runtimeSessions).set({expires_at: this.isoIn(idleLifetimeMs)})
        .where(eq(runtimeSessions.token_hash, hashOf(token)));
    }
    return session.actor;
  }

  /** Prüft die Session, ohne sie zu verlängern — für offene Realtime-Verbindungen. */
  async isActive(token: string): Promise<boolean> {
    const session = await this.sessionOf(token);
    return session !== null && session.expiresAtMs > this.now();
  }

  async deleteSession(token: string): Promise<void> {
    await this.database.delete(runtimeSessions).where(eq(runtimeSessions.token_hash, hashOf(token)));
  }

  /** Beendet alle anderen Sessions desselben Kontos und liefert, wie viele es waren. */
  async deleteOtherSessions(currentToken: string, uid: string): Promise<number> {
    const deleted = await this.database.delete(runtimeSessions)
      .where(and(eq(runtimeSessions.uid, uid), ne(runtimeSessions.token_hash, hashOf(currentToken))))
      .returning({token_hash: runtimeSessions.token_hash});
    return deleted.length;
  }

  /** Beendet alle Sessions eines Kontos (gelöscht, zurückgesetzt, Notzugang). */
  async deleteSessionsOf(uid: string): Promise<void> {
    await this.database.delete(runtimeSessions).where(eq(runtimeSessions.uid, uid));
  }

  private async sessionOf(token: string): Promise<{actor: RuntimeActor; expiresAtMs: number} | null> {
    const teamId = this.activeTeamId();
    if (teamId === null) return null;
    const row = await this.database.select({uid: runtimeSessions.uid, role: teamMembers.role, expiresAt: runtimeSessions.expires_at})
      .from(runtimeSessions)
      .innerJoin(teamMembers, and(eq(teamMembers.uid, runtimeSessions.uid), eq(teamMembers.team_id, teamId)))
      .where(eq(runtimeSessions.token_hash, hashOf(token))).get();
    if (row === undefined) return null;
    const role = isRuntimeRole(row.role) ? row.role : "member";
    return {actor: {uid: row.uid, role}, expiresAtMs: new Date(row.expiresAt).getTime()};
  }

  private isoIn(offsetMs: number): string {
    return new Date(this.now() + offsetMs).toISOString();
  }
}

function hashOf(token: string): string {
  return createHash("sha256").update(token).digest("hex");
}
