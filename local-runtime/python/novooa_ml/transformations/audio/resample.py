from novooa_ml.transformations.kinds import AUDIO
from novooa_ml.transformations.parameters import is_integer
from novooa_ml.transformations.schema import Integer
from novooa_ml.transformations.strategy import TransformationStrategy
from novooa_ml.transformations.values import AudioSignal, require_audio


class AudioResampleStrategy(TransformationStrategy):
    """Ändert die Abtastrate per Fourier-Resampling; Tonhöhe und Dauer bleiben erhalten."""

    accepts = (AUDIO,)
    produces = AUDIO
    parameters = {"sampleRate": Integer(minimum=1)}

    @property
    def transformation_type(self):
        return "audio.resample"

    def transform(self, value, parameters, context):
        signal = require_audio(value, self.transformation_type, context)
        target = parameters.get("sampleRate")
        if not is_integer(target) or target <= 0:
            raise ValueError("audio.resample benötigt sampleRate als positive ganze Zahl.")
        if target == signal.sample_rate:
            return signal
        numpy = context.numpy
        frames = signal.samples.shape[0]
        length = max(1, round(frames * target / signal.sample_rate))
        spectrum = numpy.fft.rfft(signal.samples, axis=0)
        resampled = numpy.fft.irfft(spectrum, n=length, axis=0) * (length / frames)
        return AudioSignal(resampled.astype(numpy.float32), target)
