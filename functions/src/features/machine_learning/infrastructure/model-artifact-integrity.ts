import {createHash} from "node:crypto";
import {type ModelArtifactReference} from "../domain/entities/model-artifact-reference.js";

export function verifyModelArtifact(
  reference: ModelArtifactReference,
  content: Uint8Array,
): Uint8Array {
  verifySize(reference, content);
  verifyChecksum(reference, content);
  return content;
}

function verifySize(reference: ModelArtifactReference, content: Uint8Array): void {
  if (content.byteLength === reference.sizeBytes) return;
  throw new Error(`Die Größe des Modell-Artefakts ${reference.artifactId} stimmt nicht.`);
}

function verifyChecksum(
  reference: ModelArtifactReference,
  content: Uint8Array,
): void {
  const checksum = createHash("sha256").update(content).digest("hex");
  if (checksum === reference.sha256.toLowerCase()) return;
  throw new Error(`Die Prüfsumme des Modell-Artefakts ${reference.artifactId} stimmt nicht.`);
}
