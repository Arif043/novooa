import 'model_task_area.dart';

export 'model_task_area.dart';

/// Was ein Modell löst — unabhängig vom Verfahren. Die Schlüssel entsprechen den Werten der
/// Runtime (überwiegend Pipeline-Tags von Hugging Face). Generative Aufgaben fehlen bewusst: Sie
/// laufen über Sprachmodelle im Prompt-Baustein.
enum ModelTask {
  imageClassification('image-classification', ModelTaskArea.imageVideo),
  objectDetection('object-detection', ModelTaskArea.imageVideo),
  imageSegmentation('image-segmentation', ModelTaskArea.imageVideo),
  opticalCharacterRecognition(
    'optical-character-recognition',
    ModelTaskArea.imageVideo,
  ),
  documentQuestionAnswering(
    'document-question-answering',
    ModelTaskArea.imageVideo,
  ),
  depthEstimation('depth-estimation', ModelTaskArea.imageVideo),
  keypointDetection('keypoint-detection', ModelTaskArea.imageVideo),
  zeroShotImageClassification(
    'zero-shot-image-classification',
    ModelTaskArea.imageVideo,
  ),
  imageToImage('image-to-image', ModelTaskArea.imageVideo),
  videoClassification('video-classification', ModelTaskArea.imageVideo),
  textToSpeech('text-to-speech', ModelTaskArea.audio),
  automaticSpeechRecognition(
    'automatic-speech-recognition',
    ModelTaskArea.audio,
  ),
  audioClassification('audio-classification', ModelTaskArea.audio),
  voiceActivityDetection('voice-activity-detection', ModelTaskArea.audio),
  speakerDiarization('speaker-diarization', ModelTaskArea.audio),
  audioToAudio('audio-to-audio', ModelTaskArea.audio),
  textClassification('text-classification', ModelTaskArea.text),
  tokenClassification('token-classification', ModelTaskArea.text),
  questionAnswering('question-answering', ModelTaskArea.text),
  zeroShotClassification('zero-shot-classification', ModelTaskArea.text),
  sentenceSimilarity('sentence-similarity', ModelTaskArea.text),
  featureExtraction('feature-extraction', ModelTaskArea.text),
  tabularClassification('tabular-classification', ModelTaskArea.data),
  tabularRegression('tabular-regression', ModelTaskArea.data),
  timeSeriesForecasting('time-series-forecasting', ModelTaskArea.data),
  anomalyDetection('anomaly-detection', ModelTaskArea.data),
  clustering('clustering', ModelTaskArea.data),
  other('other', ModelTaskArea.other);

  const ModelTask(this.key, this.area);

  final String key;
  final ModelTaskArea area;

  /// Unbekannte Schlüssel (neuere Runtime) landen unter „Sonstige“, statt die App zu brechen.
  static ModelTask fromKey(Object? key) => ModelTask.values.firstWhere(
    (task) => task.key == key,
    orElse: () => ModelTask.other,
  );
}
