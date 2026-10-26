import {NodeFailure} from "./node-failure.js";
import {type ConsoleOutput} from "./task.js";

/**
 * Der Katalog der Geschäftsfehler von Bausteinen. Jeder Code hat feste
 * Felder; der Client übersetzt Code und Felder (siehe
 * `docs/notes/baustein-fehlercodes.md`).
 */
export type MissingSetting = "model" | "modelInputMapping" | "inputFile" | "outputFile" | "audioInput" |
  "recipient" | "messageBody" | "notificationText" | "mailbox" | "teamMembers" | "resultFields";
export type InvalidSetting = "modelInputDuplicate" | "modelParameter" | "documentFilterValue" |
  "documentFieldValue" | "documentFieldDuplicate" | "jsonPointer";
export type ValueTarget = "modelInput" | "documentFilter" | "forEachItems";
export type ExpectedValue = "image" | "audio" | "file" | "number" | "boolean" | "json" | "textList" |
  "numberList" | "list" | "tensor";
export type RunTrigger = "email" | "whatsapp" | "sms" | "telegram" | "instagram" | "webhook";
export type Capability = "speechSynthesis" | "speechTranscription" | "httpRequests" | "float16Tensors";
export type ScriptOutputProblem = "duplicateName" | "invalidEntry" | "invalidName" | "unknownType" | "wrongValueType";
/** `notInstalled`: Die Pakete wurden noch nicht installiert; `unsupported`: Die Umgebung kennt keine Pakete (Cloud). */
export type ScriptPackagesProblem = "notInstalled" | "unsupported";

export const nodeFailures = {
  configurationMissing: (primitive: string) => coded("configurationMissing", {primitive}),
  settingMissing: (setting: MissingSetting) => coded("settingMissing", {setting}),
  settingInvalid: (setting: InvalidSetting, name?: string) => coded("settingInvalid", withName({setting}, name)),
  valueTypeMismatch: (target: ValueTarget, expected: ExpectedValue, name?: string) =>
    coded("valueTypeMismatch", withName({target, expected}, name)),
  tensorShapeMismatch: (name: string) => coded("tensorShapeMismatch", {name}),
  modelOutputInvalid: (output: "image" | "audio") => coded("modelOutputInvalid", {output}),
  triggerMismatch: (trigger: RunTrigger) => coded("triggerMismatch", {trigger}),
  capabilityUnavailable: (capability: Capability) => coded("capabilityUnavailable", {capability}),
  httpBodyInvalidJson: () => coded("httpBodyInvalidJson", {}),
  httpStatusFailed: (status: number, excerpt: string) => coded("httpStatusFailed", {status: String(status), excerpt}),
  forEachUnsupported: (reason: "nestedForEach" | "pausingBlock") => coded("forEachUnsupported", {reason}),
  scriptOutputInvalid: (reason: ScriptOutputProblem, name?: string, type?: string) =>
    coded("scriptOutputInvalid", withName(type === undefined ? {reason} : {reason, type}, name)),
  /** Der Baustein gehört zu einem Plugin, das im Arbeitsbereich nicht aktiviert ist. */
  pluginDisabled: (plugin: string) => coded("pluginDisabled", {plugin}),
  scriptPackagesUnavailable: (reason: ScriptPackagesProblem, packages: readonly string[]) =>
    coded("scriptPackagesUnavailable", {reason, packages: packages.join(", ")}),
  /** Die Meldung des Scripts selbst (z. B. die Python-Ausnahme) ist der technische Text. */
  scriptFailed: (message: string, console: ConsoleOutput) => NodeFailure.of({code: "scriptFailed", message, console}),
  /** Ein unerwarteter Fehler ohne fachlichen Code, z. B. aus der Infrastruktur eines inneren Plans. */
  unexpected: (message: string, console?: ConsoleOutput) => NodeFailure.of({code: "unexpected", message, console}),
};

function coded(code: string, details: Record<string, string>): NodeFailure {
  const fields = Object.entries(details).map(([name, value]) => `${name}=${JSON.stringify(value)}`);
  const message = fields.length === 0 ? code : `${code}: ${fields.join(" ")}`;
  return NodeFailure.of({code, message, details});
}

function withName(details: Record<string, string>, name?: string): Record<string, string> {
  return name === undefined ? details : {...details, name};
}
