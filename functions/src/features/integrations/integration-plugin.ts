import {type NodeExecutor} from "../task_execution/domain/executors/node-executor.js";

/**
 * Ein fest eingebautes Plugin: ein Modul, das ein externes System an novooa anschließt und dafür Bausteine mitbringt.
 * Der Kern importiert nichts aus `features/integrations`; verdrahtet wird nur in `shared/local` (siehe
 * `registerIntegrationPlugins`). Der Vertrag wächst mit den Plugins, nicht vorab.
 */
export type IntegrationPlugin = {
  id: string;
  /** Executoren der Bausteine, die das Plugin mitbringt (Primitive stehen in `workflowPrimitives`). */
  executors: readonly NodeExecutor[];
};
