import assert from "node:assert/strict";
import test from "node:test";
import {type WorkflowExecutionScope} from "../../../domain/executors/node-executor.js";
import {
  type NodeExecutionResult,
  type WorkflowNode,
} from "./task-definition.js";
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

test("resolves a node's main value flat under its name from outputs", () => {
  const resolver = graphResolverFor(
    [stringInputNode("n1", "eingang")],
    [result("n1", "stringInput", {value: {type: "string", value: "Hallo"}})],
  );

  assert.equal(resolver.resolveValue("{{eingang}}"), "Hallo");
});

test(
  "löst {{name.value}} nicht auf — nur die flache Form {{name}}",
  () => {
    const resolver = graphResolverFor(
      [stringInputNode("n1", "eingang")],
      [result("n1", "stringInput", {value: {type: "string", value: "Hallo"}})],
    );

    assert.equal(resolver.resolveValue("{{eingang}}"), "Hallo");
    assert.equal(resolver.resolveValue("{{eingang.value}}"), undefined);
  },
);

test("resolves further outputs flat under their names from outputs, not under the node name", () => {
  const resolver = graphResolverFor(
    [{
      ...stringInputNode("n1", "eingang"), primitive: "readEmail", config: {primitive: "readEmail"},
      outputs: [
        {key: "value", name: "eingang", showOnCanvas: true},
        {key: "sender", name: "Absender", showOnCanvas: false},
      ],
    }],
    [result("n1", "readEmail", {
      value: {type: "string", value: "Hallo"},
      sender: {type: "string", value: "a@b.de"},
      subject: {type: "string", value: "ohne Namen"},
    })],
  );

  assert.equal(resolver.resolveValue("{{eingang}}"), "Hallo");
  assert.equal(resolver.resolveValue("{{Absender}}"), "a@b.de");
  assert.equal(resolver.resolveValue("{{eingang.sender}}"), undefined);
  assert.equal(resolver.resolveValue("{{subject}}"), undefined);
});

test("flattens structured prompt fields directly without a node name", () => {
  const resolver = graphResolverFor(
    [{
      id: "n1",
      primitive: "prompt",
      title: "",
      description: "",
      outputs: [],
      config: {
        primitive: "prompt",
        instruction: "",
        outputType: "structured",
        choices: [],
        structuredFields: [
          {name: "Name", description: "", type: "string"},
          {name: "Alter", description: "", type: "string"},
        ],
        firstChoice: "",
        secondChoice: "",
        attachments: [],
        knowledgeAttachments: [],
        skillAttachments: [],
      },
    }],
    [result("n1", "prompt", {
      value: {type: "json", value: {Name: "Anna", Alter: 30}},
      Name: {type: "string", value: "Anna"},
      Alter: {type: "number", value: 30},
    })],
  );

  assert.equal(resolver.resolveValue("{{Name}}"), "Anna");
  assert.equal(resolver.resolveValue("{{Alter}}"), 30);
  assert.equal(resolver.resolveValue("{{value}}"), undefined);
});

test("flattens dialog input fields directly without a node name", () => {
  const resolver = graphResolverFor(
    [{
      id: "n1",
      primitive: "dialogInput",
      title: "",
      description: "",
      outputs: [],
      config: {primitive: "dialogInput", instruction: "", fields: [
        {name: "Kundennummer", type: "string", options: []},
      ]},
    }],
    [result("n1", "dialogInput", {
      value: {type: "json", value: {Kundennummer: "K-1"}},
      Kundennummer: {type: "string", value: "K-1"},
    })],
  );

  assert.equal(resolver.resolveValue("{{Kundennummer}}"), "K-1");
});

test("flattens script workflow outputs, but keeps a script without them under its output name", () => {
  const scriptNode = (id: string, mainName: string): WorkflowNode => ({
    id, primitive: "script", title: "", description: "", outputs: namedMain(mainName),
    config: {primitive: "script", script: "", inputTemplate: "", attachments: []},
  });
  const resolver = graphResolverFor(
    [scriptNode("n1", ""), scriptNode("n2", "text")],
    [
      result("n1", "script", {summe: {type: "number", value: 42.5}, faellig: {type: "datetime", value: "2026-10-01"}}),
      result("n2", "script", {value: {type: "string", value: "Hallo"}}),
    ],
  );

  assert.equal(resolver.resolveValue("{{summe}}"), 42.5);
  assert.equal(resolver.resolveValue("{{faellig}}"), "2026-10-01");
  assert.equal(resolver.resolveValue("{{text}}"), "Hallo");
});

function resolverFor(scope: WorkflowExecutionScope): TemplateExpressionResolver {
  return new TemplateExpressionResolver(() => variableTemplateContextFor(
    {nodes: [], edges: []}, new Map(), {}, scope,
  ));
}

function graphResolverFor(
  nodes: WorkflowNode[],
  results: NodeExecutionResult[],
): TemplateExpressionResolver {
  return new TemplateExpressionResolver(() => variableTemplateContextFor(
    {nodes, edges: []},
    new Map(results.map((nodeResult) => [nodeResult.nodeId, nodeResult])),
    {},
  ));
}

function stringInputNode(id: string, mainName: string): WorkflowNode {
  return {
    id,
    primitive: "stringInput",
    title: "",
    description: "",
    outputs: namedMain(mainName),
    config: {primitive: "stringInput", value: ""},
  };
}

function namedMain(name: string): WorkflowNode["outputs"] {
  return name ? [{key: "value", name, showOnCanvas: true}] : [];
}

test("a node without a name for its main value is not reachable, not even by its id", () => {
  const resolver = graphResolverFor(
    [stringInputNode("n1", "")],
    [result("n1", "stringInput", {value: {type: "string", value: "Hallo"}})],
  );

  assert.equal(resolver.resolveValue("{{n1}}"), undefined);
});

function result(
  nodeId: string,
  primitive: WorkflowNode["primitive"],
  outputs: NodeExecutionResult["outputs"],
): NodeExecutionResult {
  return {nodeId, primitive, status: "executed", outputs};
}
