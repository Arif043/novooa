from abc import ABC, abstractmethod


class TransformationStrategy(ABC):
    """Gemeinsame Basis aller Ein- und Ausgangstransformationen.

    Eine Strategie erhält einen Wert, die Parameter aus dem Modellvertrag und den Kontext und
    liefert einen neuen Wert; den übergebenen Wert verändert sie nicht.
    """

    @property
    @abstractmethod
    def transformation_type(self):
        """Der im Modellvertrag verwendete Transformationstyp."""

    @abstractmethod
    def transform(self, value, parameters, context):
        """Liefert den transformierten Wert."""
