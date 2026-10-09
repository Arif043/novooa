from novooa_ml.transformations.strategy import TransformationStrategy


class CtcGreedyDecodeStrategy(TransformationStrategy):
    """Dekodiert CTC-Logits gierig in `{text, confidence}`."""

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
        allowed_indices = allowed_character_indices(parameters, labels, blank_index)
        return [
            decode_batch(batch, labels, blank_index, apply_softmax, collapse_repeated, allowed_indices, context.numpy)
            for batch in batches
        ]


def allowed_character_indices(parameters, labels, blank_index):
    allowed = parameters.get("allowedCharacters")
    if allowed is None:
        return None
    if not isinstance(allowed, str) or not allowed:
        raise ValueError("sequence.ctcGreedyDecode benötigt erlaubte Zeichen als nichtleeren Text.")
    indices = {blank_index, *(index for index, label in enumerate(labels) if label in allowed)}
    if len(indices) == 1:
        raise ValueError("Keines der erlaubten CTC-Zeichen ist im Alphabet vorhanden.")
    return tuple(indices)


def decode_batch(batch, labels, blank_index, apply_softmax, collapse_repeated, allowed_indices, numpy):
    previous, text, probabilities = -1, "", []
    for row in batch:
        values = softmax(row, numpy) if apply_softmax else row
        index = best_index(values, allowed_indices, numpy)
        if index != blank_index and (not collapse_repeated or index != previous):
            text += labels[index]
            probabilities.append(float(values[index]))
        previous = index
    confidence = 0 if not probabilities else float(numpy.exp(numpy.mean(numpy.log(numpy.maximum(probabilities, numpy.finfo(float).tiny)))))
    return {"text": text, "confidence": confidence}


def best_index(values, allowed_indices, numpy):
    if allowed_indices is None:
        return int(numpy.argmax(values))
    return max(allowed_indices, key=lambda index: values[index])


def softmax(values, numpy):
    exponentials = numpy.exp(values - numpy.max(values))
    return exponentials / numpy.sum(exponentials)
