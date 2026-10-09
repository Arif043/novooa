from novooa_ml.transformations.kinds import TENSOR
from novooa_ml.transformations.parameters import axis_of, is_integer
from novooa_ml.transformations.strategy import TransformationStrategy


class SliceStrategy(TransformationStrategy):
    """Wählt den Bereich start bis ausschließlich end entlang einer Achse."""

    accepts = (TENSOR,)
    produces = TENSOR

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
