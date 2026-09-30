import {type RuntimeFieldCipher} from "./runtime-field-cipher.js";

export interface RuntimeSecretRotationStore {
  rewrapSecrets(cipher: RuntimeFieldCipher): Promise<number>;
  verifySecrets(cipher: RuntimeFieldCipher): Promise<void>;
}
