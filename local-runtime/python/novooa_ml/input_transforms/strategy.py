from abc import ABC, abstractmethod


class InputTransformStrategy(ABC):
    @property
    @abstractmethod
    def transformation_type(self):
        """Der im Modellvertrag verwendete Transformationstyp."""

    @abstractmethod
    def transform(self, context, parameters):
        """Verändert den Transformationszustand fachlich begrenzt."""
