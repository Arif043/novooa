import {type RuntimeLicense} from
  "../../../licensing/domain/entities/runtime-license-lease.js";
import {type RuntimePushDevice} from "../entities/runtime-push.js";

export interface RuntimePushDeviceStore {
  save(license: RuntimeLicense, device: RuntimePushDevice): Promise<void>;
  remove(licenseId: string, token: string): Promise<void>;
}
