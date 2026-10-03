import assert from "node:assert/strict";
import {mkdir, mkdtemp, readFile, readdir, rm, writeFile} from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import test, {type TestContext} from "node:test";
import {genkit} from "genkit/beta";
import {DirectorySkillStore} from "../../../../skills/infrastructure/local/directory-skill-store.js";
import {aiTurnMiddleware} from "./node-attachment-genkit.js";
import {prepareSkillDirectory} from "./skill-workspace.js";

async function temporaryDirectory(t: TestContext): Promise<string> {
  const directory = await mkdtemp(path.join(os.tmpdir(), "skill-workspace-"));
  t.after(() => rm(directory, {recursive: true, force: true}));
  return directory;
}

async function skillsFolderWith(t: TestContext, skills: Record<string, Record<string, string>>): Promise<DirectorySkillStore> {
  const root = await temporaryDirectory(t);
  for (const [name, files] of Object.entries(skills)) {
    for (const [relative, content] of Object.entries(files)) {
      await mkdir(path.dirname(path.join(root, name, relative)), {recursive: true});
      await writeFile(path.join(root, name, relative), content);
    }
  }
  return new DirectorySkillStore(root);
}

const skillMd = (name: string, description: string) => `---\nname: ${name}\ndescription: ${description}\n---\n# ${name}\nAnleitung für ${name}.\n`;

test("attached skills are copied as whole folders under their folder name", async (t) => {
  const store = await skillsFolderWith(t, {
    pdf: {"SKILL.md": skillMd("pdf", "Verarbeitet PDFs"), "references/REFERENCE.md": "Details", "scripts/run.py": "print()"},
    andere: {"SKILL.md": skillMd("andere", "Nicht angehängt")},
  });
  const workspace = await temporaryDirectory(t);

  const skillsDirectory = await prepareSkillDirectory(workspace, [{name: "pdf", description: ""}, {name: "pdf", description: ""}], store);

  assert.equal(skillsDirectory, path.join(workspace, "skills"));
  assert.deepEqual(await readdir(skillsDirectory!), ["pdf"]);
  assert.equal(await readFile(path.join(skillsDirectory!, "pdf", "references", "REFERENCE.md"), "utf8"), "Details");
  assert.equal(await readFile(path.join(skillsDirectory!, "pdf", "scripts", "run.py"), "utf8"), "print()");
});

test("without attachments nothing is prepared; without a reader or a folder the run fails readably", async (t) => {
  const store = await skillsFolderWith(t, {});
  const workspace = await temporaryDirectory(t);

  assert.equal(await prepareSkillDirectory(workspace, [], undefined), undefined);
  await assert.rejects(prepareSkillDirectory(workspace, [{name: "pdf", description: ""}], undefined), /nicht verfügbar/);
  await assert.rejects(prepareSkillDirectory(workspace, [{name: "pdf", description: ""}], store), /„pdf“ wurde nicht gefunden/);
});

test("the Genkit skills middleware lists the copied skills by folder name and serves SKILL.md, references via the filesystem", async (t) => {
  const store = await skillsFolderWith(t, {
    "pdf-verarbeitung": {
      "SKILL.md": "---\nname: Anderer Name\ndescription: >\n  Verarbeitet PDFs,\n  füllt Formulare.\n---\n# PDF\nSiehe references/REFERENCE.md.\n",
      "references/REFERENCE.md": "Referenzinhalt",
    },
  });
  const workspace = await temporaryDirectory(t);
  const skillsDirectory = await prepareSkillDirectory(workspace, [{name: "pdf-verarbeitung", description: ""}], store);
  const ai = genkit({});
  const requests: Array<{messages: unknown; tools: string[]}> = [];
  let step = 0;
  const model = ai.defineModel({name: "fake-skill-model"}, async (request) => {
    requests.push({messages: JSON.stringify(request.messages), tools: (request.tools ?? []).map((tool) => tool.name)});
    step++;
    if (step === 1) {
      return {message: {role: "model", content: [{toolRequest: {name: "use_skill", ref: "1", input: {skillName: "pdf-verarbeitung"}}}]}, finishReason: "stop"};
    }
    return {message: {role: "model", content: [{text: "fertig"}]}, finishReason: "stop"};
  });

  const response = await ai.generate({model, prompt: "Bitte ein PDF bearbeiten.", use: aiTurnMiddleware({
    rootDirectory: workspace, files: [], knowledgeFiles: [], skillsDirectory, skillCount: 1, cleanup: async () => undefined,
  })});

  assert.equal(response.text, "fertig");
  assert.ok(requests[0].tools.includes("use_skill"));
  assert.ok(requests[0].tools.includes("read_file"), "references are reachable through the filesystem middleware");
  assert.match(String(requests[0].messages), /pdf-verarbeitung - Verarbeitet PDFs, füllt Formulare\./);
  assert.match(String(requests[1].messages), /Siehe references\/REFERENCE\.md/);
  assert.equal(await readFile(path.join(skillsDirectory!, "pdf-verarbeitung", "references", "REFERENCE.md"), "utf8"), "Referenzinhalt");
});
