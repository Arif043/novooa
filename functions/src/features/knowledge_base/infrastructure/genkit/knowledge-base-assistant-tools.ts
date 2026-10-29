import {type Genkit} from "genkit";
import {
  defineExtractPageLinksTool,
  type ExtractPageLinksToolDependencies,
} from "./extract-page-links-tool.js";
import {type KnowledgeNoteToolDependencies} from "./knowledge-note-tool-support.js";
import {defineListKnowledgeNoteTitlesTool} from "./list-knowledge-note-titles-tool.js";
import {defineReadKnowledgeNoteTool} from "./read-knowledge-note-tool.js";
import {defineSearchKnowledgeNotesTool} from "./search-knowledge-notes-tool.js";

export type KnowledgeBaseAssistantToolDependencies =
  ExtractPageLinksToolDependencies & KnowledgeNoteToolDependencies;

export function defineKnowledgeBaseAssistantTools(
  ai: Genkit,
  dependencies: KnowledgeBaseAssistantToolDependencies,
) {
  return {
    listKnowledgeNoteTitles: defineListKnowledgeNoteTitlesTool(ai, dependencies),
    searchKnowledgeNotes: defineSearchKnowledgeNotesTool(ai, dependencies),
    readKnowledgeNote: defineReadKnowledgeNoteTool(ai, dependencies),
    extractPageLinks: defineExtractPageLinksTool(ai, dependencies),
  };
}
