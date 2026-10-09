import io

from novooa_ml.transformations.kinds import TENSOR, TEXT
from novooa_ml.transformations.strategy import TransformationStrategy
from novooa_ml.transformations.values import require_text

from .kokoro_token_ids import kokoro_token_ids


class KokoroStyleStrategy(TransformationStrategy):
    """Wählt den Stilvektor der Stimme passend zur Tokenanzahl aus der Stimmenressource."""

    accepts = (TEXT,)
    produces = TENSOR

    @property
    def transformation_type(self):
        return "text.kokoroStyle"

    def transform(self, value, parameters, context):
        text = require_text(value, self.transformation_type)
        token_count = len(kokoro_token_ids(text, parameters)) + 2
        voice = required_voice(parameters)
        resource = context.resource_bytes(required_resource_name(parameters))
        return style_for(resource, voice, token_count, context.numpy)


def required_voice(parameters):
    voice = parameters.get("voice")
    if not isinstance(voice, str) or not voice:
        raise ValueError("Die Kokoro-Style-Transformation benötigt eine Stimme.")
    return voice


def required_resource_name(parameters):
    name = parameters.get("resource")
    if not isinstance(name, str) or not name:
        raise ValueError("Die Kokoro-Style-Transformation benötigt eine Modellressource.")
    return name


def style_for(resource_bytes, voice, token_count, numpy):
    try:
        with numpy.load(io.BytesIO(resource_bytes)) as voices:
            styles = voices[voice]
    except KeyError as error:
        raise ValueError(f"Die Kokoro-Stimme {voice} ist nicht vorhanden.") from error
    if styles.ndim != 3 or styles.shape[1:] != (1, 256):
        raise ValueError("Die Kokoro-Stimmenressource hat ein ungültiges Format.")
    return styles[min(token_count, styles.shape[0] - 1)].astype(numpy.float32, copy=True)
