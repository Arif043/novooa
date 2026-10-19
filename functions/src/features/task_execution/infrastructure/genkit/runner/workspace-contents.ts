import path from "node:path";
import {type KnowledgeBaseStore} from
  "../../../../knowledge_base/domain/repositories/knowledge-base-store.js";
import {type Employee} from "../../../../employees/domain/entities/employee.js";
import {type EmployeeStore} from "../../../../employees/domain/repositories/employee-store.js";
import {type ObjectStore} from "../../../../files/domain/repositories/object-store.js";
import {type SkillContentReader} from "../../../../skills/domain/repositories/skill-content-reader.js";
import {type NodeAttachment} from "./task-definition.js";

export type PreparedNodeAttachment = NodeAttachment & {
  filename: string;
};

/** Woher der Workspace eines Bausteins seine Inhalte holt. */
export type NodeAttachmentSources = {
  objectStore: ObjectStore;
  knowledgeBaseStore: KnowledgeBaseStore;
  skillContentReader?: SkillContentReader;
  employeeStore?: EmployeeStore;
};

/** Lädt einen Mitarbeiter frisch aus dem Speicher; ein gelöschter Mitarbeiter bricht den Lauf lesbar ab. */
export async function loadEmployee(teamId: string, employeeId: string, store?: EmployeeStore): Promise<Employee> {
  if (store === undefined) throw new Error("Mitarbeiter sind in dieser Umgebung nicht verfügbar.");
  const employee = await store.find(teamId, employeeId);
  if (employee === null) {
    throw new Error("Der zugewiesene Mitarbeiter wurde nicht gefunden. Wurde er gelöscht? Wähle im Baustein einen anderen Mitarbeiter.");
  }
  return employee;
}

export async function downloadAttachments(
  rootDirectory: string,
  attachments: NodeAttachment[],
  objectStore: ObjectStore,
): Promise<PreparedNodeAttachment[]> {
  return Promise.all(
    attachments.map((attachment, index) =>
      downloadAttachment(rootDirectory, attachment, index, objectStore),
    ),
  );
}

async function downloadAttachment(
  rootDirectory: string,
  attachment: NodeAttachment,
  index: number,
  objectStore: ObjectStore,
): Promise<PreparedNodeAttachment> {
  const filename = safeFilename(attachment.displayName, index);
  const destination = path.join(rootDirectory, filename);
  await objectStore.downloadToFile(attachment.storagePath, destination);
  return {...attachment, filename};
}

function safeFilename(displayName: string, index: number): string {
  const fallback = `datei-${index + 1}`;
  const normalized = displayName.trim() || fallback;
  const safeName = normalized.replace(/[^a-zA-Z0-9._-]+/g, "_");
  return `${index + 1}-${safeName.slice(0, 120)}`;
}
