import {and, eq, gt, lte} from "drizzle-orm";
import {createHash, randomInt} from "node:crypto";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {runtimeInvitations} from "../../../../db/schema.js";
import {type InvitationRepository, type IssuedInvitation} from "../../domain/repositories/invitation-repository.js";

/** Crockford-Base32 ohne I, L, O, U: gut vorzulesen und abzutippen. */
const alphabet = "0123456789ABCDEFGHJKMNPQRSTVWXYZ";
const codeLength = 16;
const lifetimeMs = 72 * 60 * 60 * 1000;

/**
 * Einladungscodes haben 80 Bit Zufall und gelten 72 Stunden; deshalb genügt wie bei Sitzungen ein
 * schneller Hash. Gespeichert wird nur der Hash, eingelöst wird genau einmal.
 */
export class SQLiteInvitationRepository implements InvitationRepository {
  constructor(private readonly database: RuntimeExecutor, private readonly now: () => number = Date.now) {}

  async issue(uid: string): Promise<IssuedInvitation> {
    const code = newCode();
    const expiresAt = new Date(this.now() + lifetimeMs).toISOString();
    await this.database.transaction(async (tx) => {
      await tx.delete(runtimeInvitations).where(eq(runtimeInvitations.uid, uid));
      await tx.insert(runtimeInvitations).values({code_hash: hashOf(code), uid, expires_at: expiresAt});
    });
    return {code, expiresAt};
  }

  async redeem(code: string): Promise<string | null> {
    const nowIso = new Date(this.now()).toISOString();
    await this.database.delete(runtimeInvitations).where(lte(runtimeInvitations.expires_at, nowIso));
    const redeemed = await this.database.delete(runtimeInvitations)
      .where(and(eq(runtimeInvitations.code_hash, hashOf(normalized(code))), gt(runtimeInvitations.expires_at, nowIso)))
      .returning({uid: runtimeInvitations.uid});
    return redeemed[0]?.uid ?? null;
  }
}

function newCode(): string {
  const characters = Array.from({length: codeLength}, () => alphabet[randomInt(alphabet.length)]);
  return characters.join("").match(/.{4}/g)!.join("-");
}

/** Bindestriche, Leerzeichen und Kleinschreibung beim Abtippen sind egal; verwechselbare Zeichen werden gelesen wie gemeint. */
function normalized(code: string): string {
  const compact = code.toUpperCase().replace(/[\s-]/g, "").replace(/O/g, "0").replace(/[IL]/g, "1");
  return compact.length === codeLength ? compact.match(/.{4}/g)!.join("-") : compact;
}

function hashOf(code: string): string {
  return createHash("sha256").update(code).digest("hex");
}
