class TransformationRegistry:
    def __init__(self, strategies):
        self._strategies = strategy_map(strategies)

    def apply(self, context, transformations):
        for transformation in transformations:
            self._strategy_for(transformation).transform(
                context, transformation["parameters"]
            )
        return context

    def _strategy_for(self, transformation):
        transformation_type = transformation.get("type")
        strategy = self._strategies.get(transformation_type)
        if strategy is None:
            raise ValueError(
                f"Nicht unterstützte Bildtransformation: {transformation_type}"
            )
        return strategy


def strategy_map(strategies):
    mapped = {strategy.transformation_type: strategy for strategy in strategies}
    if len(mapped) != len(strategies):
        raise ValueError("Transformationstypen dürfen nur einmal registriert werden.")
    return mapped
