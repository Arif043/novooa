export const scriptPythonSource = `
import json
import sys

payload = json.loads(sys.stdin.read())
input = payload["input"]
variables = payload["variables"]
files_dir = payload.get("filesDir")
attachment_files = payload.get("files", [])
files = [
    {
        "id": file.get("id"),
        "filename": file.get("filename"),
        "displayName": file.get("displayName"),
        "contentType": file.get("contentType"),
        "sizeBytes": file.get("sizeBytes"),
    }
    for file in attachment_files
]
printed = []

def _resolve_file(name):
    for file in attachment_files:
        if name in [file.get("filename"), file.get("displayName"), file.get("id")]:
            return file["path"]
    raise FileNotFoundError(f"Angehaengte Datei nicht gefunden: {name}")

def list_files():
    return files

def read_file(name, encoding="utf-8"):
    with open(_resolve_file(name), "r", encoding=encoding) as file:
        return file.read()

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
    "input": input,
    "files": files,
    "files_dir": files_dir,
    "list_files": list_files,
    "read_file": read_file,
    **variables,
}
exec(payload["script"], {"__builtins__": safe_builtins}, namespace)
output = namespace.get("output")

if output is None:
    output = "".join(printed)

if not isinstance(output, str):
    raise TypeError("Script muss eine String-Variable output setzen oder Text printen.")

next_variables = {}
for key, value in namespace.items():
    if key in ["input", "output", "files", "files_dir", "list_files", "read_file"]:
        continue
    if key.startswith("__"):
        continue
    try:
        json.dumps(value)
        next_variables[key] = value
    except TypeError:
        pass

sys.stdout.write(json.dumps({
    "output": output,
    "printed": "".join(printed),
    "variables": next_variables,
}))
`;
