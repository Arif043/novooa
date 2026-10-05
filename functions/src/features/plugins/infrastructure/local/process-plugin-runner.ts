import {spawn} from "node:child_process";
import path from "node:path";
import {pathToFileURL} from "node:url";
import {type PluginPrimitiveDefinition} from "../../domain/entities/plugin-manifest.js";
import {PluginNotFoundError} from "../../domain/entities/stored-plugin.js";
import {
  PluginRunError,
  type PluginPrimitiveRun,
  type PluginRunner,
  type PluginTriggerEvent,
  type PluginTriggerPoll,
  type PluginTriggerPollResult,
  type PluginTriggerRunner,
} from "../../domain/repositories/plugin-runner.js";
import {type PluginSettingsStore} from "../../domain/repositories/plugin-settings-store.js";
import {type PluginStore} from "../../domain/repositories/plugin-store.js";
import {type NodeOutputValue} from "../../../task_execution/domain/entities/workflow-value.js";

export type ProcessPluginRunnerOptions = {
  timeoutMilliseconds: number;
  maximumOutputBytes: number;
  maximumOldSpaceMegabytes: number;
  /** Überschreibbar für Tests; Standard ist die mitkompilierte `plugin-host.js`. */
  hostFile: string;
  nodeExecutable: string;
};

const defaults: ProcessPluginRunnerOptions = {
  timeoutMilliseconds: 30_000,
  maximumOutputBytes: 1024 * 1024,
  maximumOldSpaceMegabytes: 128,
  hostFile: path.join(__dirname, "plugin-host.js"),
  nodeExecutable: process.execPath,
};

/**
 * Führt Plugin-Code in einem eigenen Node-Prozess aus: ohne geerbte Umgebung (keine Geheimnisse der Runtime), mit dem
 * Permission-Modell (nur Lesen im Plugin-Ordner, keine Kindprozesse, keine Worker, keine Schreibzugriffe), mit
 * Zeit- und Speicherlimit. Netzwerkzugriffe lassen sich mit Node nicht einschränken; die Vertrauensgrenze ist deshalb
 * die Signatur des Herausgebers.
 */
export class ProcessPluginRunner implements PluginRunner, PluginTriggerRunner {
  private readonly options: ProcessPluginRunnerOptions;

  constructor(
    private readonly store: PluginStore,
    private readonly settings: PluginSettingsStore,
    private readonly pluginsDirectory: string,
    options: Partial<ProcessPluginRunnerOptions> = {},
  ) {
    this.options = {...defaults, ...options};
  }

  async runPrimitive(run: PluginPrimitiveRun): Promise<Record<string, NodeOutputValue>> {
    const plugin = await this.store.find(run.pluginId);
    if (plugin === undefined) throw new PluginNotFoundError(run.pluginId);
    const definition = plugin.manifest.primitives.find((primitive) => primitive.type === run.nodeType);
    if (definition === undefined) throw new PluginRunError(`Das Plugin „${plugin.name}“ kennt den Baustein „${run.nodeType}“ nicht.`);
    const pluginDirectory = path.join(this.pluginsDirectory, plugin.id);
    const raw = await this.execute(pluginDirectory, {
      entryUrl: pathToFileURL(path.join(pluginDirectory, plugin.manifest.entry)).href,
      kind: "primitive",
      type: run.nodeType,
      settings: run.settings,
      panel: await this.settings.read(plugin.id),
    }, plugin.name);
    return typedOutputs(definition, raw, plugin.name);
  }

  async pollTrigger(poll: PluginTriggerPoll): Promise<PluginTriggerPollResult> {
    const plugin = await this.store.find(poll.pluginId);
    if (plugin === undefined) throw new PluginNotFoundError(poll.pluginId);
    if (!plugin.manifest.triggers.some((trigger) => trigger.type === poll.triggerType)) {
      throw new PluginRunError(`Das Plugin „${plugin.name}“ kennt den Trigger „${poll.triggerType}“ nicht.`);
    }
    const pluginDirectory = path.join(this.pluginsDirectory, plugin.id);
    const raw = await this.execute(pluginDirectory, {
      entryUrl: pathToFileURL(path.join(pluginDirectory, plugin.manifest.entry)).href,
      kind: "trigger",
      type: poll.triggerType,
      settings: poll.settings,
      panel: await this.settings.read(plugin.id),
      state: poll.state,
    }, plugin.name);
    return triggerResult(raw, poll.state, plugin.name);
  }

