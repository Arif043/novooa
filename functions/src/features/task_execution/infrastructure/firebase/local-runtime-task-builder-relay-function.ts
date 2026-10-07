import {onRequest} from "firebase-functions/v2/https";
import {assistantCallableInputSchema, assistantRequestFromInput} from
  "../../../assistant/infrastructure/firebase/assistant-callable-input.js";
import {geminiApiKey} from "../../../../shared/genkit/gemini-secret.js";
import {logException} from "../../../../shared/logging/logger.js";
import {FirebaseRuntimeRelayLicenseVerifier} from
  "../../../licensing/infrastructure/firebase/firebase-runtime-relay-license-verifier.js";
import {localRuntimeLicenseSigningKey} from
  "../../../licensing/infrastructure/firebase/local-runtime-license-signing-key.js";
import {signedRuntimeLicenseFrom} from
  "../../../licensing/infrastructure/firebase/signed-runtime-license-input.js";
import {runTaskBuilderAssistant} from "./run-task-builder-assistant.js";

const verifier = new FirebaseRuntimeRelayLicenseVerifier();

/**
 * Der Aufgabenstudio-Agent für lokale Runtimes: Er läuft ausschließlich in der
 * Cloud mit dem Modell aus Remote Config. Die Runtime weist sich mit ihrer
 * Lizenz aus und schickt nur Frage und Verlauf; der Agent braucht keine
 * lokalen Daten. Die Antwort hat dieselbe Form wie die der App.
 */
export const localRuntimeTaskBuilderRelay = onRequest(
  {
    cors: false, invoker: "public", timeoutSeconds: 120, memory: "512MiB",
    secrets: [localRuntimeLicenseSigningKey, geminiApiKey],
  },
  async (request, response) => {
    if (request.method !== "POST") return void response.status(405).json({error: "Methode nicht erlaubt."});
    try {
      const body = (request.body ?? {}) as {license?: unknown};
      const license = await verifier.verify(signedRuntimeLicenseFrom(body.license));
      const input = assistantCallableInputSchema.parse(request.body);
      response.status(200).json(await runTaskBuilderAssistant({
        request: assistantRequestFromInput(input), actorId: `license-${license.licenseId}`,
        teamIdForActor: async () => null,
      }));
    } catch (error) {
      logException("local_runtime_task_builder_relay.failed", error);
      response.status(401).json({error: "Die Relay-Anfrage wurde abgelehnt."});
    }
  },
);
