from abc import ABC, abstractmethod


class TransformationStrategy(ABC):
    """Gemeinsame Basis aller Ein- und Ausgangstransformationen.

    Eine Strategie erhält einen Wert, die Parameter aus dem Modellvertrag und den Kontext und
    liefert einen neuen Wert; den übergebenen Wert verändert sie nicht. `accepts` und
    `produces` nennen die Wertarten (siehe `kinds.py`), aus denen die Pipeline-Prüfung ableitet,
    wo die Transformation stehen darf.
    """

    accepts = ()
    produces = None
    # Name → Schema (`transformations/schema`); Grundlage der Prüfung beim Import.
    parameters = {}

    @property
    @abstractmethod
    def transformation_type(self):
        """Der im Modellvertrag verwendete Transformationstyp."""

    @abstractmethod
    def transform(self, value, parameters, context):
        """Liefert den transformierten Wert."""
