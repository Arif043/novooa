#!/usr/bin/env python3
"""Härtet die Python-Dienste gegen Reverse-Engineering.

Jedes Paketmodul wird mit Nuitka (``--module``) zu einer nativen ``.so``
kompiliert und die ``.py``-Quelle entfernt. Nur die Abhängigkeiten
(numpy/onnxruntime/…) bleiben als normale pip-Pakete — unser Code ist das
Schützenswerte. Übrig bleiben ausschließlich winzige, IP-freie Launcher:

* ``<paket>/__main__.py`` für den ``python -m <paket>``-Start (die eigentliche
  Server-Logik liegt kompiliert in ``server.so`` bzw. ``inference_server.so``).
* Pro von Node über einen Pfad gestartetem Worker ein Launcher, der die
  kompilierte Implementierung unter ``_native/`` aufruft.

Grund für die Launcher: ``python -m modul`` bzw. ``python datei.py`` braucht ein
Code-Objekt; eine Nuitka-``.so`` liefert keines ("No code object available").
Importieren einer ``.so`` funktioniert dagegen problemlos.

Aufruf:  python3 harden_python.py <python-root>

Verschleierung erhöht die Kosten des Reverse-Engineering, macht es aber nicht
unmöglich — nativer Maschinencode ist deutlich schwerer als Bytecode, aber
analysierbar. Der eigentliche Diebstahlschutz bleibt das Lizenzsystem.
"""

from __future__ import annotations

import py_compile
import subprocess
import sys
from pathlib import Path

# Pakete, deren Submodule komplett kompiliert werden.
PACKAGES = ["novooa_ml", "novooa_script"]

# Module, die NICHT zu .so kompiliert, sondern als sourceless .pyc geschützt
# werden: Sie werden als eigener Prozess per Pfad gestartet (python -I <pfad>)
# und sind bewusst eigenständig — eine .so wäre per Pfad nicht ausführbar
# ("No code object available"), .pyc dagegen schon.
PYC_ONLY = {"child.py"}

# __main__.py-Launcher je Paket (ersetzt `python -m <paket>.<modul>`):
# Paket -> kompilierter Modulpfad, dessen main() aufgerufen wird.
ENTRYPOINTS = {
    "novooa_script": "novooa_script.server",
    "novooa_ml": "novooa_ml.inference_server",
}

# Top-level Worker, die Node per Dateipfad mit `python3 <pfad>` startet.
# Ihre Logik wandert kompiliert nach _native/, der Pfad bleibt ein Launcher.
WORKERS = [
    "input_transform_worker.py",
    "onnx_worker.py",
    "onnx_validation_worker.py",
]

LAUNCHER_MAIN_TEMPLATE = '''from {module} import main

if __name__ == "__main__":
    main()
'''

# Launcher für die Worker: identischer Fehlerpfad wie die Originale
# (Meldung nach stderr, Exit-Code 1). Node startet die Worker mit `python -I`,
# das PYTHONPATH ignoriert und das Skriptverzeichnis nicht auf sys.path legt —
# der Launcher ergänzt es daher selbst, damit _native/ und die Pakete gefunden
# werden.
WORKER_LAUNCHER_TEMPLATE = '''import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from _native.{module} import main

if __name__ == "__main__":
    try:
        main()
    except Exception as error:  # noqa: BLE001 - Fehler als Text an den Aufrufer
        sys.stderr.write({error_prefix} + str(error))
        sys.exit(1)
'''

# onnx_validation_worker stellt der Fehlermeldung einen festen Text voran.
WORKER_ERROR_PREFIX = {
    "onnx_validation_worker": '"Die ONNX-Modellprüfung ist fehlgeschlagen: "',
}


def compile_module(source: Path, output_dir: Path) -> Path:
    """Kompiliert eine .py zu .so und gibt den Pfad der .so zurück."""
    build_dir = output_dir / f"{source.stem}.nuitka"
    subprocess.run(
        [
            sys.executable,
            "-m",
            "nuitka",
            "--module",
            str(source),
            f"--output-dir={build_dir}",
            "--quiet",
            "--no-progressbar",
            "--remove-output",
        ],
        check=True,
    )
    produced = sorted(build_dir.glob(f"{source.stem}*.so"))
    if not produced:
        raise RuntimeError(f"Nuitka erzeugte keine .so für {source}")
    return produced[0]


def harden_package(root: Path, package: str) -> None:
    pkg_dir = root / package
    if not pkg_dir.is_dir():
        raise RuntimeError(f"Paketverzeichnis fehlt: {pkg_dir}")
    build_dir = root / ".nuitka-build"
    build_dir.mkdir(exist_ok=True)

    for source in sorted(pkg_dir.rglob("*.py")):
        if source.name in ("__init__.py", "__main__.py"):
            continue  # Launcher/Marker bleiben lesbar (kein IP).
        if source.name in PYC_ONLY:
            pyc = source.with_suffix(".pyc")
            py_compile.compile(str(source), cfile=str(pyc), doraise=True)
            source.unlink()
            print(f"  bytecode:   {source.relative_to(root)} -> {pyc.name}")
            continue
        so = compile_module(source, build_dir)
        target = source.with_name(so.name)
        target.write_bytes(so.read_bytes())
        source.unlink()
        print(f"  kompiliert: {source.relative_to(root)} -> {target.name}")

    entry = ENTRYPOINTS.get(package)
    if entry:
        (pkg_dir / "__main__.py").write_text(
            LAUNCHER_MAIN_TEMPLATE.format(module=entry),
            encoding="utf-8",
        )
        print(f"  Launcher: {package}/__main__.py (python -m {package})")


def harden_workers(root: Path) -> None:
    native = root / "_native"
    native.mkdir(exist_ok=True)
    (native / "__init__.py").write_text("", encoding="utf-8")
    build_dir = root / ".nuitka-build"
    build_dir.mkdir(exist_ok=True)

    for worker in WORKERS:
        source = root / worker
        if not source.is_file():
            print(f"  übersprungen (fehlt): {worker}")
            continue
        stem = source.stem
        # Implementierung nach _native/ verschieben und kompilieren.
        impl = native / worker
        impl.write_text(source.read_text(encoding="utf-8"), encoding="utf-8")
        so = compile_module(impl, build_dir)
        (native / so.name).write_bytes(so.read_bytes())
        impl.unlink()
        # Launcher am ursprünglichen Pfad (Node startet diesen Pfad weiter).
        prefix = WORKER_ERROR_PREFIX.get(stem, '""')
        source.write_text(
            WORKER_LAUNCHER_TEMPLATE.format(module=stem, error_prefix=prefix),
            encoding="utf-8",
        )
        print(f"  Worker: {worker} -> _native/{so.name} (+ Launcher)")


def cleanup(root: Path) -> None:
    build_dir = root / ".nuitka-build"
    if build_dir.exists():
        for child in sorted(build_dir.rglob("*"), reverse=True):
            child.unlink() if child.is_file() else child.rmdir()
        build_dir.rmdir()


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__)
        return 2
    root = Path(sys.argv[1]).resolve()
    print(f"Härte Python unter {root}")
    for package in PACKAGES:
        if (root / package).is_dir():
            print(f"Paket {package}:")
            harden_package(root, package)
    if any((root / w).is_file() for w in WORKERS):
        print("Worker:")
        harden_workers(root)
    cleanup(root)
    print("Python-Härtung abgeschlossen.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
