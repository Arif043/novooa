import {type SignedRuntimeLicense} from "./runtime-license-lease.js";

export type RuntimeLicenseActivation = {
  license: SignedRuntimeLicense;
  activationSecret: string;
};
