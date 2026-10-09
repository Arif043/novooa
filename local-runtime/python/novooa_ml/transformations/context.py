class TransformationContext:
    """Was eine Pipeline über ihre Schritte hinweg braucht — für Ein- und Ausgang gleich.

    `metadata` hält Wissen, das ein Schritt für spätere hinterlässt (z. B. das Tensor-Layout).
    """

    def __init__(self, numpy, image_module=None, resource_reader=None, output_name=None, output_parameters=()):
        self.numpy = numpy
        self.image_module = image_module
        self.metadata = {}
        self._resource_reader = resource_reader
        self._output_name = output_name
        self._output_parameters = output_parameters

    def resource_bytes(self, name):
        if self._resource_reader is None:
            raise ValueError("Die Transformation hat keinen Zugriff auf Modellressourcen.")
        if not isinstance(name, str) or not name:
            raise ValueError("Der Name einer Modellressource ist ungültig.")
        return self._resource_reader(name)

    def parameter_value(self, descriptor):
        """Vom Nutzer eingestellter Wert eines Ausgangsparameters (`outputParameters`)."""
        name = required_string(descriptor.get("name"), "Der Name des Ausgangsparameters fehlt.")
        selected = next(
            (
                item["value"] for item in self._output_parameters
                if item.get("outputName") == self._output_name and item.get("name") == name
            ),
            descriptor.get("default"),
        )
        minimum = required_integer(descriptor.get("minimum"), "Der Minimalwert ist ungültig.")
        maximum = required_integer(descriptor.get("maximum"), "Der Maximalwert ist ungültig.")
        if not isinstance(selected, int) or selected < minimum or selected > maximum:
            raise ValueError(f"Der Parameter {name} liegt außerhalb des erlaubten Bereichs.")
        return selected


def required_string(value, message):
    if not isinstance(value, str) or not value:
        raise ValueError(message)
    return value


def required_integer(value, message):
    if not isinstance(value, int):
        raise ValueError(message)
    return value
