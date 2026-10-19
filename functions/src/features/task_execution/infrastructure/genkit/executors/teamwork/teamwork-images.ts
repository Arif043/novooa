import {mkdir, writeFile} from "node:fs/promises";
import path from "node:path";
import {imageExtensionFor} from "../../../../domain/services/image-content-type.js";

/** Ordner im Arbeitsordner, in dem die Bilder der Anweisung liegen. */
export const teamworkImageDirectoryName = "images";

/**
 * Legt die Bilder der Anweisung als Dateien in den Arbeitsordner. Nur der Orchestrator bekommt sie mit der
 * Anweisung; Mitarbeiter sehen sie über `read_file`, das Bilddateien als Bild an ihr Modell gibt.
 * Liefert die Pfade relativ zum Arbeitsordner.
 */
export async function writeTeamworkImages(rootDirectory: string, mediaUrls: string[]): Promise<string[]> {
  if (mediaUrls.length === 0) return [];
  await mkdir(path.join(rootDirectory, teamworkImageDirectoryName), {recursive: true});
  return Promise.all(mediaUrls.map(async (url, index) => {
    const {contentType, bytes} = imageOf(url);
    const relativePath = `${teamworkImageDirectoryName}/bild-${index + 1}.${imageExtensionFor(contentType)}`;
    await writeFile(path.join(rootDirectory, relativePath), bytes);
    return relativePath;
  }));
}

/** Hinweis für den Orchestrator: wo die Bilder liegen und dass er Mitarbeitern den Pfad nennen muss. */
export function teamworkImageInstructions(imagePaths: string[]): string | undefined {
  if (imagePaths.length === 0) return undefined;
  return [
    "Die Bilder dieser Anweisung liegen auch als Dateien im Arbeitsordner:",
    ...imagePaths.map((imagePath) => `- ${imagePath}`),
    "Mitarbeiter sehen die Bilder nur über diese Dateien. Nenne ihnen im Auftrag den Pfad, damit sie das Bild mit read_file selbst ansehen.",
  ].join("\n");
}

function imageOf(dataUrl: string): {contentType: string; bytes: Buffer} {
  const match = /^data:([^;,]+);base64,([\s\S]*)$/.exec(dataUrl);
  if (!match) throw new Error("Ein Bild der Anweisung ist keine Data-URL.");
  return {contentType: match[1], bytes: Buffer.from(match[2], "base64")};
}
