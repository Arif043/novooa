import {
  type LocalRuntimeLicense,
  type SignedLocalRuntimeLicense,
} from "../entities/local-runtime-license-lease.js";

export interface LocalRuntimeRelayLicenseVerifier {
  verify(license: SignedLocalRuntimeLicense): Promise<LocalRuntimeLicense>;
}
