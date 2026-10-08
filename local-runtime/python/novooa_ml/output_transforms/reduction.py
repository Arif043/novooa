from novooa_ml.tensor_operations import axis_of, is_integer

from .registry import OutputTransformationStrategy


class ArgmaxStrategy(OutputTransformationStrategy):
    """Index des größten Werts entlang einer Achse, z. B. die wahrscheinlichste Klasse."""

    @property
    def transformation_type(self):
        return "tensor.argmax"

    def transform(self, value, parameters, context):
        tensor = context.numpy.asarray(value)
        axis = axis_of(tensor, parameters, self.transformation_type)
        return context.numpy.argmax(tensor, axis=axis)


class SqueezeStrategy(OutputTransformationStrategy):
    """Entfernt Dimensionen der Größe 1, z. B. die Batch-Dimension."""

    @property
    def transformation_type(self):
        return "tensor.squeeze"

    def transform(self, value, parameters, context):
        return context.numpy.squeeze(context.numpy.asarray(value))


class ReduceStrategy(OutputTransformationStrategy):
    """Verdichtet eine Achse per Mittelwert, Summe, Maximum oder Minimum."""

    @property
    def transformation_type(self):
        return "tensor.reduce"

    def transform(self, value, parameters, context):
        numpy = context.numpy
        operations = {"mean": numpy.mean, "sum": numpy.sum, "max": numpy.max, "min": numpy.min}
        operation = operations.get(parameters.get("operation"))
        if operation is None:
            raise ValueError("tensor.reduce benötigt operation mean, sum, max oder min.")
        tensor = numpy.asarray(value)
        return operation(tensor, axis=axis_of(tensor, parameters, self.transformation_type))


class L2NormalizeStrategy(OutputTransformationStrategy):
    """Skaliert Vektoren auf Länge 1, damit sich Embeddings per Skalarprodukt vergleichen lassen."""

    @property
    def transformation_type(self):
        return "tensor.l2Normalize"

    def transform(self, value, parameters, context):
        numpy = context.numpy
        tensor = numpy.asarray(value, dtype=numpy.float32)
        axis = axis_of(tensor, parameters, self.transformation_type)
        norms = numpy.linalg.norm(tensor, axis=axis, keepdims=True)
        # Nullvektoren haben keine Richtung und bleiben unverändert.
        return tensor / numpy.where(norms == 0, 1, norms)


class SliceStrategy(OutputTransformationStrategy):
    """Wählt den Bereich start bis ausschließlich end entlang einer Achse."""

    @property
    def transformation_type(self):
        return "tensor.slice"

    def transform(self, value, parameters, context):
        tensor = context.numpy.asarray(value)
        axis = axis_of(tensor, parameters, self.transformation_type)
        start, end = parameters.get("start"), parameters.get("end")
        if not is_integer(start) or (end is not None and not is_integer(end)):
            raise ValueError("tensor.slice benötigt start und optional end als ganze Zahlen.")
        selection = [slice(None)] * tensor.ndim
        selection[axis] = slice(start, end)
        result = tensor[tuple(selection)]
        if result.shape[axis] == 0:
            raise ValueError("tensor.slice: Der gewählte Bereich ist leer.")
        return result


class RoundStrategy(OutputTransformationStrategy):
    """Rundet auf `decimals` Nachkommastellen (Standard: ganze Zahlen)."""

    @property
    def transformation_type(self):
        return "tensor.round"

    def transform(self, value, parameters, context):
        decimals = parameters.get("decimals", 0)
        if not is_integer(decimals) or decimals < 0:
            raise ValueError("tensor.round benötigt decimals als nichtnegative ganze Zahl.")
        return context.numpy.round(context.numpy.asarray(value, dtype=float), decimals)
