from novooa_ml import tensor_operations

from .registry import OutputTransformationStrategy


class SharedTensorOperationStrategy(OutputTransformationStrategy):
    """Dieselben Tensoroperationen wie am Eingang, hier auf einen Modellausgang angewandt."""

    operation = None

    def transform(self, value, parameters, context):
        return type(self).operation(context.numpy, value, parameters)


class OutputScaleStrategy(SharedTensorOperationStrategy):
    transformation_type = "tensor.scale"
    operation = staticmethod(tensor_operations.scale)


class OutputClipStrategy(SharedTensorOperationStrategy):
    transformation_type = "tensor.clip"
    operation = staticmethod(tensor_operations.clip)


class OutputReshapeStrategy(SharedTensorOperationStrategy):
    transformation_type = "tensor.reshape"
    operation = staticmethod(tensor_operations.reshape)


class OutputTransposeStrategy(SharedTensorOperationStrategy):
    transformation_type = "tensor.transpose"
    operation = staticmethod(tensor_operations.transpose)
