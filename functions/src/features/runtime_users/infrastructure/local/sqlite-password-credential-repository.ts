import {eq, sql} from "drizzle-orm";
import {randomBytes, scrypt, timingSafeEqual} from "node:crypto";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {runtimePasswordCredentials} from "../../../../db/schema.js";
import {type RuntimePassword} from "../../domain/entities/runtime-password.js";
import {type PasswordCredentialRepository} from "../../domain/repositories/password-credential-repository.js";
import {type SensitiveFieldCipher} from "../../../runtime_security/domain/repositories/runtime-field-cipher.js";
import {passwordHashContext} from "../../../runtime_security/infrastructure/runtime-secret-context.js";

const scryptKeyLength = 64;
const saltBytes = 16;

// OWASP Password Storage Cheat Sheet (Stand 2024): scrypt mit N=2^17, r=8, p=1 als Minimum, wenn Argon2id
// nicht verfügbar ist. Das braucht grob 128 * N * r Bytes (~128 MiB), maxmem muss also explizit erhöht werden.
// Gehasht wird asynchron im libuv-Threadpool und immer nur ein Passwort gleichzeitig, damit weder der
// Event-Loop blockiert noch parallele Anfragen je ~128 MiB belegen.
const scryptOptions = {N: 131072, r: 8, p: 1, maxmem: 256 * 1024 * 1024};

/** Ersatz-Salt für unbekannte Konten: Die Prüfung kostet gleich viel, ob es das Konto gibt oder nicht. */
const unknownAccountSalt = randomBytes(saltBytes).toString("hex");

export class SQLitePasswordCredentialRepository implements PasswordCredentialRepository {
  private hashing: Promise<unknown> = Promise.resolve();

  constructor(
    private readonly database: RuntimeExecutor,
    private readonly cipher: SensitiveFieldCipher,
  ) {}

  async hasAny(): Promise<boolean> {
    const row = await this.database.select({uid: runtimePasswordCredentials.uid}).from(runtimePasswordCredentials).limit(1).get();
    return row !== undefined;
  }

  async verify(uid: string | null, password: string): Promise<boolean> {
    const row = uid === null ? undefined : await this.database.select({
      encryptedHash: runtimePasswordCredentials.encrypted_hash, salt: runtimePasswordCredentials.salt,
    }).from(runtimePasswordCredentials).where(eq(runtimePasswordCredentials.uid, uid)).get();
    const candidate = Buffer.from(await this.hash(password, row?.salt ?? unknownAccountSalt), "hex");
    if (uid === null || row === undefined || password.length === 0) return false;
    const stored = this.storedHash(uid, row.encryptedHash);
    return stored !== null && candidate.length === stored.length && timingSafeEqual(candidate, stored);
  }

  async set(uid: string, password: RuntimePassword): Promise<void> {
    const salt = randomBytes(saltBytes).toString("hex");
    const encryptedHash = this.cipher.encrypt(await this.hash(password.value, salt), passwordHashContext(uid));
    await this.database.insert(runtimePasswordCredentials).values({uid, encrypted_hash: encryptedHash, salt})
      .onConflictDoUpdate({
        target: runtimePasswordCredentials.uid,
        set: {encrypted_hash: encryptedHash, salt, updated_at: sql`CURRENT_TIMESTAMP`},
      });
  }

  async remove(uid: string): Promise<void> {
    await this.database.delete(runtimePasswordCredentials).where(eq(runtimePasswordCredentials.uid, uid));
  }

  /** Ein Umschlag, der nicht zu diesem Konto passt (kopiert oder verändert), zählt wie ein falsches Passwort. */
  private storedHash(uid: string, encryptedHash: string): Buffer | null {
    try {
      return Buffer.from(this.cipher.decrypt(encryptedHash, passwordHashContext(uid)), "hex");
    } catch {
      return null;
    }
  }

  /** Reiht den Hash hinter den laufenden ein; ein Fehler blockiert die Schlange nicht. */
  private hash(password: string, salt: string): Promise<string> {
    const hashed = this.hashing.then(() => hashFor(password, salt));
    this.hashing = hashed.catch(() => undefined);
    return hashed;
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