  private execute(pluginDirectory: string, request: unknown, pluginName: string): Promise<unknown> {
    const {hostFile, maximumOldSpaceMegabytes, maximumOutputBytes, timeoutMilliseconds, nodeExecutable} = this.options;
    return new Promise((resolve, reject) => {
      const child = spawn(nodeExecutable, [
        "--permission", `--allow-fs-read=${hostFile}`, `--allow-fs-read=${pluginDirectory}`,
        `--max-old-space-size=${maximumOldSpaceMegabytes}`, hostFile,
      ], {env: {}, stdio: ["pipe", "pipe", "ignore"]});
      const chunks: Buffer[] = [];
      let size = 0;
      let settled = false;
      const finish = (action: () => void) => {
        if (settled) return;
        settled = true;
        clearTimeout(timer);
        child.kill("SIGKILL");
        action();
      };
      const timer = setTimeout(() => finish(() => reject(new PluginRunError(
        `Das Plugin „${pluginName}“ hat nicht innerhalb von ${timeoutMilliseconds / 1000} Sekunden geantwortet.`))), timeoutMilliseconds);
      child.stdout.on("data", (chunk: Buffer) => {
        size += chunk.length;
        if (size > maximumOutputBytes) {
          finish(() => reject(new PluginRunError(`Das Plugin „${pluginName}“ hat zu viel Ausgabe erzeugt.`)));
          return;
        }
        chunks.push(chunk);
      });
      child.on("error", (error) => finish(() => reject(new PluginRunError(`Das Plugin „${pluginName}“ ließ sich nicht starten: ${error.message}`))));
      child.on("close", () => finish(() => {
        try {
          const response = JSON.parse(Buffer.concat(chunks).toString("utf8")) as {ok: boolean; outputs?: unknown; error?: string};
          if (response.ok) resolve(response.outputs);
          else reject(new PluginRunError(`Das Plugin „${pluginName}“ meldet einen Fehler: ${response.error ?? "unbekannt"}`));
        } catch {
          reject(new PluginRunError(`Das Plugin „${pluginName}“ ist abgestürzt oder lieferte keine gültige Antwort.`));
        }
      }));
      child.stdin.on("error", () => undefined);
      child.stdin.end(JSON.stringify(request));
    });
  }
}

/** Übersetzt die rohen Rückgabewerte in getaggte Ausgaben und prüft sie gegen das Manifest. */
export function typedOutputs(definition: PluginPrimitiveDefinition, raw: unknown, pluginName: string): Record<string, NodeOutputValue> {
  if (raw === null || raw === undefined) return {};
  if (typeof raw !== "object" || Array.isArray(raw)) {
    throw new PluginRunError(`Das Plugin „${pluginName}“ muss die Ausgaben als Objekt zurückgeben.`);
  }
  const declared = new Map(definition.outputs.map((output) => [output.name, output]));
  const result: Record<string, NodeOutputValue> = {};
  for (const [name, value] of Object.entries(raw)) {
    const output = declared.get(name);
    if (output === undefined) throw new PluginRunError(`Das Plugin „${pluginName}“ liefert die nicht deklarierte Ausgabe „${name}“.`);
    result[name] = typed(output.type, value, name, pluginName);
  }
  return result;
}

function typed(type: "string" | "number" | "boolean" | "datetime" | "json", value: unknown, name: string, pluginName: string): NodeOutputValue {
  const fail = () => new PluginRunError(`Die Ausgabe „${name}“ von „${pluginName}“ hat nicht den deklarierten Typ ${type}.`);
  switch (type) {
  case "string":
    if (typeof value !== "string") throw fail();
    return {type, value};
  case "datetime":
    if (typeof value !== "string" || Number.isNaN(Date.parse(value))) throw fail();
    return {type, value};
  case "number":
    if (typeof value !== "number" || !Number.isFinite(value)) throw fail();
    return {type, value};
  case "boolean":
    if (typeof value !== "boolean") throw fail();
    return {type, value};
  case "json":
    return {type, value};
  }
}

const maximumEventsPerPoll = 50;
const maximumStateBytes = 100 * 1024;

/** Prüft die Antwort eines Triggers: `{events: [{context?, data?}], state?}`. */
export function triggerResult(raw: unknown, previousState: unknown, pluginName: string): PluginTriggerPollResult {
  if (raw === null || raw === undefined) return {events: [], state: previousState};
  if (typeof raw !== "object" || Array.isArray(raw)) {
    throw new PluginRunError(`Der Trigger von „${pluginName}“ muss ein Objekt mit events und state zurückgeben.`);
  }
  const {events, state} = raw as {events?: unknown; state?: unknown};
  if (events !== undefined && !Array.isArray(events)) {
    throw new PluginRunError(`Der Trigger von „${pluginName}“ muss events als Liste zurückgeben.`);
  }
  if (events !== undefined && events.length > maximumEventsPerPoll) {
    throw new PluginRunError(`Der Trigger von „${pluginName}“ meldet mehr als ${maximumEventsPerPoll} Ereignisse auf einmal.`);
  }
  const nextState = state === undefined ? previousState : state;
  if (JSON.stringify(nextState ?? null).length > maximumStateBytes) {
    throw new PluginRunError(`Der Zustand des Triggers von „${pluginName}“ ist zu groß.`);
  }
  return {events: (events ?? []).map((event) => triggerEvent(event, pluginName)), state: nextState};
}

function triggerEvent(value: unknown, pluginName: string): PluginTriggerEvent {
  if (value === null || typeof value !== "object" || Array.isArray(value)) {
    throw new PluginRunError(`Ein Ereignis von „${pluginName}“ muss ein Objekt sein.`);
  }
  const {context, data} = value as {context?: unknown; data?: unknown};
  if (data !== undefined && (data === null || typeof data !== "object" || Array.isArray(data))) {
    throw new PluginRunError(`Die Daten eines Ereignisses von „${pluginName}“ müssen ein Objekt sein.`);
  }
  return {
    context: typeof context === "string" && context.trim().length > 0 ? context.trim().slice(0, 500) : `Ereignis von ${pluginName}`,
    data: (data ?? {}) as Record<string, unknown>,
  };
}
