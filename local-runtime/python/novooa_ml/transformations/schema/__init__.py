"""Deklarative Parameterschemas der Transformationen.

Jede Strategie beschreibt ihre Parameter mit diesen Bausteinen. Die Runtime prüft damit ein
Manifest schon beim Import: fehlende, falsche und unbekannte Parameter sowie Bindungen an
Settings, deren Steuerelement nicht passt. `describe()` liefert die Beschreibung als JSON.
"""

from .composites import ListOf, MapOf, OneOf, Record
from .scalars import Boolean, Choice, Integer, Number, Schema, Text

__all__ = ["Boolean", "Choice", "Integer", "ListOf", "MapOf", "Number", "OneOf", "Record", "Schema", "Text"]
