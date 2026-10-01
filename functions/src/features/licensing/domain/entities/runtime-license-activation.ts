import {type SignedRuntimeLicense} from "./runtime-license-lease.js";

export type RuntimeLicenseActivation = {
  license: SignedRuntimeLicense;
  activationSecret: string;
  /**
   * SHA-256 des eingelösten Lizenz-Tokens. Weist bei der Ersteinrichtung
   * nach, dass das Betreiber-Passwort vom Lizenzinhaber gesetzt wird.
   */
  activationTokenHash?: string;
};
