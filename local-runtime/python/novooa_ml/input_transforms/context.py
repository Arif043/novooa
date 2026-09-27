class ImageTransformContext:
    def __init__(self, image, numpy, image_module, resource_reader=None):
        self.image = image
        self.numpy = numpy
        self.image_module = image_module
        self.tensor = None
        self.layout = "channelsLast"
        self._resource_reader = resource_reader

    def require_image(self, transformation_type):
        if self.tensor is not None:
            raise ValueError(
                f"{transformation_type} muss vor Tensortransformationen stehen."
            )

    def tensor_array(self):
        if self.tensor is None:
            array = self.numpy.asarray(self.image)
            self.tensor = array[..., self.numpy.newaxis] if array.ndim == 2 else array
        return self.tensor

    def resource_bytes(self, name):
        return resource_bytes_for(self._resource_reader, name)


class TextTransformContext:
    def __init__(self, text, numpy, resource_reader=None):
        self.text = text
        self.numpy = numpy
        self.tensor = None
        self._resource_reader = resource_reader

    def tensor_array(self):
        if self.tensor is None:
            raise ValueError("Die Texttransformation hat keinen Tensor erzeugt.")
        return self.tensor

    def resource_bytes(self, name):
        return resource_bytes_for(self._resource_reader, name)


class NumberTransformContext:
    def __init__(self, value, numpy, resource_reader=None):
        self.value = value
        self.numpy = numpy
        self.tensor = None
        self._resource_reader = resource_reader

    def tensor_array(self):
        if self.tensor is None:
            raise ValueError("Die Zahltransformation hat keinen Tensor erzeugt.")
        return self.tensor

    def resource_bytes(self, name):
        return resource_bytes_for(self._resource_reader, name)


def resource_bytes_for(reader, name):
    if reader is None:
        raise ValueError("Die Transformation hat keinen Zugriff auf Modellressourcen.")
    if not isinstance(name, str) or not name:
        raise ValueError("Der Name einer Modellressource ist ungültig.")
    return reader(name)
