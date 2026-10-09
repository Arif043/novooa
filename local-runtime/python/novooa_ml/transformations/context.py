class TransformationContext:
    """Was eine Pipeline über ihre Schritte hinweg braucht — für Ein- und Ausgang gleich.

    `metadata` hält Wissen, das ein Schritt für spätere hinterlässt (z. B. das Tensor-Layout).
    Vom Nutzer einstellbare Werte (Settings) setzt TypeScript vorab in die Parameter ein.
    """

    def __init__(self, numpy, image_module=None, resource_reader=None, inputs=None):
        self.numpy = numpy
        self.image_module = image_module
        self.metadata = {}
        self._resource_reader = resource_reader
        # Am Ausgang: Metadaten der Modelleingänge (Name → {"geometry": …}).
        self._inputs = inputs or {}

    def resource_bytes(self, name):
        if self._resource_reader is None:
            raise ValueError("Die Transformation hat keinen Zugriff auf Modellressourcen.")
        if not isinstance(name, str) or not name:
            raise ValueError("Der Name einer Modellressource ist ungültig.")
        return self._resource_reader(name)

    def input_geometry(self, name, transformation_type):
        """Wie der Eingang `name` das Quellbild ins Modellbild abgebildet hat."""
        metadata = self._inputs.get(name)
        if not isinstance(metadata, dict) or "geometry" not in metadata:
            raise ValueError(f"{transformation_type}: Der Eingang {name} liefert keine Bildgeometrie.")
        if metadata["geometry"] is None:
            raise ValueError(
                f"{transformation_type}: Die Bildgeometrie des Eingangs {name} lässt sich nicht zurückrechnen "
                "(z. B. nach image.perspectiveCrop)."
            )
        return metadata["geometry"]
