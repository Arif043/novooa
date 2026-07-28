import {type KnowledgeBaseStore} from "../../../../knowledge_base/domain/repositories/knowledge-base-store.js";
import {type ObjectStore} from "../../../../files/domain/repositories/object-store.js";
import {type TeamFileStore} from "../../../../files/domain/repositories/team-file-store.js";
import {type TaskMessageSender} from "../../../domain/repositories/task-message-sender.js";

export type TaskGraphRuntime = {
  objectStore: ObjectStore;
  knowledgeBaseStore: KnowledgeBaseStore;
  teamFileStore: TeamFileStore;
  messageSender: TaskMessageSender;
};
