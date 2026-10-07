/// Was ein Modell löst — unabhängig vom Verfahren. Die Schlüssel entsprechen den Werten der
/// Runtime (Pipeline-Tags von Hugging Face).
enum ModelTask {
  textToSpeech('text-to-speech'),
  automaticSpeechRecognition('automatic-speech-recognition'),
  audioClassification('audio-classification'),
  imageClassification('image-classification'),
  objectDetection('object-detection'),
  imageSegmentation('image-segmentation'),
  imageToText('image-to-text'),
  textClassification('text-classification'),
  tokenClassification('token-classification'),
  translation('translation'),
  featureExtraction('feature-extraction'),
  other('other');

  const ModelTask(this.key);

  final String key;

  /// Unbekannte Schlüssel (neuere Runtime) landen unter „Sonstige“, statt die App zu brechen.
  static ModelTask fromKey(Object? key) => ModelTask.values.firstWhere(
    (task) => task.key == key,
    orElse: () => ModelTask.other,
  );
}
