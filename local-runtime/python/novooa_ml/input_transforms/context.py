class ImageTransformContext:
    def __init__(self, image, numpy, image_module):
        self.image = image
        self.numpy = numpy
        self.image_module = image_module
        self.tensor = None
        self.layout = "channelsLast"

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
