from .strategy import InputTransformStrategy


class ConstantTensorStrategy(InputTransformStrategy):
    @property
    def transformation_type(self):
        return "tensor.constant"

    def transform(self, context, parameters):
        values = parameters.get("values")
        if not isinstance(values, list) or not values or not all(isinstance(value, (int, float)) for value in values):
            raise ValueError("tensor.constant benötigt ein nicht leeres Zahlenfeld values.")
        context.tensor = context.numpy.asarray(values, dtype=context.numpy.float32)
