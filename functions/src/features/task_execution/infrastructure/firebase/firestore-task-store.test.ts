import assert from "node:assert/strict";
import test from "node:test";
import {taskDefinitionFromDocument} from "./firestore-task-store.js";

const lookupNode = {
  id: "suche", title: "Datensatz suchen", description: "", outputName: "Datensatz",
  outputFieldNames: {found: "Gefunden", record: "Eintrag", kaputt: 42},
  config: {primitive: "documentLookup", collectionName: "kunden", filters: []},
};

test("übernimmt die Namen der weiteren Werte, auch in Zweigen", () => {
  const task = taskDefinitionFromDocument("t1", {
    title: "Aufgabe",
    graph: {
      nodes: [
        lookupNode,
        {
          id: "weiche", title: "Weiche", description: "", outputName: "Bedingung",
          config: {
            primitive: "conditionalFlow", valueTemplate: "", choices: [],
            branches: [{id: "ja", label: "Ja", nodeIds: [], graph: {nodes: [{...lookupNode, id: "innen"}], edges: []}}],
          },
        },
      ],
      edges: [{from: "suche", to: "weiche"}],
    },
  });

  assert.deepEqual(task.nodes[0]?.outputFieldNames, {found: "Gefunden", record: "Eintrag"});
  const branch = task.nodes[1]?.config as {branches: {graph: {nodes: {outputFieldNames?: unknown}[]}}[]};
  assert.deepEqual(branch.branches[0]?.graph.nodes[0]?.outputFieldNames, {found: "Gefunden", record: "Eintrag"});
});

test("ohne gespeicherte Namen bleibt die Zuordnung leer", () => {
  const {outputFieldNames: _ignored, ...withoutNames} = lookupNode;
  const task = taskDefinitionFromDocument("t1", {title: "Aufgabe", graph: {nodes: [withoutNames], edges: []}});

  assert.deepEqual(task.nodes[0]?.outputFieldNames, {});
});
