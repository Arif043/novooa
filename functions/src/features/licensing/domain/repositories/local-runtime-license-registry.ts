import {type LocalRuntimeLicense} from "../entities/local-runtime-license-lease.js";

export interface LocalRuntimeLicenseRegistry {
  licenseForActivationToken(token: string, now: Date): Promise<LocalRuntimeLicense>;
}
