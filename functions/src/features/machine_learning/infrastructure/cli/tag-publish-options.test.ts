import assert from "node:assert/strict";
import test from "node:test";
import {shippedModelTagsPath} from "./repository-files.js";
import {tagPublishOptionsFromArguments} from "./tag-publish-options.js";

test("publishes the shipped vocabulary unless another file is given", () => {
  assert.equal(tagPublishOptionsFromArguments(["--project", "p"]).tagsPath, shippedModelTagsPath);
  assert.equal(tagPublishOptionsFromArguments(["--project", "p", "--tags", "eigene.json"]).tagsPath, "eigene.json");
});

test("accepts a dry run and requires the project", () => {
  assert.equal(tagPublishOptionsFromArguments(["--project", "p", "--dry-run"]).dryRun, true);
  assert.throws(() => tagPublishOptionsFromArguments(["--dry-run"]), /--project fehlt/);
});
