import {eq} from "drizzle-orm";
import {randomBytes, scrypt, timingSafeEqual} from "node:crypto";
import {type RuntimeExecutor} from "../../db/database.js";
import {runtimeAccessCredential} from "../../db/schema.js";

const scryptKeyLength = 64;
const saltBytes = 16;

// OWASP Password Storage Cheat Sheet (Stand 2024): scrypt mit N=2^17, r=8,
// p=1 als Minimum, wenn Argon2id nicht verfügbar ist. Node erlaubt diese
// Parameter nicht mit dem Default-Speicherlimit (32 MiB) — scrypt braucht
// hier grob 128 * N * r Bytes (~128 MiB), maxmem muss also explizit erhöht
// werden. Login passiert selten (einmal pro Gerät/30 Tage), die höheren
// Kosten fallen praktisch nicht ins Gewicht. Gehasht wird asynchron im
// libuv-Threadpool und immer nur ein Passwort gleichzeitig, damit weder der
// Event-Loop blockiert noch parallele Anfragen je ~128 MiB belegen.
const scryptOptions = {N: 131072, r: 8, p: 1, maxmem: 256 * 1024 * 1024};

/**
 * Verwaltet das eine Betreiber-Passwort der lokalen Runtime (Singleton-Row,
 * id = 1 — ein Arbeitsbereich hat genau ein Zugriffs-Passwort). Speichert
 * ausschließlich einen scrypt-Hash, nie das Klartext-Passwort.
 */
export class LocalRuntimeAccessCredentialStore {
  private hashing: Promise<unknown> = Promise.resolve();

  constructor(private readonly database: RuntimeExecutor) {}

  async hasCredential(): Promise<boolean> {
    const row = await this.database.select({id: runtimeAccessCredential.id}).from(runtimeAccessCredential)
      .where(eq(runtimeAccessCredential.id, 1)).get();
    return row !== undefined;
  }

  /**
   * Ersteinrichtung. Ein vorhandenes Passwort wird nur über die authentifizierte
   * Passwortänderung ersetzt, niemals über den öffentlichen Setup-Endpunkt.
   */
  async setPassword(password: string): Promise<void> {
    if (await this.hasCredential()) {
      throw new RuntimeAccessCredentialAlreadySetError();
    }
    const salt = randomBytes(saltBytes).toString("hex");
    const hash = await this.hash(password, salt);
    await this.database.insert(runtimeAccessCredential).values({id: 1, password_hash: hash, salt});
  }

  async verifyPassword(password: string): Promise<boolean> {
    const row = await this.database.select({password_hash: runtimeAccessCredential.password_hash, salt: runtimeAccessCredential.salt})
      .from(runtimeAccessCredential).where(eq(runtimeAccessCredential.id, 1)).get();
    if (!row) return false;
    const candidate = Buffer.from(await this.hash(password, row.salt), "hex");
    const stored = Buffer.from(row.password_hash, "hex");
    return candidate.length === stored.length && timingSafeEqual(candidate, stored);
  }

  async updatePassword(password: string): Promise<void> {
    const salt = randomBytes(saltBytes).toString("hex");
    const hash = await this.hash(password, salt);
    const updated = await this.database.update(runtimeAccessCredential)
      .set({password_hash: hash, salt}).where(eq(runtimeAccessCredential.id, 1))
      .returning({id: runtimeAccessCredential.id});
    if (updated.length === 0) throw new Error("Das Zugriffs-Passwort wurde noch nicht eingerichtet.");
  }

  /** Reiht den Hash hinter den laufenden ein; ein Fehler blockiert die Schlange nicht. */
  private hash(password: string, salt: string): Promise<string> {
    const hashed = this.hashing.then(() => hashFor(password, salt));
    this.hashing = hashed.catch(() => undefined);
    return hashed;
  }
}

export class RuntimeAccessCredentialAlreadySetError extends Error {
  constructor() {
    super("Für diese Runtime ist bereits ein Zugriffs-Passwort gesetzt.");
  }
}

function hashFor(password: string, salt: string): Promise<string> {
  return new Promise((resolve, reject) => {
    scrypt(password, salt, scryptKeyLength, scryptOptions, (error, key) => {
      if (error) reject(error);
      else resolve(key.toString("hex"));
    });
  });
}
