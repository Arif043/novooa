import assert from "node:assert/strict";
import test from "node:test";
import {modelPublishOptionsFromArguments} from "./model-publish-options.js";

test("uses the required project without a storage bucket", () => {
  const options = modelPublishOptionsFromArguments(argumentsFor());
  assert.equal(options.projectId, "project-1");
  assert.equal(options.dryRun, false);
});

test("accepts the dry-run flag", () => {
  const options = modelPublishOptionsFromArguments([...argumentsFor(), "--dry-run"]);
  assert.equal(options.dryRun, true);
});

test("rejects a missing required option", () => {
  assert.throws(() => modelPublishOptionsFromArguments(["--project", "project-1"]), /--manifest fehlt/);
});

function argumentsFor(): readonly string[] {
  return ["--project", "project-1", "--manifest", "model.json", "--artifact", "model.onnx"];
}
