import {randomBytes} from "node:crypto";
import {FieldValue, Timestamp} from "firebase-admin/firestore";
import {localRuntimeActivationTokenHash} from "../license-activation-token-hash.js";
import {getDatabase} from "../../../../shared/firebase/firestore-db.js";

void issueLicense().catch(reportFailure);

async function issueLicense(): Promise<void> {
  const licenseId = requiredArgument("license-id");
  const workspaceId = optionalArgument("workspace-id") ?? licenseId;
  const expiresAt = optionalExpiration();
  const activationToken = randomActivationToken();
  await getDatabase().collection("licenses").doc(
    localRuntimeActivationTokenHash(activationToken),
  ).create({
    licenseId,
    workspaceId,
    status: "active",
    ...(expiresAt === undefined ? {} : {expiresAt}),
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
  console.log(activationToken);
}

function reportFailure(error: unknown): void {
  console.error(error instanceof Error ? error.message : String(error));
  process.exitCode = 1;
}

function requiredArgument(name: string): string {
  const value = optionalArgument(name);
  if (value) return value;
  throw new Error(`--${name} fehlt.`);
}

function optionalArgument(name: string): string | undefined {
  const index = process.argv.indexOf(`--${name}`);
  const value = index === -1 ? undefined : process.argv[index + 1]?.trim();
  if (value === undefined) return undefined;
  if (value.length === 0 || value.length > 200) throw new Error(`--${name} ist ungültig.`);
  return value;
}

function optionalExpiration(): Timestamp | undefined {
  const value = optionalArgument("expires-at");
  if (value === undefined) return undefined;
  const parsed = Date.parse(value);
  if (Number.isNaN(parsed)) throw new Error("--expires-at ist ungültig.");
  return Timestamp.fromMillis(parsed);
}

function randomActivationToken(): string {
  const alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  return [...randomBytes(12)].map((byte) => alphabet[byte & 31]).join("");
}
