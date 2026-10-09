from novooa_ml.transformations.strategy import TransformationStrategy
from novooa_ml.transformations.values import require_text

from .piper_phoneme_ids import phoneme_ids


class PiperPhonemesStrategy(TransformationStrategy):
    """Text → Piper-Phonem-IDs mit Start- und Endsymbol."""

    @property
    def transformation_type(self):
        return "text.piperPhonemes"

    def transform(self, value, parameters, context):
        text = require_text(value, self.transformation_type)
        return phoneme_ids(text, parameters, context.numpy)
