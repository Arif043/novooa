import {type RuntimeLicense} from "../entities/runtime-license-lease.js";

export type RuntimeLicenseActivationGrant = {
  license: RuntimeLicense;
  activationSecret: string;
};

export interface RuntimeLicenseRegistry {
  activate(token: string, now: Date): Promise<RuntimeLicenseActivationGrant>;
  release(license: RuntimeLicense, activationSecret: string, now: Date): Promise<void>;
  licenseForId(licenseId: string, now: Date): Promise<RuntimeLicense>;
}
