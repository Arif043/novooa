from abc import ABC, abstractmethod


class OutputTransformationStrategy(ABC):
    @property
    @abstractmethod
    def transformation_type(self):
        pass

    @abstractmethod
    def transform(self, value, parameters, context):
        pass


class OutputTransformationRegistry:
    def __init__(self, strategies):
        self._strategies = {strategy.transformation_type: strategy for strategy in strategies}
        if len(self._strategies) != len(strategies):
            raise ValueError("Ausgabetransformationen dürfen nur einmal registriert werden.")

    def process(self, tensor, transformations, context):
        value = tensor
        values = {"tensor": workflow_value(value)}
        for transformation in transformations:
            strategy = self._strategy_for(transformation)
            value = strategy.transform(value, transformation["parameters"], context)
            workflow = workflow_value(value)
            values["tensor"] = workflow
            result = transformation.get("result")
            if result is not None:
                values[result] = workflow
        return values

    def _strategy_for(self, transformation):
        transformation_type = transformation.get("type")
        strategy = self._strategies.get(transformation_type)
        if strategy is None:
            raise ValueError(f"Nicht unterstützte Transformation: {transformation_type}")
        return strategy


class OutputTransformationContext:
    def __init__(self, output_name, output_parameters, numpy):
        self.output_name = output_name
        self.output_parameters = output_parameters
        self.numpy = numpy

    def parameter_value(self, descriptor):
        name = required_string(descriptor.get("name"), "Der Name des Ausgangsparameters fehlt.")
        selected = next(
            (
                item["value"]
                for item in self.output_parameters
                if item.get("outputName") == self.output_name and item.get("name") == name
            ),
            descriptor.get("default"),
        )
        minimum = required_integer(descriptor.get("minimum"), "Der Minimalwert ist ungültig.")
        maximum = required_integer(descriptor.get("maximum"), "Der Maximalwert ist ungültig.")
        if not isinstance(selected, int) or selected < minimum or selected > maximum:
            raise ValueError(f"Der Parameter {name} liegt außerhalb des erlaubten Bereichs.")
        return selected


def workflow_value(value):
    if hasattr(value, "tolist"):
        return value.tolist()
    return value


def required_string(value, message):
    if not isinstance(value, str) or not value:
        raise ValueError(message)
    return value


def required_integer(value, message):
    if not isinstance(value, int):
        raise ValueError(message)
    return value
