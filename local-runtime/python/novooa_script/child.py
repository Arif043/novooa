"""Führt ein einzelnes Script aus. Läuft als eigener Prozess pro Lauf.

Aufruf: python -u -I child.py <Laufverzeichnis>. Die Anfrage kommt über stdin, das
Ergebnis steht in <Laufverzeichnis>/result.json. Alles, was das Script auf stdout
schreibt (print, Unterprozesse, Low-Level-Schreibzugriffe), landet in der Datei, die der
Server als stdout übergibt; er liest sie nach dem Lauf. Das Script bekommt volles
Python; die Grenzen setzen der Container und die Limits des Elternprozesses.
"""
import json
import os
import sys
import traceback

# Mit -I steht das eigene Verzeichnis nicht im Importpfad. Nur für diesen Import aufnehmen,
# damit der Importpfad, den das Script sieht, unverändert bleibt.
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from workflow_inputs import WorkflowInputs  # noqa: E402
from workflow_outputs import WorkflowOutputs  # noqa: E402
sys.path.pop(0)


def main():
    owner = os.getpid()
    run_directory = sys.argv[1]
    payload = json.loads(sys.stdin.read())
    result = run(payload)
    if os.getpid() != owner:
        # Eine Kopie, die das Script per fork erzeugt hat: Das Ergebnis gehört allein dem Ursprungsprozess.
        os._exit(0)
    with open(os.path.join(run_directory, "result.json"), "w", encoding="utf-8") as handle:
        json.dump(result, handle)


def run(payload):
    if payload.get("site"):
        # Vor allem anderen, damit ein Paket der Umgebung ein gleichnamiges Modul verdeckt.
        sys.path.insert(0, payload["site"])
    attachments = payload.get("files", [])
    outputs = WorkflowOutputs()
    namespace = namespace_for(payload, attachments, outputs)
    try:
        exec(compile(payload["script"], "<script>", "exec"), namespace)
        return success(outputs)
    except BaseException as error:  # noqa: BLE001 - jeder Fehler gehört dem Nutzer
        return {"error": describe(error)}


def namespace_for(payload, attachments, outputs):
    files = [public_file(file) for file in attachments]

    def list_files():
        return files

    def read_file(display_name, encoding="utf-8"):
        with open(path_of(attachments, display_name), "r", encoding=encoding) as handle:
            return handle.read()

    return {
        # Wie beim Start einer Datei: Scripts mit `if __name__ == "__main__":` sollen diesen Block ausführen.
        "__name__": "__main__",
        "files": files,
        "list_files": list_files,
        "read_file": read_file,
        "workflow_input": WorkflowInputs(payload["inputs"]).read,
        "workflow_output": outputs.define,
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


def success(outputs):
    return {"workflowOutputs": outputs.as_list()}


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
