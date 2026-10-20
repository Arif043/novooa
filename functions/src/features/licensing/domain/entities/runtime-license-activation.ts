import {type SignedRuntimeLicense} from "./runtime-license-lease.js";

export type RuntimeLicenseActivation = {
  license: SignedRuntimeLicense;
  activationSecret: string;
  /**
   * SHA-256 des eingelösten Lizenz-Tokens. Weist bei der Ersteinrichtung
   * und beim Notzugang nach, dass der Lizenzinhaber das Admin-Konto anlegt
   * bzw. wiederherstellt.
   */
  activationTokenHash?: string;
};
