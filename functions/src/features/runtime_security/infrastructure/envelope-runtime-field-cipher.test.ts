import assert from "node:assert/strict";
import test from "node:test";
import {EnvelopeRuntimeFieldCipher} from "./envelope-runtime-field-cipher.js";
import {createRuntimeKeyring} from "./runtime-keyring.js";

const context = ["workspace-1", "model-1", "api-key"];

test("uses fresh data keys and nonces for each encrypted field value", () => {
  const cipher = encryption();
  const first = cipher.encrypt("secret", context);
  const second = cipher.encrypt("secret", context);
  assert.notEqual(first, second);
  assert.notDeepEqual(JSON.parse(first).wrappedKey, JSON.parse(second).wrappedKey);
  assert.notDeepEqual(JSON.parse(first).payload, JSON.parse(second).payload);
  assert.equal(cipher.decrypt(first, context), "secret");
  assert.equal(cipher.decrypt(second, context), "secret");
  assert.equal(cipher.decrypt(cipher.encrypt("", context), context), "");
});

test("binds ciphertext to workspace, record and field with unambiguous context encoding", () => {
  const cipher = encryption();
  const encrypted = cipher.encrypt("secret", context);
  for (const other of [["workspace-2", "model-1", "api-key"],
    ["workspace-1", "model-2", "api-key"], ["workspace-1", "model-1", "password"]]) {
    assert.throws(() => cipher.decrypt(encrypted, other));
  }
  assert.throws(() => cipher.encrypt("secret", []));
  const separated = cipher.encrypt("secret", ["a/b", "c"]);
  assert.throws(() => cipher.decrypt(separated, ["a", "b/c"]));
});

test("rejects tampering with the payload, wrapped key, salt and version", () => {
  const cipher = encryption();
  const encrypted = cipher.encrypt("secret", context);
  for (const part of ["payload", "wrappedKey"]) {
    const envelope = JSON.parse(encrypted);
    envelope[part].tag = Buffer.alloc(16).toString("base64url");
    assert.throws(() => cipher.decrypt(JSON.stringify(envelope), context));
    assert.throws(() => cipher.rewrap(JSON.stringify(envelope), context));
  }
  const envelope = JSON.parse(encrypted);
  assert.throws(() => cipher.decrypt(JSON.stringify({...envelope, salt: Buffer.alloc(32).toString("base64url")}), context));
  assert.throws(() => cipher.decrypt(JSON.stringify({...envelope, version: 2}), context));
  assert.throws(() => cipher.decrypt(JSON.stringify({...envelope, masterKeyId: "missing"}), context));
});

test("rewraps only the data key and allows retiring the previous master key", () => {
  const original = createRuntimeKeyring();
  const oldCipher = new EnvelopeRuntimeFieldCipher(JSON.stringify(original));
  const encrypted = oldCipher.encrypt("secret", context);
  const replacement = createRuntimeKeyring();
  const both = {...replacement, keys: {...original.keys, ...replacement.keys}};
  const rotating = new EnvelopeRuntimeFieldCipher(JSON.stringify(both));
  const rewrapped = rotating.rewrap(encrypted, context);
  assert.deepEqual(JSON.parse(rewrapped).payload, JSON.parse(encrypted).payload);
  assert.notDeepEqual(JSON.parse(rewrapped).wrappedKey, JSON.parse(encrypted).wrappedKey);
  assert.equal(rotating.rewrap(rewrapped, context), rewrapped);
  assert.equal(rotating.decrypt(encrypted, context), "secret");
  assert.throws(() => oldCipher.decrypt(rewrapped, context));
  assert.equal(new EnvelopeRuntimeFieldCipher(JSON.stringify(replacement)).decrypt(rewrapped, context), "secret");
});

test("rejects legacy keys, missing active keys and malformed envelope encodings", () => {
  assert.throws(() => new EnvelopeRuntimeFieldCipher(Buffer.alloc(32).toString("base64")));
  assert.throws(() => new EnvelopeRuntimeFieldCipher(JSON.stringify({...createRuntimeKeyring(), keys: {}})));
  const cipher = encryption();
  assert.throws(() => cipher.decrypt("iv.tag.legacy", context));
  const envelope = JSON.parse(cipher.encrypt("secret", context));
  envelope.wrappedKey.iv = "invalid";
  assert.throws(() => cipher.decrypt(JSON.stringify(envelope), context));
});

function encryption(): EnvelopeRuntimeFieldCipher {
  return new EnvelopeRuntimeFieldCipher(JSON.stringify(createRuntimeKeyring()));
}
