import assert from "node:assert/strict";
import test from "node:test";
import {TransferCategorySelection} from "./transfer-category.js";
import {InvalidTransferArchiveError, InvalidTransferRequestError} from "./transfer-errors.js";
import {createTransferManifest, transferManifestFrom} from "./transfer-manifest.js";
import {isTeamStoragePath, TransferTeamMapping} from "./transfer-team-mapping.js";

test("orders a selection in import order and removes duplicates", () => {
  const selection = TransferCategorySelection.from(["tasks", "files", "tasks"]);
  assert.deepEqual(selection.categories, ["files", "tasks"]);
});

test("rejects an empty or unknown selection", () => {
  assert.throws(() => TransferCategorySelection.from([]), InvalidTransferRequestError);
  assert.throws(() => TransferCategorySelection.from(["triggers"]), InvalidTransferRequestError);
  assert.throws(() => TransferCategorySelection.from("files"), InvalidTransferRequestError);
});

test("restricts a selection to the categories contained in an export", () => {
  const selection = TransferCategorySelection.from(["files", "knowledge"]).restrictedTo(["knowledge", "tasks"]);
  assert.deepEqual(selection.categories, ["knowledge"]);
  assert.throws(() => TransferCategorySelection.from(["files"]).restrictedTo(["tasks"]), InvalidTransferRequestError);
});

test("round-trips a manifest", () => {
  const manifest = createTransferManifest({sourceTeamId: "team-1", counts: {files: 2, tasks: 0},
    exportedAt: new Date("2026-10-01T08:00:00Z")});
  assert.deepEqual(transferManifestFrom(JSON.parse(JSON.stringify(manifest))), manifest);
  assert.deepEqual(manifest.categories, ["files", "tasks"]);
});

test("rejects foreign or incompatible manifests", () => {
  assert.throws(() => transferManifestFrom(undefined), InvalidTransferArchiveError);
  assert.throws(() => transferManifestFrom({format: "other"}), InvalidTransferArchiveError);
  assert.throws(() => transferManifestFrom({format: "novooa-export", version: 2}), InvalidTransferArchiveError);
  assert.throws(() => transferManifestFrom({format: "novooa-export", version: 1, exportedAt: "x",
    sourceTeamId: "t", categories: ["triggers"], counts: {}}), InvalidTransferArchiveError);
});

test("rewrites team storage paths and references to the target team", () => {
  const mapping = new TransferTeamMapping("team-a", "team-b");
  assert.equal(mapping.storagePath("teams/team-a/files/f1/versions/v1/a.pdf"), "teams/team-b/files/f1/versions/v1/a.pdf");
  assert.equal(mapping.references("{\"storagePath\":\"teams/team-a/files/f1\"}"), "{\"storagePath\":\"teams/team-b/files/f1\"}");
});

test("rejects storage paths outside the source team or with traversal", () => {
  const mapping = new TransferTeamMapping("team-a", "team-b");
  assert.throws(() => mapping.storagePath("teams/other/files/f1/versions/v1/a.pdf"), InvalidTransferArchiveError);
  assert.throws(() => mapping.storagePath("teams/team-a/files/../../../etc/passwd"), InvalidTransferArchiveError);
  assert.equal(isTeamStoragePath("team-a", "teams/team-a/files/f1/versions/v1/a.pdf"), true);
  assert.equal(isTeamStoragePath("team-a", "teams/team-a/files//a.pdf"), false);
});
