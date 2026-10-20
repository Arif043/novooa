import assert from "node:assert/strict";
import test from "node:test";
import {RuntimePassword} from "./runtime-password.js";

test("a password needs at least 12 characters", () => {
  assert.throws(() => RuntimePassword.from("elf-zeichen"), /12 bis 1000/);
  assert.equal(RuntimePassword.from("zwoelf-zeich").value, "zwoelf-zeich");
});
