import {type RuntimeFieldCipher} from "./runtime-field-cipher.js";

export interface RuntimeKeyRepository {
  beginRotation(): Promise<RuntimeFieldCipher>;
  completeRotation(retireOldKeys: boolean): Promise<void>;
}
