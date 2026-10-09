class PipelineResult:
    """Endwert einer Pipeline und die per `result` benannten Zwischenergebnisse."""

    def __init__(self, value, results):
        self.value = value
        self.results = results


class TransformationRegistry:
    def __init__(self, strategies):
        self._strategies = strategy_map(strategies)

    @property
    def supported_types(self):
        return tuple(self._strategies.keys())

    def kinds_of(self, transformation_type):
        """(accepts, produces) eines Typs; None, wenn der Typ unbekannt ist."""
        strategy = self._strategies.get(transformation_type)
        return None if strategy is None else (strategy.accepts, strategy.produces)

    def run(self, value, transformations, context):
        results = {}
        for transformation in transformations:
            value = self._strategy_for(transformation).transform(
                value, transformation["parameters"], context
            )
            name = transformation.get("result")
            if name is not None:
                results[name] = value
        return PipelineResult(value, results)

    def _strategy_for(self, transformation):
        transformation_type = transformation.get("type")
        strategy = self._strategies.get(transformation_type)
        if strategy is None:
            raise ValueError(f"Nicht unterstützte Transformation: {transformation_type}")
        return strategy


def strategy_map(strategies):
    mapped = {strategy.transformation_type: strategy for strategy in strategies}
    if len(mapped) != len(strategies):
        raise ValueError("Transformationstypen dürfen nur einmal registriert werden.")
    return mapped
