#!/usr/bin/env python3
"""Kompiliert eine Kopie der novooa-Python-Pakete; entfernt dort die Quellen.

Aufruf: python harden_python.py <kopie-des-python-baums>
Nuitka und ein C-Compiler müssen im Build-System installiert sein.
"""

import py_compile
import shutil
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

ENTRYPOINTS = {
    "novooa_script": "novooa_script.server",
    "novooa_ml": "novooa_ml.inference_server",
    "novooa_packages": "novooa_packages.server",
}


def compile_module(source, build_directory):
    destination = build_directory / source.relative_to(build_directory.parent).with_suffix("")
    subprocess.run([
        sys.executable, "-m", "nuitka", "--module", str(source),
        f"--output-dir={destination}", "--jobs=1", "--quiet", "--no-progressbar", "--remove-output",
    ], check=True)
    modules = list(destination.glob(f"{source.stem}*.so"))
    if len(modules) != 1:
        raise RuntimeError(f"Keine eindeutige native Erweiterung für {source}")
    shutil.copy2(modules[0], source.with_name(modules[0].name))
    source.unlink()
    shutil.rmtree(destination)
    print(f"kompiliert: {source.relative_to(build_directory.parent)}", flush=True)


def harden_source(source, build_directory):
    # child läuft mit python -I per Dateipfad; eine Erweiterung ist so nicht startbar.
    if source.name == "child.py":
        py_compile.compile(str(source), cfile=str(source.with_suffix(".pyc")), doraise=True)
        source.unlink()
    elif source.name not in ("__init__.py", "__main__.py"):
        compile_module(source, build_directory)


def harden_package(package, build_directory):
    with ThreadPoolExecutor(max_workers=4) as compilers:
        list(compilers.map(lambda source: harden_source(source, build_directory), sorted(package.rglob("*.py"))))
    entrypoint = ENTRYPOINTS.get(package.name)
    if entrypoint:
        (package / "__main__.py").write_text(
            f'from {entrypoint} import main\n\nif __name__ == "__main__":\n    main()\n',
            encoding="utf-8",
        )
    for cache in package.rglob("__pycache__"):
        shutil.rmtree(cache)


def main(arguments):
    if len(arguments) != 1:
        raise SystemExit(__doc__)
    root = Path(arguments[0]).resolve()
    packages = sorted(path for path in root.glob("novooa_*") if path.is_dir())
    if not packages:
        raise RuntimeError(f"Keine novooa-Pakete unter {root}")
    build_directory = root / ".nuitka-build"
    build_directory.mkdir()
    for package in packages:
        harden_package(package, build_directory)
        print(f"gehärtet: {package.name}", flush=True)
    shutil.rmtree(build_directory)


if __name__ == "__main__":
    main(sys.argv[1:])
