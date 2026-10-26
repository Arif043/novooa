class TransformationContext:
    """Was eine Pipeline über ihre Schritte hinweg braucht — für Ein- und Ausgang gleich.

    `metadata` hält Wissen, das ein Schritt für spätere hinterlässt (z. B. das Tensor-Layout).
    Vom Nutzer einstellbare Werte (Settings) setzt TypeScript vorab in die Parameter ein.
    """

    def __init__(self, numpy, image_module=None, resource_reader=None, inputs=None, outputs=None):
        self.numpy = numpy
        self.image_module = image_module
        self.metadata = {}
        self._resource_reader = resource_reader
        # Am Ausgang: Metadaten der Modelleingänge (Name → {"geometry": …, "tiles": …}).
        self._inputs = inputs or {}
        # Am Ausgang: alle Rohausgänge des Modells (Name → Tensor), auch solche ohne eigenen Vertragsausgang.
        self._outputs = outputs or {}

    def resource_bytes(self, name):
        if self._resource_reader is None:
            raise ValueError("Die Transformation hat keinen Zugriff auf Modellressourcen.")
        if not isinstance(name, str) or not name:
            raise ValueError("Der Name einer Modellressource ist ungültig.")
        return self._resource_reader(name)

    def output_tensor(self, name, transformation_type):
        """Ein Rohausgang des Modells, z. B. die Scores zu den Boxen eines anderen Ausgangs."""
        if name not in self._outputs:
            known = ", ".join(sorted(self._outputs)) or "keine"
            raise ValueError(f"{transformation_type}: Das Modell hat keinen Ausgang {name} (vorhanden: {known}).")
        return self._outputs[name]

    def input_metadata(self, name, key, transformation_type, description):
        """Was der Eingang `name` über seine Quelle mitgegeben hat, z. B. Kachelraster oder Quellbild."""
        metadata = self._inputs.get(name)
        if not isinstance(metadata, dict) or metadata.get(key) is None:
            raise ValueError(f"{transformation_type}: Der Eingang {name} liefert {description}.")
        return metadata[key]

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
