# Anhänge und Workspace

> Vor jedem Executor-Aufruf legt der Graph-Runner einen node-spezifischen temporären Workspace mit Dateien und Wissensnotizen an und entfernt ihn danach.

Gehört zu: [Aufgabe](../index/aufgabe.md)

- Ort: `/tmp`; geladen werden die angehängten Dateiversionen und
  Wissensnotizen.
- **Prompt:** Genkit-Filesystem-Middleware (`@genkit-ai/middleware`),
  read-only.
- **Script:** Dateimetadaten (`files`) und die Funktionen `list_files()` und
  `read_file(display_name)`.

## Siehe auch

- [Prompt-Executor](./prompt-executor.md)
- [Script-Executor](./script-executor.md)
- [Dateien](../index/dateien.md)
