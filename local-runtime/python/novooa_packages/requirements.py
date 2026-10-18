"""Prüfung der Paketangaben, bevor sie an uv gehen.

Erlaubt ist nur ein Paketname von PyPI, optional mit Extras und Versionsangabe
(`pandas`, `pandas==2.2.3`, `requests[socks]>=2.31,<3`). URLs, Pfade und Optionen
wie `--index-url` sind ausgeschlossen: Eine Angabe darf nie mehr bewirken als
„dieses Paket von PyPI“.
"""
import re

_NAME = r"[A-Za-z0-9](?:[A-Za-z0-9._-]*[A-Za-z0-9])?"
_EXTRAS = r"\[\s*" + _NAME + r"(?:\s*,\s*" + _NAME + r")*\s*\]"
_CLAUSE = r"(?:===|==|!=|~=|>=|<=|>|<)\s*[A-Za-z0-9.*+!_-]+"
_SPEC = re.compile(rf"^({_NAME})\s*({_EXTRAS})?\s*({_CLAUSE}(?:\s*,\s*{_CLAUSE})*)?$")
_ENVIRONMENT_ID = re.compile(r"^[0-9a-f]{64}$")
MAX_PACKAGES = 50


class RequirementInvalid(ValueError):
    pass


def checked_packages(packages):
    if not isinstance(packages, list) or not packages:
        raise RequirementInvalid("Die Paketliste ist leer.")
    if len(packages) > MAX_PACKAGES:
        raise RequirementInvalid(f"Höchstens {MAX_PACKAGES} Pakete je Umgebung.")
    for package in packages:
        if not isinstance(package, str) or not _SPEC.match(package.strip()):
            raise RequirementInvalid(f"Ungültige Paketangabe: {package!r}")
    return [package.strip() for package in packages]


def checked_environment_id(environment_id):
    if not isinstance(environment_id, str) or not _ENVIRONMENT_ID.match(environment_id):
        raise RequirementInvalid("Ungültige Umgebungs-ID.")
    return environment_id
