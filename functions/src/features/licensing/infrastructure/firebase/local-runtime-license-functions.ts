import {defineSecret} from "firebase-functions/params";
import {onRequest} from "firebase-functions/v2/https";
import {localRuntimeActivationTokenFrom} from "../../domain/entities/local-runtime-activation-token.js";
import {signLocalRuntimeLicense} from "../license-lease-crypto.js";
import {
  FirestoreLocalRuntimeLicenseRegistry,
} from "./firestore-local-runtime-license-registry.js";

export const localRuntimeLicenseSigningKey = defineSecret(
  "LOCAL_RUNTIME_LICENSE_SIGNING_KEY",
);

const licenseRegistry = new FirestoreLocalRuntimeLicenseRegistry();

export const issueLocalRuntimeLicense = onRequest(
  {cors: false, invoker: "public", secrets: [localRuntimeLicenseSigningKey]},
  async (request, response) => {
    if (request.method !== "POST") {
      response.status(405).json({error: "Methode nicht erlaubt."});
      return;
    }
    try {
      const activationToken = localRuntimeActivationTokenFrom(request.body?.activationToken);
      const license = await licenseRegistry.licenseForActivationToken(activationToken, new Date());
      const signedLicense = signLocalRuntimeLicense(license, localRuntimeLicenseSigningKey.value());
      response.status(200).json(signedLicense);
    } catch {
      response.status(401).json({error: "Der Lizenzschlüssel wurde abgelehnt."});
    }
  },
);
