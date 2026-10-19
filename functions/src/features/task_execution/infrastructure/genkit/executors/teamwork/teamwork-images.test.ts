import assert from "node:assert/strict";
import {mkdtemp, readFile, rm} from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import {teamworkImageInstructions, writeTeamworkImages} from "./teamwork-images.js";

test("images of the instruction land as files in the workspace for the members", async (t) => {
  const root = await mkdtemp(path.join(os.tmpdir(), "teamwork-images-"));
  t.after(() => rm(root, {recursive: true, force: true}));

  const paths = await writeTeamworkImages(root, [
    "data:image/png;base64,aW1hZ2U=",
    "data:image/jpeg;base64,anBlZw==",
  ]);

  assert.deepEqual(paths, ["images/bild-1.png", "images/bild-2.jpg"]);
  assert.equal(await readFile(path.join(root, "images/bild-1.png"), "utf8"), "image");
  assert.match(teamworkImageInstructions(paths) ?? "", /images\/bild-1\.png[\s\S]*Nenne ihnen im Auftrag den Pfad/);
});

test("without images nothing is written and no hint is given", async () => {
  assert.deepEqual(await writeTeamworkImages("/does/not/exist", []), []);
  assert.equal(teamworkImageInstructions([]), undefined);
});
