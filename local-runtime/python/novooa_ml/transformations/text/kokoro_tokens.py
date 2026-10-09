from novooa_ml.transformations.kinds import TENSOR, TEXT
from novooa_ml.transformations.strategy import TransformationStrategy
from novooa_ml.transformations.values import require_text

from .kokoro_token_ids import kokoro_token_ids


class KokoroTokensStrategy(TransformationStrategy):
    """Text → Kokoro-Token-IDs, eingerahmt von Füll-Tokens."""

    accepts = (TEXT,)
    produces = TENSOR

    @property
    def transformation_type(self):
        return "text.kokoroTokens"

    def transform(self, value, parameters, context):
        tokens = kokoro_token_ids(require_text(value, self.transformation_type), parameters)
        return context.numpy.asarray([[0, *tokens, 0]], dtype=context.numpy.int64)
