"""Mel-Filterbank (Slaney- oder HTK-Skala), kompatibel zu den üblichen librosa-Voreinstellungen."""


def mel_filter_bank(numpy, sample_rate, frame_length, mel_bins, minimum, maximum, scale, normalization):
    frequencies = numpy.fft.rfftfreq(frame_length, 1 / sample_rate)
    mel_edges = numpy.linspace(hz_to_mel(numpy, minimum, scale), hz_to_mel(numpy, maximum, scale), mel_bins + 2)
    edges = mel_to_hz(numpy, mel_edges, scale)
    widths = numpy.diff(edges)
    ramps = edges[:, numpy.newaxis] - frequencies[numpy.newaxis, :]
    lower = -ramps[:-2] / widths[:-1, numpy.newaxis]
    upper = ramps[2:] / widths[1:, numpy.newaxis]
    weights = numpy.maximum(0, numpy.minimum(lower, upper))
    if normalization == "slaney":
        weights *= (2.0 / (edges[2:] - edges[:-2]))[:, numpy.newaxis]
    return weights.astype(numpy.float32)


def hz_to_mel(numpy, frequencies, scale):
    frequencies = numpy.asarray(frequencies, dtype=numpy.float64)
    if scale == "htk":
        return 2595.0 * numpy.log10(1.0 + frequencies / 700.0)
    linear = frequencies / (200.0 / 3)
    logarithmic = 15.0 + numpy.log(numpy.maximum(frequencies, 1e-10) / 1000.0) / (numpy.log(6.4) / 27.0)
    return numpy.where(frequencies >= 1000.0, logarithmic, linear)


def mel_to_hz(numpy, mels, scale):
    mels = numpy.asarray(mels, dtype=numpy.float64)
    if scale == "htk":
        return 700.0 * (10.0 ** (mels / 2595.0) - 1.0)
    linear = mels * (200.0 / 3)
    logarithmic = 1000.0 * numpy.exp((numpy.log(6.4) / 27.0) * (mels - 15.0))
    return numpy.where(mels >= 15.0, logarithmic, linear)
