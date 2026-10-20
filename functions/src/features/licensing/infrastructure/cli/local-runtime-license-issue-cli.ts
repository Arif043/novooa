import {randomBytes, randomUUID} from "node:crypto";
import {FieldValue, Timestamp} from "firebase-admin/firestore";
import {localRuntimeActivationTokenHash} from "../license-activation-token-hash.js";
import {getDatabase} from "../../../../shared/firebase/firestore-db.js";
import {optionalArgument, reportFailure, requiredArgument, requiredMaxUsers} from "./license-cli-arguments.js";

void issueLicense().catch(reportFailure);

async function issueLicense(): Promise<void> {
  const licenseId = optionalArgument("license-id") ?? randomUUID();
  const name = requiredArgument("name");
  const workspaceId = optionalArgument("workspace-id") ?? licenseId;
  const expiresAt = requiredExpiration();
  const maxUsers = requiredMaxUsers();
  const activationToken = await uniqueActivationToken({licenseId, name, workspaceId, expiresAt, maxUsers});
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

type LicenseDraft = {licenseId: string; name: string; workspaceId: string; expiresAt: Timestamp; maxUsers: number | null};
function isAlreadyExists(error: unknown): boolean { return typeof error === "object" && error !== null && "code" in error && error.code === 6; }
function requiredExpiration(): Timestamp { const value = requiredArgument("expires-at"); const parsed = Date.parse(value); if (Number.isNaN(parsed)) throw new Error("--expires-at ist ungültig."); return Timestamp.fromMillis(parsed); }
function randomActivationToken(): string { const alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"; return [...randomBytes(16)].map((byte) => alphabet[byte & 31]).join(""); }
