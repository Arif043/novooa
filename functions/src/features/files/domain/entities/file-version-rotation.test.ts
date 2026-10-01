import assert from "node:assert/strict";
import test from "node:test";
import {
  DEFAULT_FILE_VERSION_LIMIT,
  parseFileVersionLimit,
  versionsToRotateOut,
} from "./file-version-rotation.js";

const versions = ["a", "b", "c", "d"].map((id, index) => ({id, createdAt: index}));

test("rotates out the oldest versions beyond the limit", () => {
  const removed = versionsToRotateOut(versions, 2, "d").map((v) => v.id);
  assert.deepEqual(removed, ["b", "a"]);
});

test("keeps the current version even when it is not the newest", () => {
  const removed = versionsToRotateOut(versions, 2, "a").map((v) => v.id);
  assert.deepEqual(removed, ["c", "b"]);
});

test("rotates nothing within the limit", () => {
  assert.deepEqual(versionsToRotateOut(versions, 4, "d"), []);
});

test("never rotates below one version", () => {
  assert.equal(versionsToRotateOut(versions, 0, "d").length, 3);
});

test("parses the configured version limit", () => {
  assert.equal(parseFileVersionLimit(undefined), DEFAULT_FILE_VERSION_LIMIT);
  assert.equal(parseFileVersionLimit(" 25 "), 25);
  assert.throws(() => parseFileVersionLimit("0"));
  assert.throws(() => parseFileVersionLimit("abc"));
});
