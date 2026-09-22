import {randomBytes, scryptSync, timingSafeEqual} from "node:crypto";
import {type LocalSqlDatabase, type SqlRow} from "./local-sql-database.js";

const scryptKeyLength = 64;
const saltBytes = 16;

// OWASP Password Storage Cheat Sheet (Stand 2024): scrypt mit N=2^17, r=8,
// p=1 als Minimum, wenn Argon2id nicht verfügbar ist. Node erlaubt diese
// Parameter nicht mit dem Default-Speicherlimit (32 MiB) — scrypt braucht
// hier grob 128 * N * r Bytes (~128 MiB), maxmem muss also explizit erhöht
// werden. Login passiert selten (einmal pro Gerät/30 Tage), die höheren
// Kosten fallen praktisch nicht ins Gewicht.
const scryptOptions = {N: 131072, r: 8, p: 1, maxmem: 256 * 1024 * 1024};

type CredentialRow = SqlRow & {password_hash: string; salt: string};

/**
 * Verwaltet das eine Betreiber-Passwort der lokalen Runtime (Singleton-Row,
 * id = 1 — ein Arbeitsbereich hat genau ein Zugriffs-Passwort). Speichert
 * ausschließlich einen scrypt-Hash, nie das Klartext-Passwort.
 */
export class LocalRuntimeAccessCredentialStore {
  constructor(private readonly database: LocalSqlDatabase) {}

  async hasCredential(): Promise<boolean> {
    const row = await this.database.get<SqlRow>(
      "SELECT id FROM runtime_access_credential WHERE id = 1",
    );
    return row !== null;
  }

  /**
   * Setzt das Passwort. Wirft, falls bereits eines gesetzt ist — die
   * Sperre ist absichtlich permanent und nicht per API zurücksetzbar.
   */
  async setPassword(password: string): Promise<void> {
    if (await this.hasCredential()) {
      throw new RuntimeAccessCredentialAlreadySetError();
    }
    const salt = randomBytes(saltBytes).toString("hex");
    const hash = hashFor(password, salt);
    await this.database.run(
      "INSERT INTO runtime_access_credential (id, password_hash, salt) VALUES (1, ?, ?)",
      [hash, salt],
    );
  }

  async verifyPassword(password: string): Promise<boolean> {
    const row = await this.database.get<CredentialRow>(
      "SELECT password_hash, salt FROM runtime_access_credential WHERE id = 1",
    );
    if (row === null) return false;
    const candidate = Buffer.from(hashFor(password, row.salt), "hex");
    const stored = Buffer.from(row.password_hash, "hex");
    return candidate.length === stored.length && timingSafeEqual(candidate, stored);
  }
}

export class RuntimeAccessCredentialAlreadySetError extends Error {
  constructor() {
    super("Für diese Runtime ist bereits ein Zugriffs-Passwort gesetzt.");
  }
}

function hashFor(password: string, salt: string): string {
  return scryptSync(password, salt, scryptKeyLength, scryptOptions).toString("hex");
}
