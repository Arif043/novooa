import assert from "node:assert/strict";
import test from "node:test";
import {modelPublishOptionsFromArguments} from "./model-publish-options.js";

test("uses a Firebase bucket derived from the required project", () => {
  const options = modelPublishOptionsFromArguments(argumentsFor());
  assert.equal(options.bucketName, "project-1.firebasestorage.app");
  assert.equal(options.dryRun, false);
});

test("accepts the dry-run flag and an explicit bucket", () => {
  const options = modelPublishOptionsFromArguments([...argumentsFor(), "--bucket", "models.example", "--dry-run"]);
  assert.equal(options.bucketName, "models.example");
  assert.equal(options.dryRun, true);
});

test("rejects a missing required option", () => {
  assert.throws(() => modelPublishOptionsFromArguments(["--project", "project-1"]), /--manifest fehlt/);
});

function argumentsFor(): readonly string[] {
  return ["--project", "project-1", "--manifest", "model.json", "--artifact", "model.onnx"];
}
