"""Führt ein einzelnes Script aus. Läuft als eigener Prozess pro Lauf.

Aufruf: python -I child.py <Laufverzeichnis>. Die Anfrage kommt über stdin, das
Ergebnis steht in <Laufverzeichnis>/result.json. Das Script bekommt volles
Python; die Grenzen setzen der Container und die Limits des Elternprozesses.
"""
import contextlib
import io
import json
import os
import sys
import traceback

RESERVED = {"input", "output", "files", "list_files", "read_file"}
MAX_PRINTED_CHARACTERS = 256 * 1024


def main():
    run_directory = sys.argv[1]
    payload = json.loads(sys.stdin.read())
    result = run(payload)
    with open(os.path.join(run_directory, "result.json"), "w", encoding="utf-8") as handle:
        json.dump(result, handle)


def run(payload):
    attachments = payload.get("files", [])
    namespace = namespace_for(payload, attachments)
    printed = io.StringIO()
    try:
        with contextlib.redirect_stdout(printed):
            exec(compile(payload["script"], "<script>", "exec"), namespace)
        return success(namespace, printed)
    except BaseException as error:  # noqa: BLE001 - jeder Fehler gehört dem Nutzer
        return {"error": describe(error), "printed": clipped(printed)}


def namespace_for(payload, attachments):
    files = [public_file(file) for file in attachments]

    def list_files():
        return files

    def read_file(display_name, encoding="utf-8"):
        with open(path_of(attachments, display_name), "r", encoding=encoding) as handle:
            return handle.read()

    return {
        "__name__": "__script__",
        "input": payload["input"],
        "files": files,
        "list_files": list_files,
        "read_file": read_file,
        **payload["variables"],
    }


def public_file(file):
    return {key: file.get(key) for key in ("displayName", "contentType", "sizeBytes", "versionCreatedAt", "path")}


def path_of(attachments, display_name):
    matching = [file for file in attachments if file.get("displayName") == display_name]
    if len(matching) == 1:
        return matching[0]["path"]
    if len(matching) > 1:
        raise ValueError(f"Mehrere angehängte Dateien heißen: {display_name}")
    raise FileNotFoundError(f"Angehängte Datei nicht gefunden: {display_name}")


def success(namespace, printed):
    output_defined = "output" in namespace
    output = namespace.get("output")
    if output_defined and not isinstance(output, str):
        raise TypeError("Script muss eine String-Variable output setzen.")
    return {
        "outputDefined": output_defined,
        "output": output,
        "printed": clipped(printed),
        "variables": serializable_variables(namespace),
    }


def serializable_variables(namespace):
    variables = {}
    for key, value in namespace.items():
        if key in RESERVED or key.startswith("__"):
            continue
        try:
            json.dumps(value)
        except (TypeError, ValueError):
            continue
        variables[key] = value
    return variables


def clipped(printed):
    text = printed.getvalue()
    if len(text) <= MAX_PRINTED_CHARACTERS:
        return text
    return text[:MAX_PRINTED_CHARACTERS] + "\n[Ausgabe gekürzt]"


def describe(error):
    line = script_line(error)
    where = f"Zeile {line}: " if line else ""
    if isinstance(error, MemoryError):
        return f"{where}Das Script hat zu viel Speicher verbraucht."
    return f"{where}{type(error).__name__}: {error}"


def script_line(error):
    line = None
    for frame in traceback.extract_tb(error.__traceback__):
        if frame.filename == "<script>":
            line = frame.lineno
    if line is None and isinstance(error, SyntaxError) and error.filename == "<script>":
        line = error.lineno
    return line


if __name__ == "__main__":
    main()
