from .strategy import InputTransformStrategy


class TensorLayoutStrategy(InputTransformStrategy):
    @property
    def transformation_type(self):
        return "tensor.layout"

    def transform(self, context, parameters):
        requested = parameters.get("order")
        if requested not in ["channelsFirst", "channelsLast"]:
            raise ValueError("tensor.layout benötigt channelsFirst oder channelsLast.")
        if requested == context.layout:
            return
        axes = (2, 0, 1) if requested == "channelsFirst" else (1, 2, 0)
        context.tensor = context.tensor_array().transpose(axes)
        context.layout = requested
