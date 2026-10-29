import assert from "node:assert/strict";
import {mkdtemp, readFile, rm} from "node:fs/promises";
import {tmpdir} from "node:os";
import {join} from "node:path";
import test from "node:test";
import {type KnowledgeBaseStore} from "../../../../knowledge_base/domain/repositories/knowledge-base-store.js";
import {prepareKnowledgeFiles} from "./knowledge-note-workspace.js";

/** Notizen als Adjazenzliste: Notiz-ID → IDs der ausgehend verlinkten Notizen. */
function storeWith(links: Record<string, string[]>): KnowledgeBaseStore {
  return {
    async loadNote(_teamId, attachment) {
      return {...attachment, title: attachment.noteId, path: `${attachment.noteId}.md`,
        content: `# ${attachment.noteId}`, outgoingLinks: links[attachment.noteId] ?? []};
    },
  };
}

const attach = (noteId: string) => ({knowledgeBaseId: "default", noteId, title: noteId, path: `${noteId}.md`});

async function resolvedIds(links: Record<string, string[]>, attached: string[]) {
  const directory = await mkdtemp(join(tmpdir(), "novooa-knowledge-"));
  try {
    const notes = await prepareKnowledgeFiles(directory, "team-1", attached.map(attach), storeWith(links));
    return notes.map((note) => ({id: note.noteId, direct: note.isDirectAttachment}));
  } finally {
    await rm(directory, {force: true, recursive: true});
  }
}

test("collects linked notes level by level", async () => {
  const notes = await resolvedIds({a: ["b", "c"], b: ["d"], c: []}, ["a"]);

  assert.deepEqual(notes.map((note) => note.id), ["a", "b", "c", "d"]);
});

test("a deep branch does not crowd out a second attachment at the note limit", async () => {
  const manyLinks = Array.from({length: 60}, (_, index) => `link-${index}`);

  const notes = await resolvedIds({a: manyLinks}, ["a", "z"]);

  assert.equal(notes.length, 50);
  assert.deepEqual(notes.slice(0, 2), [{id: "a", direct: true}, {id: "z", direct: true}]);
});

test("an attachment linked by another attachment stays direct and appears once", async () => {
  const notes = await resolvedIds({a: ["b"], b: ["a"]}, ["a", "b"]);

  assert.deepEqual(notes, [{id: "a", direct: true}, {id: "b", direct: true}]);
});

test("stops following links after five levels", async () => {
  const chain = {n0: ["n1"], n1: ["n2"], n2: ["n3"], n3: ["n4"], n4: ["n5"], n5: ["n6"], n6: ["n7"]};

  const notes = await resolvedIds(chain, ["n0"]);

  assert.deepEqual(notes.map((note) => note.id), ["n0", "n1", "n2", "n3", "n4", "n5"]);
});

test("names files after the note title and lists the links between collected notes", async () => {
  const directory = await mkdtemp(join(tmpdir(), "novooa-knowledge-"));
  try {
    const notes = await prepareKnowledgeFiles(directory, "team-1", [attach("a")], storeWith({a: ["b"], b: []}));

    assert.deepEqual(notes.map((note) => [note.filename, note.depth, note.linkedTitles]), [
      ["knowledge/a.md", 0, ["b"]],
      ["knowledge/b.md", 1, []],
    ]);
    assert.equal(await readFile(join(directory, "knowledge", "b.md"), "utf8"), "# b");
  } finally {
    await rm(directory, {force: true, recursive: true});
  }
});

