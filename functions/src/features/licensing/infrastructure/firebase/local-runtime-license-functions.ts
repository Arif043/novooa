import {onRequest} from "firebase-functions/v2/https";
import {runtimeActivationTokenFrom} from "../../domain/entities/activation-token.js";
import {signRuntimeLicense} from "../license-lease-crypto.js";
import {
  FirestoreRuntimeLicenseRegistry,
} from "./firestore-runtime-license-registry.js";
import {localRuntimeLicenseSigningKey} from "./local-runtime-license-signing-key.js";

const licenseRegistry = new FirestoreRuntimeLicenseRegistry();

export const issueLocalRuntimeLicense = onRequest(
  {cors: false, invoker: "public", secrets: [localRuntimeLicenseSigningKey]},
  async (request, response) => {
    if (request.method !== "POST") {
      response.status(405).json({error: "Methode nicht erlaubt."});
      return;
    }
    try {
      const activationToken = runtimeActivationTokenFrom(request.body?.activationToken);
      const license = await licenseRegistry.licenseForActivationToken(activationToken, new Date());
      const signedLicense = signRuntimeLicense(license, localRuntimeLicenseSigningKey.value());
      response.status(200).json(signedLicense);
    } catch {
      response.status(401).json({error: "Der Lizenzschlüssel wurde abgelehnt."});
    }
  },
);
