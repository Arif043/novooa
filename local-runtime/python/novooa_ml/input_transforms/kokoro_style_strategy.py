import io

from .kokoro_text_strategy import kokoro_token_ids
from .strategy import InputTransformStrategy


class KokoroStyleStrategy(InputTransformStrategy):
    @property
    def transformation_type(self):
        return "text.kokoroStyle"

    def transform(self, context, parameters):
        token_count = len(kokoro_token_ids(context.text, parameters)) + 2
        voice = required_voice(parameters)
        resource_name = required_resource_name(parameters)
        context.tensor = style_for(context.resource_bytes(resource_name), voice, token_count, context.numpy)


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
