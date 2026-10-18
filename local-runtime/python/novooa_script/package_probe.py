"""Prüft nach der Installation, ob sich die Pakete einer Umgebung im Script-Container laden lassen.

Der Paketdienst entpackt nur Wheels und führt keinen Code aus. Ob ein Paket hier läuft (etwa weil
eine Bibliothek des Betriebssystems fehlt oder der Import zu lange dauert), zeigt erst ein Import
unter denselben Grenzen wie ein Script.
"""
import json
import os
import re

from novooa_script.execution import PackagesMissing, ScriptFailed, TimedOut, execute, site_directory_for

_NAME = re.compile(r"^[A-Za-z0-9](?:[A-Za-z0-9._-]*[A-Za-z0-9])?")
_SKIPPED_SUFFIXES = (".dist-info", ".data", ".libs")
_MODULE_SUFFIXES = (".py", ".so", ".pyd")


def probe(request):
    """`{"loadable": True}` oder `{"loadable": False, "module": …, "error": …}`; wirft `PackagesMissing`."""
    environment = request.get("environment")
    site = site_directory_for(environment)
    if site is None:
        raise PackagesMissing()
    modules = modules_of(site, request.get("packages", []))
    if not modules:
        return {"loadable": True}
    try:
        result = execute({"script": probe_script(modules), "inputs": {}, "files": [], "environment": environment}, [])
    except TimedOut as failure:
        return {"loadable": False, "module": None, "error": f"Der Import dauerte länger als {failure.seconds:g} Sekunden."}
    except ScriptFailed as failure:
        return {"loadable": False, "module": None, "error": str(failure)}
    return verdict_of(result)


def probe_script(modules):
    # BaseException: Auch ein `sys.exit` oder `MemoryError` beim Import macht das Paket unbrauchbar.
    return (
        f"import importlib\n"
        f"for module in {json.dumps(modules)}:\n"
        f"    try:\n"
        f"        importlib.import_module(module)\n"
        f"    except BaseException as error:\n"
        f"        workflow_output('module', 'string', module)\n"
        f"        workflow_output('error', 'string', f'{{type(error).__name__}}: {{error}}')\n"
        f"        break\n"
    )


def verdict_of(result):
    values = {output["name"]: output["value"] for output in result.get("workflowOutputs", [])}
    if "module" not in values:
        return {"loadable": True}
    return {"loadable": False, "module": values["module"], "error": values.get("error", "")}


def modules_of(site, packages):
    """Die obersten importierbaren Module der angeforderten Distributionen, sortiert."""
    wanted = {normalized_name(match.group(0)) for match in map(_NAME.match, packages) if match}
    modules = set()
    for entry in sorted(os.listdir(site)):
        if entry.endswith(".dist-info") and distribution_of(entry) in wanted:
            modules.update(top_level_modules(os.path.join(site, entry, "RECORD")))
    return sorted(modules)


def distribution_of(dist_info):
    """`Opencv_Python-4.10.dist-info` → `opencv-python`."""
    return normalized_name(dist_info.removesuffix(".dist-info").rsplit("-", 1)[0])


def top_level_modules(record_path):
    try:
        with open(record_path, encoding="utf-8") as handle:
            paths = [line.split(",", 1)[0] for line in handle if line.strip()]
    except OSError:
        return set()
    return {module for module in map(module_of, paths) if module}


def module_of(path):
    """Der Modulname des obersten Pfadteils; `None` für Metadaten, Bibliotheken und private Module."""
    top, *rest = path.replace("\\", "/").split("/", 1)
    if rest:
        name = None if top.endswith(_SKIPPED_SUFFIXES) or top in ("..", "bin", "__pycache__") else top
    else:
        name = top.split(".", 1)[0] if top.endswith(_MODULE_SUFFIXES) else None
    # Private Module (`_yaml`) lädt das öffentliche Paket ohnehin selbst.
    return name if name and name.isidentifier() and not name.startswith("_") else None


def normalized_name(name):
    return re.sub(r"[-_.]+", "-", name).lower()
