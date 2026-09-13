import {defineSecret} from "firebase-functions/params";

export const localRuntimeLicenseSigningKey = defineSecret(
  "LOCAL_RUNTIME_LICENSE_SIGNING_KEY",
);
