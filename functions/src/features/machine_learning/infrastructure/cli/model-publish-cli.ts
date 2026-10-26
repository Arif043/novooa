import {cloudModelPublishDependencies} from "./model-publish-composition.js";
import {publishSystemModelCommand} from "./model-publish-command.js";
import {modelPublishOptionsFromArguments, modelPublishUsage} from "./model-publish-options.js";
import {cliErrorMessage} from "./cli-error-message.js";

async function main(): Promise<void> {
  if (process.argv.includes("--help")) return console.info(modelPublishUsage);
  const options = modelPublishOptionsFromArguments(process.argv.slice(2));
  const outcome = await publishSystemModelCommand(options, cloudModelPublishDependencies(options));
  console.info(messageFor(outcome.entry.id, outcome.entry.artifactReference.versionId, outcome.dryRun));
}

function messageFor(modelId: string, versionId: string, dryRun: boolean): string {
  if (dryRun) return `Trockenlauf erfolgreich: ${modelId}@${versionId} kann veröffentlicht werden.`;
  return `Systemmodell veröffentlicht: ${modelId}@${versionId}.`;
}

void main().catch((error: unknown) => {
  console.error(cliErrorMessage(error, "Die Modellveröffentlichung ist fehlgeschlagen."));
  process.exitCode = 1;
});
