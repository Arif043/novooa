import {type LocalRuntimeLicense} from
  "../../../licensing/domain/entities/local-runtime-license-lease.js";
import {type LocalRuntimePushDevice} from "../entities/local-runtime-push.js";

export interface LocalRuntimePushDeviceStore {
  save(license: LocalRuntimeLicense, device: LocalRuntimePushDevice): Promise<void>;
  remove(licenseId: string, token: string): Promise<void>;
}
