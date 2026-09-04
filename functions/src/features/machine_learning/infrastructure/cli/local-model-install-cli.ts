import {localModelInstallDependencies} from "./local-model-install-composition.js";
import {localModelInstallOptionsFromArguments, localModelInstallUsage} from "./local-model-install-options.js";
import {publishSystemModelCommand} from "./model-publish-command.js";

async function main(): Promise<void> {
  if (process.argv.includes("--help")) return console.info(localModelInstallUsage);
  const options = localModelInstallOptionsFromArguments(process.argv.slice(2));
  const outcome = await publishSystemModelCommand(options, localModelInstallDependencies(options));
  console.info(messageFor(outcome.entry.id, outcome.entry.artifactReference.versionId, outcome.dryRun));
}

function messageFor(modelId: string, versionId: string, dryRun: boolean): string {
  if (dryRun) return `Trockenlauf erfolgreich: ${modelId}@${versionId} kann lokal installiert werden.`;
  return `Systemmodell lokal installiert: ${modelId}@${versionId}.`;
}

void main().catch((error: unknown) => {
  console.error(error instanceof Error ? error.message : "Die lokale Modellinstallation ist fehlgeschlagen.");
  process.exitCode = 1;
});
