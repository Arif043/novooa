"""Baut Paketumgebungen für Script-Bausteine mit uv.

Eine Umgebung liegt unter `envs/<id>/` mit `site/` (die Pakete, kommt in den
Suchpfad des Scripts), `lock.txt` (festgelegte Versionen mit Prüfsummen) und
`novooa-environment.json`. Sie entsteht in `.building/` und erscheint erst
vollständig, per atomarem Umbenennen. Nur fertige Pakete (Wheels): Beim
Installieren läuft kein Code der Pakete.
"""
import json
import os
import shutil
import subprocess
import sys
import uuid
from pathlib import Path
from threading import Lock

ENVIRONMENTS = "envs"
BUILDING = ".building"
METADATA = "novooa-environment.json"
INSTALL_TIMEOUT_SECONDS = 15 * 60


class InstallFailed(Exception):
    """`reason`: notFound, noWheel, tooLarge oder failed; `detail`: Auszug aus der Ausgabe von uv."""

    def __init__(self, reason, detail=""):
        super().__init__(reason)
        self.reason = reason
        self.detail = detail


class EnvironmentInstaller:
    def __init__(self, root, maximum_bytes, run=subprocess.run):
        self._root = Path(root)
        self._maximum_bytes = maximum_bytes
        self._run = run
        # Eine Installation zur Zeit: uv lädt ohnehin parallel, und der Cache bleibt konsistent.
        self._lock = Lock()

    def list(self):
        environments = []
        for metadata in sorted((self._root / ENVIRONMENTS).glob(f"*/{METADATA}")):
            environments.append(json.loads(metadata.read_text(encoding="utf-8")))
        return environments

    def install(self, environment_id, packages):
        with self._lock:
            existing = self._environment(environment_id)
            if existing.is_dir():
                return self._metadata(existing)
            building = self._root / BUILDING / f"{environment_id}-{uuid.uuid4().hex}"
            try:
                return self._build(environment_id, packages, building)
            finally:
                shutil.rmtree(building, ignore_errors=True)

    def delete(self, environment_id):
        with self._lock:
            shutil.rmtree(self._environment(environment_id), ignore_errors=True)

    def _build(self, environment_id, packages, building):
        building.mkdir(parents=True)
        (building / "requirements.in").write_text("\n".join(packages) + "\n", encoding="utf-8")
        self._uv(["pip", "compile", "requirements.in", "-o", "lock.txt", "--generate-hashes",
                  "--only-binary", ":all:", "--no-header", "--quiet"], building)
        self._uv(["pip", "install", "--target", "site", "--require-hashes", "--no-deps",
                  "--only-binary", ":all:", "--link-mode", "hardlink", "-r", "lock.txt"], building)
        size = directory_bytes(building / "site")
        if size > self._maximum_bytes:
            raise InstallFailed("tooLarge", f"{size} Bytes")
        metadata = {"id": environment_id, "packages": packages, "sizeBytes": size}
        (building / METADATA).write_text(json.dumps(metadata), encoding="utf-8")
        self._environment(environment_id).parent.mkdir(parents=True, exist_ok=True)
        os.replace(building, self._environment(environment_id))
        return metadata

    def _uv(self, arguments, directory):
        completed = self._run(
            ["uv", *arguments, "--python", sys.executable],
            cwd=directory, env=self._uv_environment(), capture_output=True, text=True,
            timeout=INSTALL_TIMEOUT_SECONDS,
        )
        if completed.returncode != 0:
            raise InstallFailed(reason_of(completed.stderr), tail(completed.stderr))

    def _uv_environment(self):
        # Der Cache liegt im selben Volume wie die Umgebungen, damit uv Hardlinks setzen kann.
        return {
            "PATH": os.environ.get("PATH", ""),
            "UV_CACHE_DIR": str(self._root / ".cache"),
            "UV_NO_CONFIG": "1",
            "UV_PYTHON_DOWNLOADS": "never",
            "HOME": str(self._root / ".home"),
        }

    def _environment(self, environment_id):
        return self._root / ENVIRONMENTS / environment_id

    @staticmethod
    def _metadata(directory):
        return json.loads((directory / METADATA).read_text(encoding="utf-8"))


def reason_of(output):
    text = output.lower()
    if "only-binary" in text or "no wheels" in text or "has no wheels" in text or "no binary" in text:
        return "noWheel"
    if "not found in the package registry" in text or ("no solution found" in text and "was not found" in text):
        return "notFound"
    return "failed"


def tail(output, lines=8):
    return "\n".join(output.strip().splitlines()[-lines:])


def directory_bytes(directory):
    return sum(path.stat().st_size for path in Path(directory).rglob("*") if path.is_file())
