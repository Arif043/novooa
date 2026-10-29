/** Eine Wissensnotiz der Wissensbasis eines Teams (Markdown mit `[[Links]]`). */
export type KnowledgeNote = {
  id: string;
  title: string;
  path: string;
  content: string;
};
