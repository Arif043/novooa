import {type TaskVariables} from "./node-executor.js";

const variablePattern = /\{\{\s*([a-zA-Z_][\w]*(?:\.[a-zA-Z_][\w]*|\.\d+)*)\s*\}\}/g;

export function resolveVariableTemplates(
  text: string,
  variables: TaskVariables,
): string {
  return text.replace(variablePattern, (match, path: string) => {
    const value = valueAtPath(variables, path.split("."));
    if (value === undefined) return match;
    return formatVariable(value);
  });
}

function valueAtPath(value: unknown, path: string[]): unknown {
  return path.reduce<unknown>((current, segment) => {
    if (current === undefined || current === null) return undefined;
    if (Array.isArray(current)) return current[Number(segment)];
    if (!isRecord(current)) return undefined;
    return current[segment];
  }, value);
}

function formatVariable(value: unknown): string {
  if (typeof value === "string") return value;
  return JSON.stringify(value);
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}
