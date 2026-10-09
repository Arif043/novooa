from novooa_ml.transformations.kinds import AUDIO, TENSOR
from novooa_ml.transformations.parameters import is_integer, number, optional_number
from novooa_ml.transformations.strategy import TransformationStrategy
from novooa_ml.transformations.values import require_audio

from .mel_filters import mel_filter_bank

SCALES = ("power", "log", "log10", "db")
FLOOR = 1e-10


class AudioMelSpectrogramStrategy(TransformationStrategy):
    """Erzeugt ein Mel-Spektrogramm der Form (melBins, Frames) aus Mono-Audio.

    Standard für viele Audio- und Sprachmodelle; `scale` wählt Leistung, natürlichen oder
    dekadischen Logarithmus oder dB relativ zum Maximum, `dynamicRange` begrenzt den
    Abstand zum Maximum in der gewählten Einheit.
    """

    accepts = (AUDIO,)
    produces = TENSOR

    @property
    def transformation_type(self):
        return "audio.melSpectrogram"

    def transform(self, value, parameters, context):
        signal = require_audio(value, self.transformation_type, context)
        if signal.samples.shape[1] != 1:
            raise ValueError("audio.melSpectrogram benötigt Mono-Audio; vorher audio.mono einsetzen.")
        settings = spectrogram_settings(parameters, signal.sample_rate)
        numpy = context.numpy
        power = power_spectrum(numpy, signal.samples[:, 0], settings)
        filters = mel_filter_bank(
            numpy, signal.sample_rate, settings["frameLength"], settings["melBins"],
            settings["minFrequency"], settings["maxFrequency"], settings["melScale"], settings["filterNormalization"],
        )
        return scaled(numpy, filters @ power, settings).astype(numpy.float32)


def spectrogram_settings(parameters, sample_rate):
    settings = {
        "frameLength": positive(parameters.get("frameLength", 400), "frameLength"),
        "hopLength": positive(parameters.get("hopLength", 160), "hopLength"),
        "melBins": positive(parameters.get("melBins", 80), "melBins"),
        "minFrequency": number(parameters.get("minFrequency", 0), "audio.melSpectrogram", "minFrequency"),
        "maxFrequency": number(parameters.get("maxFrequency", sample_rate / 2), "audio.melSpectrogram", "maxFrequency"),
        "power": number(parameters.get("power", 2), "audio.melSpectrogram", "power"),
        "scale": choice(parameters.get("scale", "power"), SCALES, "scale"),
        "dynamicRange": optional_number(parameters.get("dynamicRange"), "audio.melSpectrogram", "dynamicRange"),
        "melScale": choice(parameters.get("melScale", "slaney"), ("slaney", "htk"), "melScale"),
        "filterNormalization": choice(parameters.get("filterNormalization", "slaney"), ("slaney", "none"), "filterNormalization"),
        "center": parameters.get("center", True) is True,
    }
    if not 0 <= settings["minFrequency"] < settings["maxFrequency"] <= sample_rate / 2:
        raise ValueError("audio.melSpectrogram: minFrequency und maxFrequency müssen zwischen 0 und der halben Abtastrate liegen.")
    if settings["dynamicRange"] is not None and (settings["scale"] == "power" or settings["dynamicRange"] <= 0):
        raise ValueError("audio.melSpectrogram: dynamicRange gilt nur für logarithmische Skalen und muss positiv sein.")
    return settings


def power_spectrum(numpy, samples, settings):
    frame_length, hop = settings["frameLength"], settings["hopLength"]
    if settings["center"]:
        samples = numpy.pad(samples, frame_length // 2, mode="reflect" if len(samples) > frame_length // 2 else "constant")
    if len(samples) < frame_length:
        samples = numpy.pad(samples, (0, frame_length - len(samples)))
    count = 1 + (len(samples) - frame_length) // hop
    indexes = numpy.arange(frame_length)[numpy.newaxis, :] + hop * numpy.arange(count)[:, numpy.newaxis]
    window = 0.5 - 0.5 * numpy.cos(2 * numpy.pi * numpy.arange(frame_length) / frame_length)
    spectrum = numpy.abs(numpy.fft.rfft(samples[indexes] * window, axis=1))
    return (spectrum ** settings["power"]).T


def scaled(numpy, mel, settings):
    scale = settings["scale"]
    if scale == "power":
        return mel
    floored = numpy.maximum(mel, FLOOR)
    if scale == "log":
        values = numpy.log(floored)
    elif scale == "log10":
        values = numpy.log10(floored)
    else:
        values = 10 * numpy.log10(floored) - 10 * numpy.log10(max(float(mel.max()), FLOOR))
    if settings["dynamicRange"] is not None:
        values = numpy.maximum(values, values.max() - settings["dynamicRange"])
    return values


def positive(value, name):
    if not is_integer(value) or value <= 0:
        raise ValueError(f"audio.melSpectrogram benötigt {name} als positive ganze Zahl.")
    return value


def choice(value, options, name):
    if value not in options:
        raise ValueError(f"audio.melSpectrogram: {name} muss einer der Werte {', '.join(options)} sein.")
    return value
