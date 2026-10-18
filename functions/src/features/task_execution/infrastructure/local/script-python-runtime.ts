export const scriptPythonSource = `
import datetime
import json
import sys

payload = json.loads(sys.stdin.read())
inputs = payload["inputs"]
attachment_files = payload.get("files", [])
files = [
    {
        "displayName": file.get("displayName"),
        "contentType": file.get("contentType"),
        "sizeBytes": file.get("sizeBytes"),
        "versionCreatedAt": file.get("versionCreatedAt"),
    }
    for file in attachment_files
]
printed = []
workflow_outputs = []

def _resolve_file(display_name):
    matching_files = [
        file for file in attachment_files
        if file.get("displayName") == display_name
    ]
    if len(matching_files) == 1:
        return matching_files[0]["path"]
    if len(matching_files) > 1:
        raise ValueError(f"Mehrere angehaengte Dateien heissen: {display_name}")
    raise FileNotFoundError(f"Angehaengte Datei nicht gefunden: {display_name}")

def list_files():
    return files

def read_file(display_name, encoding="utf-8"):
    with open(_resolve_file(display_name), "r", encoding=encoding) as file:
        return file.read()

def workflow_input(name):
    if name not in inputs:
        raise LookupError(f'workflow_input("{name}"): Es gibt keinen Wert "{name}".')
    entry = inputs[name]
    if entry["type"] == "datetime":
        return datetime.datetime.fromisoformat(entry["value"])
    return entry["value"]

def workflow_output(name, type, value):
    # Geprueft wird im Executor (script-workflow-outputs.ts); hier nur JSON-faehig machen.
    if isinstance(value, (datetime.datetime, datetime.date)):
        value = value.isoformat()
    workflow_outputs.append({"name": name, "type": type, "value": value})

def safe_print(*values, sep=" ", end="\\n"):
    printed.append(sep.join(str(value) for value in values) + end)

safe_builtins = {
    "bool": bool,
    "dict": dict,
    "enumerate": enumerate,
    "float": float,
    "int": int,
    "len": len,
    "list": list,
    "max": max,
    "min": min,
    "print": safe_print,
    "range": range,
    "round": round,
    "set": set,
    "sorted": sorted,
    "str": str,
    "sum": sum,
    "tuple": tuple,
}

namespace = {
    "files": files,
    "list_files": list_files,
    "read_file": read_file,
    "workflow_input": workflow_input,
    "workflow_output": workflow_output,
}
exec(payload["script"], {"__builtins__": safe_builtins}, namespace)

sys.stdout.write(json.dumps({
    "printed": "".join(printed),
    "workflowOutputs": workflow_outputs,
}))
`;
