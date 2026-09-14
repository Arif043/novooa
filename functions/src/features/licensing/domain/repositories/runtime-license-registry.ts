import {type RuntimeLicense} from "../entities/runtime-license-lease.js";

export interface RuntimeLicenseRegistry {
  licenseForActivationToken(token: string, now: Date): Promise<RuntimeLicense>;
  licenseForId(licenseId: string, now: Date): Promise<RuntimeLicense>;
}
