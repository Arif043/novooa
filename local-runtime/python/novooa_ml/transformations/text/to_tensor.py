from novooa_ml.transformations.kinds import TENSOR, TEXT
from novooa_ml.transformations.strategy import TransformationStrategy
from novooa_ml.transformations.values import require_text


class TextToTensorStrategy(TransformationStrategy):
    """Text → String-Tensor `[1]`, z. B. für Modelle mit eingebauter Textverarbeitung (TF-IDF)."""

    accepts = (TEXT,)
    produces = TENSOR

    @property
    def transformation_type(self):
        return "text.toTensor"

    def transform(self, value, parameters, context):
        return context.numpy.array([require_text(value, self.transformation_type)], dtype=object)
