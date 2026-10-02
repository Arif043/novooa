import {canonicalSkillMarkdown} from "./skill-manifest.js";
import {skillEntryFile, type SkillPackage} from "./skill-package.js";

/** Das Paket unter neuem Namen: `SKILL.md` bekommt den Namen im Kopf, damit Ordner und Kopf übereinstimmen. */
export function renamedSkillPackage(skill: SkillPackage, name: string): SkillPackage {
  const decoder = new TextDecoder();
  const files = skill.files.map((file) => file.path === skillEntryFile
    ? {path: file.path, bytes: new TextEncoder().encode(canonicalSkillMarkdown(decoder.decode(file.bytes), name))}
    : file);
  return {...skill, name, files};
}
