import assert from "node:assert/strict";
import test from "node:test";
import {type WorkflowExecutionScope} from "../../../domain/executors/node-executor.js";
import {
  TemplateExpressionResolver,
  variableTemplateContextFor,
} from "./template-expression-resolver.js";

test("resolves the current iteration value without serializing it", () => {
  const resolver = resolverFor({iteration: {index: 1, value: {bounds: [1, 2]}}});

  assert.deepEqual(resolver.resolveValue("{{iteration.value.bounds}}"), [1, 2]);
  assert.equal(resolver.resolveText("Nr. {{iteration.index}}"), "Nr. 1");
});

test("resolves outer graph values from the global scope", () => {
  const resolver = resolverFor({global: {
    invoice: {value: {number: "R-42"}},
    input: {customer: "Meyer GmbH"},
  }});

  assert.equal(resolver.resolveValue("{{global.invoice.value.number}}"), "R-42");
  assert.equal(resolver.resolveValue("{{invoice.value.number}}"), "R-42");
  assert.equal(resolver.resolveValue("{{global.input.customer}}"), "Meyer GmbH");
});

test("resolves media references without converting them to text", () => {
  const media = {
    fileId: "file-1", versionId: "version-1", displayName: "beleg.png",
    contentType: "image/png", sizeBytes: 12,
  };
  const resolver = resolverFor({global: {beleg: {value: media}}});

  assert.deepEqual(resolver.resolveMediaReferences("Prüfe {{beleg.value}}."), [media]);
  assert.equal(resolver.resolveText("{{beleg.value}}").includes("file-1"), true);
  assert.equal(resolver.resolveTextWithoutMediaReferences("Prüfe {{beleg.value}}."), "Prüfe .");
});

function resolverFor(scope: WorkflowExecutionScope): TemplateExpressionResolver {
  return new TemplateExpressionResolver(() => variableTemplateContextFor(
    {nodes: [], edges: []}, new Map(), {}, scope,
  ));
}
