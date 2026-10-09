from novooa_ml import tensor_operations

from .parameters import positive_integer
from .strategy import InputTransformStrategy


class AudioMonoStrategy(InputTransformStrategy):
    """Mischt alle Kanäle zu einem Kanal (Mittelwert)."""

    @property
    def transformation_type(self):
        return "audio.mono"

    def transform(self, context, parameters):
        context.require_audio(self.transformation_type)
        context.samples = context.samples.mean(axis=1, keepdims=True).astype(context.numpy.float32)


class AudioResampleStrategy(InputTransformStrategy):
    """Ändert die Abtastrate per Fourier-Resampling; Tonhöhe und Dauer bleiben erhalten."""

    @property
    def transformation_type(self):
        return "audio.resample"

    def transform(self, context, parameters):
        context.require_audio(self.transformation_type)
        target = parameters.get("sampleRate")
        if not tensor_operations.is_integer(target) or target <= 0:
            raise ValueError("audio.resample benötigt sampleRate als positive ganze Zahl.")
        if target == context.sample_rate:
            return
        numpy = context.numpy
        frames = context.samples.shape[0]
        length = max(1, round(frames * target / context.sample_rate))
        spectrum = numpy.fft.rfft(context.samples, axis=0)
        resampled = numpy.fft.irfft(spectrum, n=length, axis=0) * (length / frames)
        context.samples = resampled.astype(numpy.float32)
        context.sample_rate = target


class AudioNormalizeStrategy(InputTransformStrategy):
    """Bringt die Lautstärke auf einen Spitzen- (`peak`) oder Effektivwert (`rms`)."""

    @property
    def transformation_type(self):
        return "audio.normalize"

    def transform(self, context, parameters):
        context.require_audio(self.transformation_type)
        numpy = context.numpy
        mode = parameters.get("mode", "peak")
        if mode not in ("peak", "rms"):
            raise ValueError("audio.normalize benötigt mode peak oder rms.")
        default = 1.0 if mode == "peak" else 0.1
        target = tensor_operations.number(parameters.get("target", default), self.transformation_type, "target")
        samples = context.samples
        level = numpy.abs(samples).max() if mode == "peak" else numpy.sqrt(numpy.mean(samples ** 2))
        # Stille hat keinen Pegel und bleibt unverändert.
        if level > 0:
            context.samples = (samples * (target / level)).astype(numpy.float32)


class AudioFitDurationStrategy(InputTransformStrategy):
    """Füllt mit Stille auf oder kürzt auf eine feste Dauer in Sekunden."""

    @property
    def transformation_type(self):
        return "audio.fitDuration"

    def transform(self, context, parameters):
        context.require_audio(self.transformation_type)
        seconds = tensor_operations.number(parameters.get("seconds"), self.transformation_type, "seconds")
        if seconds <= 0:
            raise ValueError("audio.fitDuration benötigt seconds größer als null.")
        length = positive_integer(max(1, round(seconds * context.sample_rate)))
        context.samples = tensor_operations.fit_length(
            context.numpy, context.samples,
            {"length": length, "axis": 0, "keep": parameters.get("keep", "start")},
        )
