from novooa_ml.transformations.kinds import TENSOR
from novooa_ml.transformations.parameters import axis_of
from novooa_ml.transformations.strategy import TransformationStrategy


class L2NormalizeStrategy(TransformationStrategy):
    """Skaliert Vektoren auf Länge 1, damit sich Embeddings per Skalarprodukt vergleichen lassen."""

    accepts = (TENSOR,)
    produces = TENSOR

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
