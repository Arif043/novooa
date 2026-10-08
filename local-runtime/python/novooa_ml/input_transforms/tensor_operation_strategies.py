from novooa_ml import tensor_operations

from .strategy import InputTransformStrategy


class TensorOperationStrategy(InputTransformStrategy):
    """Wendet eine allgemeine Tensoroperation auf den bisherigen Eingangstensor an."""

    operation = None

    def transform(self, context, parameters):
        operation = type(self).operation
        context.tensor = operation(context.numpy, context.tensor_array(), parameters)


class TensorScaleStrategy(TensorOperationStrategy):
    transformation_type = "tensor.scale"
    operation = staticmethod(tensor_operations.scale)


class TensorClipStrategy(TensorOperationStrategy):
    transformation_type = "tensor.clip"
    operation = staticmethod(tensor_operations.clip)


class TensorReshapeStrategy(TensorOperationStrategy):
    transformation_type = "tensor.reshape"
    operation = staticmethod(tensor_operations.reshape)


class TensorTransposeStrategy(TensorOperationStrategy):
    transformation_type = "tensor.transpose"
    operation = staticmethod(tensor_operations.transpose)
