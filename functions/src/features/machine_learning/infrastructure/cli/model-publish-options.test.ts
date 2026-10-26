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

test("replaces a published version only with the replace-version flag", () => {
  assert.equal(modelPublishOptionsFromArguments(argumentsFor()).replaceVersion, false);
  const options = modelPublishOptionsFromArguments([...argumentsFor(), "--replace-version", "--dry-run"]);
  assert.equal(options.replaceVersion, true);
  assert.equal(options.dryRun, true);
});

test("rejects a missing required option", () => {
  assert.throws(() => modelPublishOptionsFromArguments(["--project", "project-1"]), /--manifest fehlt/);
});

function argumentsFor(): readonly string[] {
  return ["--project", "project-1", "--manifest", "model.json", "--artifact", "model.onnx"];
}

test("collects repeated weight files and named resources", () => {
  const options = modelPublishOptionsFromArguments([
    ...argumentsFor(), "--external-data", "a.bin", "--external-data", "b.bin", "--resource", "labels=labels.json",
  ]);

  assert.deepEqual(options.externalDataPaths, ["a.bin", "b.bin"]);
  assert.deepEqual(options.resources, [{name: "labels", path: "labels.json"}]);
});

test("rejects a resource without name and a repeated single option", () => {
  assert.throws(() => modelPublishOptionsFromArguments([...argumentsFor(), "--resource", "labels.json"]), /<name>=<datei>/);
  assert.throws(() => modelPublishOptionsFromArguments([...argumentsFor(), "--manifest", "other.json"]), /doppelt/);
});
