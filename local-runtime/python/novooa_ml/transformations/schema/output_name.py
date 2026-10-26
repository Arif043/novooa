from .scalars import Text


class OutputName(Text):
    """Name eines Ausgangs des ONNX-Modells; die Veröffentlichung prüft, dass es ihn gibt."""

    type_name = "outputName"

    def expectation(self):
        return "den Namen eines Modellausgangs"
