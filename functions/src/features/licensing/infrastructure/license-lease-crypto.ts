import {
  createPrivateKey,
  createPublicKey,
  sign,
  verify,
} from "node:crypto";
import {
  runtimeLicensePayloadJson,
  type RuntimeLicense,
  type SignedRuntimeLicense,
} from "../domain/entities/runtime-license-lease.js";

export function signRuntimeLicense(
  payload: RuntimeLicense,
  privateKeyPem: string,
): SignedRuntimeLicense {
  const signature = sign(
    null,
    Buffer.from(runtimeLicensePayloadJson(payload)),
    createPrivateKey(privateKeyPem),
  );
  return {payload, signature: signature.toString("base64url")};
}

export function verifiesRuntimeLicense(
  license: SignedRuntimeLicense,
  publicKeyPem: string,
): boolean {
  try {
    return verify(
      null,
      Buffer.from(runtimeLicensePayloadJson(license.payload)),
      createPublicKey(publicKeyPem),
      Buffer.from(license.signature, "base64url"),
    );
  } catch {
    return false;
  }
}
