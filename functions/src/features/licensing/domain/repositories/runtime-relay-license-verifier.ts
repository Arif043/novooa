import {
  type RuntimeLicense,
  type SignedRuntimeLicense,
} from "../entities/runtime-license-lease.js";

export interface RuntimeRelayLicenseVerifier {
  verify(license: SignedRuntimeLicense): Promise<RuntimeLicense>;
}
