from novooa_ml.transformations.kinds import JSON_RESULT, TENSOR
from novooa_ml.transformations.parameters import is_integer
from novooa_ml.transformations.strategy import TransformationStrategy


class TopKStrategy(TransformationStrategy):
    """Liefert die k größten Werte eines Vektors als `{index, value}`.

    `k` ist eine Zahl oder per Setting einstellbar (`"k": "$anzahl"`).
    """

    accepts = (TENSOR,)
    produces = JSON_RESULT

    @property
    def transformation_type(self):
        return "tensor.topK"

    def transform(self, value, parameters, context):
        if value.ndim > 1 and context.numpy.prod(value.shape[:-1]) != 1:
            raise ValueError("tensor.topK unterstützt nur einzelne Vektoren.")
        count = count_of(parameters)
        values = value.reshape(-1)
        indexes = context.numpy.argsort(values)[::-1][:count]
        return [{"index": int(index), "value": float(values[index])} for index in indexes]


def count_of(parameters):
    # Alte Manifeste beschrieben k als Parameter; TypeScript macht daraus ein Setting.
    # Ohne Bindung gilt der dort hinterlegte Standardwert.
    legacy = parameters.get("parameter")
    count = parameters.get("k", legacy.get("default") if isinstance(legacy, dict) else None)
    if not is_integer(count) or count <= 0:
        raise ValueError("tensor.topK benötigt k als positive ganze Zahl.")
    return count
