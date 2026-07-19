import {type KnowledgeBaseStore} from "../domain/repositories/knowledge-base-store.js";
import {type ObjectStore} from "../domain/repositories/object-store.js";

export type TaskGraphRuntime = {
  objectStore: ObjectStore;
  knowledgeBaseStore: KnowledgeBaseStore;
};
