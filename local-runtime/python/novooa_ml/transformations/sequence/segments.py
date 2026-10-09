from novooa_ml.transformations.kinds import JSON_RESULT, TENSOR
from novooa_ml.transformations.parameters import is_integer, number
from novooa_ml.transformations.schema import Integer, ListOf, Number, Text
from novooa_ml.transformations.strategy import TransformationStrategy


class SequenceSegmentsStrategy(TransformationStrategy):
    """Macht aus Frame-Werten Zeitabschnitte, z. B. für Sprachaktivität oder Sprecher.

    Eindimensionale Scores werden per `threshold` zu Abschnitten `{start, end, score}`;
    zweidimensionale Klassenscores (Frames × Klassen) zu Abschnitten je wahrscheinlichster Klasse
    `{start, end, index, label?, score}`. Zeiten in Sekunden, Werte auf 6 Stellen gerundet.
    """

    accepts = (TENSOR,)
    produces = JSON_RESULT
    parameters = {
        "frameDuration": Number(minimum=0, optional=True),
        "hopLength": Integer(minimum=1, optional=True),
        "sampleRate": Integer(minimum=1, optional=True),
        "threshold": Number(optional=True, default=0.5),
        "labels": ListOf(Text(allow_empty=True), optional=True),
        "backgroundIndex": Integer(minimum=0, optional=True),
        "mergeGap": Number(minimum=0, optional=True, default=0),
        "minDuration": Number(minimum=0, optional=True, default=0),
    }

    @property
    def transformation_type(self):
        return "sequence.segments"

    def transform(self, value, parameters, context):
        scores = context.numpy.asarray(value, dtype=float)
        if scores.ndim not in (1, 2):
            raise ValueError("sequence.segments erwartet Frames oder Frames × Klassen.")
        frame = frame_duration(parameters)
        runs = score_runs(scores, parameters) if scores.ndim == 1 else class_runs(context.numpy, scores, parameters)
        runs = merged(runs, gap_frames(parameters, frame))
        minimum = number(parameters.get("minDuration", 0), self.transformation_type, "minDuration")
        # Bei eindimensionalen Scores gibt es keine Klassen und damit weder index noch label.
        labels = False if scores.ndim == 1 else parameters.get("labels")
        return [segment(run, frame, labels) for run in runs if (run["end"] - run["start"]) * frame >= minimum]


def frame_duration(parameters):
    if "frameDuration" in parameters:
        duration = number(parameters["frameDuration"], "sequence.segments", "frameDuration")
        if duration <= 0:
            raise ValueError("sequence.segments benötigt frameDuration größer als null.")
        return duration
    hop, rate = parameters.get("hopLength"), parameters.get("sampleRate")
    if not (is_integer(hop) and is_integer(rate) and hop > 0 and rate > 0):
        raise ValueError("sequence.segments benötigt frameDuration oder hopLength und sampleRate.")
    return hop / rate


def score_runs(scores, parameters):
    threshold = number(parameters.get("threshold", 0.5), "sequence.segments", "threshold")
    return runs_of([None if score < threshold else 0 for score in scores], lambda index, _: scores[index])


def class_runs(numpy, scores, parameters):
    classes = scores.shape[1]
    labels = parameters.get("labels")
    if labels is not None and (not isinstance(labels, list) or len(labels) != classes):
        raise ValueError(f"sequence.segments: labels muss genau {classes} Einträge haben.")
    background = parameters.get("backgroundIndex")
    if background is not None and (not is_integer(background) or not 0 <= background < classes):
        raise ValueError("sequence.segments: backgroundIndex liegt außerhalb der Klassen.")
    best = numpy.argmax(scores, axis=1)
    keys = [None if int(index) == background else int(index) for index in best]
    return runs_of(keys, lambda index, key: scores[index, key])


def runs_of(keys, score_at):
    runs = []
    for index, key in enumerate(keys):
        if key is None:
            continue
        if runs and runs[-1]["key"] == key and runs[-1]["end"] == index:
            runs[-1]["end"] = index + 1
            runs[-1]["scores"].append(score_at(index, key))
        else:
            runs.append({"key": key, "start": index, "end": index + 1, "scores": [score_at(index, key)]})
    return runs


def gap_frames(parameters, frame):
    gap = number(parameters.get("mergeGap", 0), "sequence.segments", "mergeGap")
    return round(gap / frame)


def merged(runs, gap):
    result = []
    for run in runs:
        previous = result[-1] if result else None
        if previous and previous["key"] == run["key"] and run["start"] - previous["end"] <= gap:
            previous["end"] = run["end"]
            previous["scores"].extend(run["scores"])
        else:
            result.append(run)
    return result


def segment(run, frame, labels):
    item = {"start": round(run["start"] * frame, 6), "end": round(run["end"] * frame, 6)}
    if labels is not False:
        item["index"] = run["key"]
        if labels is not None:
            item["label"] = labels[run["key"]]
    item["score"] = round(sum(map(float, run["scores"])) / len(run["scores"]), 6)
    return item
