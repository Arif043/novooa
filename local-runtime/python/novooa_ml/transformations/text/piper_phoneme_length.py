from novooa_ml.transformations.kinds import TENSOR, TEXT
from novooa_ml.transformations.strategy import TransformationStrategy
from novooa_ml.transformations.values import require_text

from .piper_phoneme_ids import phoneme_ids


class PiperPhonemeLengthStrategy(TransformationStrategy):
    """Text → Anzahl der Piper-Phonem-IDs (zweiter Modelleingang)."""

    accepts = (TEXT,)
    produces = TENSOR

    @property
    def transformation_type(self):
        return "text.piperPhonemeLength"

    def transform(self, value, parameters, context):
        text = require_text(value, self.transformation_type)
        ids = phoneme_ids(text, parameters, context.numpy)
        return context.numpy.asarray([len(ids)], dtype=context.numpy.int64)
