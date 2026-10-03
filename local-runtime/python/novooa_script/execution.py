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
MAX_RESULT_BYTES = 2 * 1024 * 1024
MAX_PRINTED_BYTES = 256 * 1024
MAX_SCRIPT_PROCESSES = int(os.environ.get("SCRIPT_MAX_PROCESSES", "64"))
WORK_ROOT = os.environ.get("SCRIPT_WORK_DIRECTORY", tempfile.gettempdir())


class ScriptFailed(Exception):
    """Das Script ist gescheitert; die Meldung ist für den Nutzer bestimmt."""

    def __init__(self, message, printed=""):
        super().__init__(message)
        self.printed = printed


def execute(request, file_bytes):
    """Führt ein Script in einem frischen Prozess aus und liefert das Ergebnis."""
    run_directory = tempfile.mkdtemp(prefix="run-", dir=WORK_ROOT)
    try:
        payload = payload_for(request, file_bytes, run_directory)
        try:
            result = result_of(run_child(payload, run_directory))
        except ScriptFailed as failure:
            # Was das Script bis zum Fehler ausgegeben hat, ist gerade dann wertvoll.
            failure.printed = printed_of(run_directory)
            raise
        return {**result, "printed": printed_of(run_directory)}
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
    resource.setrlimit(resource.RLIMIT_CPU, (int(TIMEOUT_SECONDS) + 2, int(TIMEOUT_SECONDS) + 2))
    resource.setrlimit(resource.RLIMIT_FSIZE, (64 * 1024 * 1024, 64 * 1024 * 1024))
    resource.setrlimit(resource.RLIMIT_NOFILE, (128, 128))
    # Zählt alle Prozesse des Benutzers im Container, auch die Threads des Servers: Ein Script
    # kann die Plätze von pids_limit nie ganz belegen, dem Server bleibt Platz für neue Anfragen.
    # Die Zahl ist auf den Speicher des Containers abgestimmt (siehe docker-compose.local.yaml).
    resource.setrlimit(resource.RLIMIT_NPROC, (MAX_SCRIPT_PROCESSES, MAX_SCRIPT_PROCESSES))
    resource.setrlimit(resource.RLIMIT_CORE, (0, 0))
    prefer_script_in_oom()


def prefer_script_in_oom():
    """Geht dem Container der Speicher aus, soll der Kernel zuerst das Script beenden, nie den Server."""
    try:
        with open("/proc/self/oom_score_adj", "w") as handle:
            handle.write("1000")
    except OSError:
        pass


def run_child(payload, run_directory):
    # Fehlerausgabe in eine Datei statt in eine Pipe: Prozesse, die das Script startet,
    # erben sonst die Pipe, und der Lauf hinge, bis auch sie enden.
    stderr_path = os.path.join(run_directory, "stderr.txt")
    with open(stderr_path, "wb") as stderr_file, open(stdout_path(run_directory), "wb") as stdout_file:
        process = subprocess.Popen(
            # -u: stdout ohne Puffer, damit auch bei Timeout oder Kill alles Bisherige erhalten bleibt.
            [sys.executable, "-u", "-I", CHILD, run_directory],
            stdin=subprocess.PIPE, stdout=stdout_file, stderr=stderr_file,
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


def stdout_path(run_directory):
    return os.path.join(run_directory, "stdout.txt")


def printed_of(run_directory):
    """Die komplette stdout des Laufs; bei sehr viel Ausgabe die ersten Bytes samt Hinweis."""
    try:
        with open(stdout_path(run_directory), "rb") as handle:
            data = handle.read(MAX_PRINTED_BYTES + 1)
    except OSError:
        return ""
    clipped = len(data) > MAX_PRINTED_BYTES
    text = data[:MAX_PRINTED_BYTES].decode("utf-8", "replace")
    return text + ("\n[Ausgabe gekürzt]" if clipped else "")


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
    try:
        with open(path, "r", encoding="utf-8") as handle:
            result = json.load(handle)
    except ValueError:
        raise ScriptFailed("Das Ergebnis des Scripts ist ungültig.")
    if "error" in result:
        raise ScriptFailed(result["error"])
    return result
