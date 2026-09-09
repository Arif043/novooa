import {
  createPrivateKey,
  createPublicKey,
  sign,
  verify,
} from "node:crypto";
import {
  localRuntimeLicensePayloadJson,
  type LocalRuntimeLicense,
  type SignedLocalRuntimeLicense,
} from "../domain/entities/local-runtime-license-lease.js";

export function signLocalRuntimeLicense(
  payload: LocalRuntimeLicense,
  privateKeyPem: string,
): SignedLocalRuntimeLicense {
  const signature = sign(
    null,
    Buffer.from(localRuntimeLicensePayloadJson(payload)),
    createPrivateKey(privateKeyPem),
  );
  return {payload, signature: signature.toString("base64url")};
}

export function verifiesLocalRuntimeLicense(
  license: SignedLocalRuntimeLicense,
  publicKeyPem: string,
): boolean {
  try {
    return verify(
      null,
      Buffer.from(localRuntimeLicensePayloadJson(license.payload)),
      createPublicKey(publicKeyPem),
      Buffer.from(license.signature, "base64url"),
    );
  } catch {
    return false;
  }
}
