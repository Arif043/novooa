import json
import os
import re
import resource
import shutil
import signal
import subprocess
import sys
import tempfile
from pathlib import Path

CHILD = str(Path(__file__).with_name("child.py"))
TIMEOUT_SECONDS = float(os.environ.get("SCRIPT_TIMEOUT_SECONDS", "10"))
MEMORY_LIMIT_BYTES = int(os.environ.get("SCRIPT_MEMORY_LIMIT_MB", "512")) * 1024 * 1024
MAX_RESULT_BYTES = 2 * 1024 * 1024
MAX_SCRIPT_PROCESSES = 32
WORK_ROOT = os.environ.get("SCRIPT_WORK_DIRECTORY", tempfile.gettempdir())


class ScriptFailed(Exception):
    """Das Script ist gescheitert; die Meldung ist für den Nutzer bestimmt."""


def execute(request, file_bytes):
    """Führt ein Script in einem frischen Prozess aus und liefert das Ergebnis."""
    run_directory = tempfile.mkdtemp(prefix="run-", dir=WORK_ROOT)
    try:
        payload = payload_for(request, file_bytes, run_directory)
        return result_of(run_child(payload, run_directory))
    finally:
        shutil.rmtree(run_directory, ignore_errors=True)


def payload_for(request, file_bytes, run_directory):
    files = []
    for index, metadata in enumerate(request.get("files", [])):
        path = os.path.join(run_directory, f"{index}-{safe_name(metadata.get('displayName'))}")
        with open(path, "wb") as handle:
            handle.write(file_bytes[index])
        files.append({**metadata, "path": path})
    return {
        "script": request["script"],
        "input": request["input"],
        "variables": request["variables"],
        "files": files,
    }


def safe_name(display_name):
    cleaned = re.sub(r"[^A-Za-z0-9._-]", "_", str(display_name or "datei"))
    return cleaned[:80] or "datei"


def limit_child():
    os.setsid()
    resource.setrlimit(resource.RLIMIT_AS, (MEMORY_LIMIT_BYTES, MEMORY_LIMIT_BYTES))
    resource.setrlimit(resource.RLIMIT_CPU, (int(TIMEOUT_SECONDS) + 2, int(TIMEOUT_SECONDS) + 2))
    resource.setrlimit(resource.RLIMIT_FSIZE, (64 * 1024 * 1024, 64 * 1024 * 1024))
    resource.setrlimit(resource.RLIMIT_NOFILE, (128, 128))
    # Zählt alle Prozesse des Benutzers im Container, auch die Threads des Servers: Ein Script
    # kann die 64 Plätze von pids_limit nie ganz belegen, dem Server bleibt Platz für neue Anfragen.
    resource.setrlimit(resource.RLIMIT_NPROC, (MAX_SCRIPT_PROCESSES, MAX_SCRIPT_PROCESSES))
    resource.setrlimit(resource.RLIMIT_CORE, (0, 0))


def run_child(payload, run_directory):
    # Fehlerausgabe in eine Datei statt in eine Pipe: Prozesse, die das Script startet,
    # erben sonst die Pipe, und der Lauf hinge, bis auch sie enden.
    stderr_path = os.path.join(run_directory, "stderr.txt")
    with open(stderr_path, "wb") as stderr_file:
        process = subprocess.Popen(
            [sys.executable, "-I", CHILD, run_directory],
            stdin=subprocess.PIPE, stdout=subprocess.DEVNULL, stderr=stderr_file,
            cwd=run_directory, env={"PATH": os.environ.get("PATH", ""), "PYTHONIOENCODING": "utf-8"},
            preexec_fn=limit_child,
        )
        wait_for(process, payload)
    if process.returncode != 0:
        raise ScriptFailed(failure_message(process.returncode, stderr_path))
    return run_directory


def wait_for(process, payload):
    try:
        process.communicate(json.dumps(payload).encode("utf-8"), timeout=TIMEOUT_SECONDS)
    except subprocess.TimeoutExpired:
        kill_group(process)
        process.communicate()
        raise ScriptFailed(f"Das Script wurde nach {TIMEOUT_SECONDS:g} Sekunden abgebrochen.")
    finally:
        # Auch nach einem normalen Ende: Was das Script gestartet hat (fork, subprocess),
        # darf den Lauf nicht überleben und keine Prozessplätze des Containers belegen.
        kill_group(process)


def kill_group(process):
    try:
        os.killpg(process.pid, signal.SIGKILL)
    except ProcessLookupError:
        pass


def failure_message(returncode, stderr_path):
    if returncode < 0:
        return f"Das Script wurde beendet (Signal {-returncode}), etwa wegen zu hohem Speicher- oder Zeitverbrauch."
    with open(stderr_path, "rb") as handle:
        text = handle.read()[-500:].decode("utf-8", "replace").strip()
    return text or "Das Script ist fehlgeschlagen."


def result_of(run_directory):
    path = os.path.join(run_directory, "result.json")
    if not os.path.exists(path) or os.path.getsize(path) > MAX_RESULT_BYTES:
        raise ScriptFailed("Das Ergebnis des Scripts ist zu groß oder fehlt.")
    with open(path, "r", encoding="utf-8") as handle:
        result = json.load(handle)
    if "error" in result:
        raise ScriptFailed(result["error"])
    return result
