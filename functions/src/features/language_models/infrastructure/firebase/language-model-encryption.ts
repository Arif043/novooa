import {defineSecret} from "firebase-functions/params";
import {CredentialCipher} from "../../../communication/infrastructure/security/credential-cipher.js";

export const languageModelEncryptionKey = defineSecret(
  "LANGUAGE_MODEL_ENCRYPTION_KEY",
);

export function languageModelCipher(): CredentialCipher {
  return new CredentialCipher(
    languageModelEncryptionKey.value(),
    "LANGUAGE_MODEL_ENCRYPTION_KEY",
  );
}
