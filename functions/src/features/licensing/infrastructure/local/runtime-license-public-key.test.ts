import assert from "node:assert/strict";
import {createPublicKey} from "node:crypto";
import test from "node:test";
import {runtimeLicensePublicKeyPem} from "./runtime-license-public-key.js";

test("the embedded license key is a valid Ed25519 public key", () => {
  assert.equal(createPublicKey(runtimeLicensePublicKeyPem).asymmetricKeyType, "ed25519");
});
