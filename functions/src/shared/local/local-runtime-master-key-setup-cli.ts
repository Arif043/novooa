import {resolve} from "node:path";
import {
  localRuntimeMasterKeyFrom,
  prepareLocalRuntimeMasterKey,
} from "./local-runtime-master-key.js";

void prepare().catch(reportFailure);

async function prepare(): Promise<void> {
  const secretFile = secretFileFrom(process.argv.slice(2));
  const created = await prepareLocalRuntimeMasterKey(secretFile);
  await localRuntimeMasterKeyFrom(secretFile);
  console.info(created
    ? "Lokaler Runtime-Master-Key wurde eingerichtet."
    : "Lokaler Runtime-Master-Key ist bereits eingerichtet.");
}

function secretFileFrom(arguments_: string[]): string {
  const index = arguments_.indexOf("--secret-file");
  const value = index < 0 ? undefined : arguments_[index + 1];
  if (!value || value.startsWith("--")) {
    throw new Error("Verwendung: --secret-file <pfad>");
  }
  return resolve(value);
}

function reportFailure(error: unknown): void {
  console.error(error instanceof Error ? error.message : "Der Runtime-Master-Key konnte nicht eingerichtet werden.");
  process.exitCode = 1;
}
