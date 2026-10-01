import {randomBytes, randomUUID} from "node:crypto";
import {FieldValue, Timestamp} from "firebase-admin/firestore";
import {localRuntimeActivationTokenHash} from "../license-activation-token-hash.js";
import {getDatabase} from "../../../../shared/firebase/firestore-db.js";

void issueLicense().catch(reportFailure);

async function issueLicense(): Promise<void> {
  const licenseId = optionalArgument("license-id") ?? randomUUID();
  const name = requiredArgument("name");
  const workspaceId = optionalArgument("workspace-id") ?? licenseId;
  const expiresAt = requiredExpiration();
  const activationToken = await uniqueActivationToken({licenseId, name, workspaceId, expiresAt});
  console.log(activationToken);
}

async function uniqueActivationToken(license: LicenseDraft): Promise<string> {
  for (let attempt = 0; attempt < 20; attempt += 1) {
    const token = randomActivationToken();
    try {
      await getDatabase().collection("licenses").doc(localRuntimeActivationTokenHash(token)).create({
        ...license, inUse: false, createdAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp(),
      });
      return token;
    } catch (error) { if (!isAlreadyExists(error)) throw error; }
  }
  throw new Error("Es konnte kein eindeutiger Lizenzschlüssel erzeugt werden.");
}

type LicenseDraft = {licenseId: string; name: string; workspaceId: string; expiresAt: Timestamp;};
function isAlreadyExists(error: unknown): boolean { return typeof error === "object" && error !== null && "code" in error && error.code === 6; }
function reportFailure(error: unknown): void { console.error(error instanceof Error ? error.message : String(error)); process.exitCode = 1; }
function requiredArgument(name: string): string { const value = optionalArgument(name); if (value) return value; throw new Error(`--${name} fehlt.`); }
function optionalArgument(name: string): string | undefined {
  const index = process.argv.indexOf(`--${name}`); const value = index === -1 ? undefined : process.argv[index + 1]?.trim();
  if (value === undefined) return undefined; if (value.length === 0 || value.length > 200) throw new Error(`--${name} ist ungültig.`); return value;
}
function requiredExpiration(): Timestamp { const value = requiredArgument("expires-at"); const parsed = Date.parse(value); if (Number.isNaN(parsed)) throw new Error("--expires-at ist ungültig."); return Timestamp.fromMillis(parsed); }
function randomActivationToken(): string { const alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"; return [...randomBytes(16)].map((byte) => alphabet[byte & 31]).join(""); }
