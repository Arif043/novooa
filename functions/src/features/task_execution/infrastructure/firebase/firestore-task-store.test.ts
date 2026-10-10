import assert from "node:assert/strict";
import test from "node:test";
import {taskDefinitionFromDocument} from "./firestore-task-store.js";

const lookupNode = {
  id: "suche", title: "Datensatz suchen", description: "",
  outputs: [
    {key: "value", name: "Datensatz", showOnCanvas: true},
    {key: "found", name: "Gefunden"},
    {key: "kaputt", name: 42},
  ],
  config: {primitive: "documentLookup", collectionName: "kunden", filters: []},
};

const expectedOutputs = [
  {key: "value", name: "Datensatz", showOnCanvas: true},
  {key: "found", name: "Gefunden", showOnCanvas: false},
];

test("übernimmt die benannten Werte samt Leinwand-Flag, auch in Zweigen", () => {
  const task = taskDefinitionFromDocument("t1", {
    title: "Aufgabe",
    graph: {
      nodes: [
        lookupNode,
        {
          id: "weiche", title: "Weiche", description: "", outputs: [{key: "value", name: "Bedingung", showOnCanvas: true}],
          config: {
            primitive: "conditionalFlow", valueTemplate: "", choices: [],
            branches: [{id: "ja", label: "Ja", nodeIds: [], graph: {nodes: [{...lookupNode, id: "innen"}], edges: []}}],
          },
        },
      ],
      edges: [{from: "suche", to: "weiche"}],
    },
  });

  assert.deepEqual(task.nodes[0]?.outputs, expectedOutputs);
  const branch = task.nodes[1]?.config as {branches: {graph: {nodes: {outputs?: unknown}[]}}[]};
  assert.deepEqual(branch.branches[0]?.graph.nodes[0]?.outputs, expectedOutputs);
});

test("ohne gespeicherte Werte bleibt die Liste leer", () => {
  const {outputs: _ignored, ...withoutNames} = lookupNode;
  const task = taskDefinitionFromDocument("t1", {title: "Aufgabe", graph: {nodes: [withoutNames], edges: []}});

  assert.deepEqual(task.nodes[0]?.outputs, []);
});
