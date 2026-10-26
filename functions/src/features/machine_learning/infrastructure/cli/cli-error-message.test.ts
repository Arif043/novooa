import assert from "node:assert/strict";
import test from "node:test";
import {SystemModelVersionConflictError} from "../../domain/usecases/publish-system-model.js";
import {cliErrorMessage} from "./cli-error-message.js";

const reference = {format: "onnx" as const, contentType: "application/onnx", sizeBytes: 1, sha256: "0".repeat(64)};

test("tells the operator how to replace a published version", () => {
  const conflict = new SystemModelVersionConflictError(
    "model", {...reference, artifactId: "model", versionId: "1"}, {...reference, artifactId: "model", versionId: "2"},
  );
  assert.match(cliErrorMessage(conflict, "fallback"), /model@1.*model@2.*--replace-version/);
});

test("uses the error message or the fallback otherwise", () => {
  assert.equal(cliErrorMessage(new Error("kaputt"), "fallback"), "kaputt");
  assert.equal(cliErrorMessage("kaputt", "fallback"), "fallback");
});
