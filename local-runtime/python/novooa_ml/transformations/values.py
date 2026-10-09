"""Werte, die durch eine Pipeline fließen, und ihr Übergang in einen Tensor.

Am Eingang beginnt eine Pipeline mit dem Quellwert (Bild, Audiosignal, Text, Zahl, JSON);
spätestens am Ende steht ein numpy-Tensor. Bild- und Audioschritte gehören vor Tensorschritte.
"""


class AudioSignal:
    """Samples der Form (Frames, Kanäle) im Bereich -1 bis 1 und ihre Abtastrate."""

    def __init__(self, samples, sample_rate):
        self.samples = samples
        self.sample_rate = sample_rate


def require_image(value, transformation_type, context):
    require_before_tensor(value, transformation_type, context)
    if not hasattr(value, "size") or not hasattr(value, "mode"):
        raise ValueError(f"{transformation_type} erwartet ein Bild.")
    return value


def require_audio(value, transformation_type, context):
    require_before_tensor(value, transformation_type, context)
    if not isinstance(value, AudioSignal):
        raise ValueError(f"{transformation_type} erwartet Audio.")
    return value


def require_text(value, transformation_type):
    if not isinstance(value, str):
        raise ValueError(f"{transformation_type} erwartet Text.")
    return value


def require_before_tensor(value, transformation_type, context):
    if isinstance(value, context.numpy.ndarray):
        raise ValueError(f"{transformation_type} muss vor Tensortransformationen stehen.")


def as_tensor(value, context):
    numpy = context.numpy
    if isinstance(value, numpy.ndarray):
        return value
    if isinstance(value, AudioSignal):
        mono = value.samples.shape[1] == 1
        return value.samples[:, 0] if mono else value.samples.T
    if hasattr(value, "size") and hasattr(value, "mode"):
        array = numpy.asarray(value)
        return array[..., numpy.newaxis] if array.ndim == 2 else array
    if isinstance(value, str):
        raise ValueError("Die Texttransformation hat keinen Tensor erzeugt.")
    raise ValueError("Die Transformation hat keinen Tensor erzeugt.")
