from .registry import OutputTransformationStrategy


class CtcGreedyDecodeStrategy(OutputTransformationStrategy):
    @property
    def transformation_type(self):
        return "sequence.ctcGreedyDecode"

    def transform(self, value, parameters, context):
        labels = parameters.get("labels")
        blank_index = parameters.get("blankIndex")
        if not isinstance(labels, list) or not all(isinstance(item, str) for item in labels):
            raise ValueError("sequence.ctcGreedyDecode benötigt labels.")
        if not isinstance(blank_index, int) or blank_index < 0 or blank_index >= len(labels):
            raise ValueError("Der CTC-Leerindex ist ungültig.")
        batches = value[None, ...] if value.ndim == 2 else value
        if batches.ndim != 3:
            raise ValueError("sequence.ctcGreedyDecode erwartet [zeit, klassen] oder [batch, zeit, klassen].")
        if batches.shape[-1] != len(labels):
            raise ValueError("Die CTC-Labels müssen zur letzten Tensorachse passen.")
        apply_softmax = parameters.get("applySoftmax", True)
        collapse_repeated = parameters.get("collapseRepeated", True)
        if not isinstance(apply_softmax, bool) or not isinstance(collapse_repeated, bool):
            raise ValueError("Die CTC-Parameter sind ungültig.")
        return [
            decode_batch(batch, labels, blank_index, apply_softmax, collapse_repeated, context.numpy)
            for batch in batches
        ]


def decode_batch(batch, labels, blank_index, apply_softmax, collapse_repeated, numpy):
    previous, text, probabilities = -1, "", []
    for row in batch:
        values = softmax(row, numpy) if apply_softmax else row
        index = int(numpy.argmax(values))
        if index != blank_index and (not collapse_repeated or index != previous):
            text += labels[index]
            probabilities.append(float(values[index]))
        previous = index
    confidence = 0 if not probabilities else float(numpy.exp(numpy.mean(numpy.log(numpy.maximum(probabilities, numpy.finfo(float).tiny)))))
    return {"text": text, "confidence": confidence}


def softmax(values, numpy):
    exponentials = numpy.exp(values - numpy.max(values))
    return exponentials / numpy.sum(exponentials)
