import 'package:flutter/material.dart';

import '../../domain/entities/model_task.dart';

/// Deutsche Bezeichnung und Symbol einer Modellaufgabe für Chips und Listen.
extension ModelTaskLabel on ModelTask {
  String get label => switch (this) {
    ModelTask.imageClassification => 'Bilder klassifizieren',
    ModelTask.objectDetection => 'Objekte erkennen',
    ModelTask.imageSegmentation => 'Bilder segmentieren',
    ModelTask.opticalCharacterRecognition => 'Text in Bildern erkennen',
    ModelTask.documentQuestionAnswering => 'Dokumente auslesen',
    ModelTask.depthEstimation => 'Tiefe schätzen',
    ModelTask.keypointDetection => 'Körperhaltung erkennen',
    ModelTask.zeroShotImageClassification => 'Bilder ohne Training zuordnen',
    ModelTask.imageToImage => 'Bilder verbessern',
    ModelTask.videoClassification => 'Videos klassifizieren',
    ModelTask.textToSpeech => 'Text vorlesen',
    ModelTask.automaticSpeechRecognition => 'Sprache erkennen',
    ModelTask.audioClassification => 'Geräusche erkennen',
    ModelTask.voiceActivityDetection => 'Sprachaktivität erkennen',
    ModelTask.speakerDiarization => 'Sprecher unterscheiden',
    ModelTask.audioToAudio => 'Audio verbessern',
    ModelTask.textClassification => 'Texte klassifizieren',
    ModelTask.tokenClassification => 'Begriffe erkennen',
    ModelTask.questionAnswering => 'Fragen beantworten',
    ModelTask.zeroShotClassification => 'Texte ohne Training zuordnen',
    ModelTask.sentenceSimilarity => 'Texte vergleichen',
    ModelTask.featureExtraction => 'Merkmale berechnen',
    ModelTask.tabularClassification => 'Tabellen klassifizieren',
    ModelTask.tabularRegression => 'Werte vorhersagen',
    ModelTask.timeSeriesForecasting => 'Zeitreihen vorhersagen',
    ModelTask.anomalyDetection => 'Anomalien erkennen',
    ModelTask.clustering => 'Daten gruppieren',
    ModelTask.other => 'Sonstige',
  };

  IconData get icon => switch (this) {
    ModelTask.imageClassification => Icons.image_outlined,
    ModelTask.objectDetection => Icons.center_focus_strong_outlined,
    ModelTask.imageSegmentation => Icons.auto_awesome_mosaic_outlined,
    ModelTask.opticalCharacterRecognition => Icons.document_scanner_outlined,
    ModelTask.documentQuestionAnswering => Icons.receipt_long_outlined,
    ModelTask.depthEstimation => Icons.layers_outlined,
    ModelTask.keypointDetection => Icons.accessibility_new,
    ModelTask.zeroShotImageClassification => Icons.collections_outlined,
    ModelTask.imageToImage => Icons.auto_fix_high_outlined,
    ModelTask.videoClassification => Icons.movie_outlined,
    ModelTask.textToSpeech => Icons.record_voice_over_outlined,
    ModelTask.automaticSpeechRecognition => Icons.mic_none_outlined,
    ModelTask.audioClassification => Icons.graphic_eq,
    ModelTask.voiceActivityDetection => Icons.settings_voice_outlined,
    ModelTask.speakerDiarization => Icons.groups_outlined,
    ModelTask.audioToAudio => Icons.equalizer,
    ModelTask.textClassification => Icons.label_outline,
    ModelTask.tokenClassification => Icons.text_fields,
    ModelTask.questionAnswering => Icons.question_answer_outlined,
    ModelTask.zeroShotClassification => Icons.sell_outlined,
    ModelTask.sentenceSimilarity => Icons.compare_arrows,
    ModelTask.featureExtraction => Icons.scatter_plot_outlined,
    ModelTask.tabularClassification => Icons.table_chart_outlined,
    ModelTask.tabularRegression => Icons.trending_up,
    ModelTask.timeSeriesForecasting => Icons.show_chart,
    ModelTask.anomalyDetection => Icons.warning_amber_outlined,
    ModelTask.clustering => Icons.bubble_chart_outlined,
    ModelTask.other => Icons.memory_outlined,
  };
}

extension ModelTaskAreaLabel on ModelTaskArea {
  String get label => switch (this) {
    ModelTaskArea.imageVideo => 'Bild & Video',
    ModelTaskArea.audio => 'Audio',
    ModelTaskArea.text => 'Text',
    ModelTaskArea.data => 'Daten & Zeitreihen',
    ModelTaskArea.other => 'Sonstige',
  };

  IconData get icon => switch (this) {
    ModelTaskArea.imageVideo => Icons.photo_camera_outlined,
    ModelTaskArea.audio => Icons.headphones_outlined,
    ModelTaskArea.text => Icons.notes,
    ModelTaskArea.data => Icons.insights_outlined,
    ModelTaskArea.other => Icons.memory_outlined,
  };
}
