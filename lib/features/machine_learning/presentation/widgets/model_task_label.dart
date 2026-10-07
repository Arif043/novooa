import 'package:flutter/material.dart';

import '../../domain/entities/model_task.dart';

/// Deutsche Bezeichnung und Symbol einer Modellaufgabe für Chips und Listen.
extension ModelTaskLabel on ModelTask {
  String get label => switch (this) {
    ModelTask.textToSpeech => 'Text vorlesen',
    ModelTask.automaticSpeechRecognition => 'Sprache erkennen',
    ModelTask.audioClassification => 'Geräusche erkennen',
    ModelTask.imageClassification => 'Bilder klassifizieren',
    ModelTask.objectDetection => 'Objekte erkennen',
    ModelTask.imageSegmentation => 'Bilder segmentieren',
    ModelTask.imageToText => 'Text aus Bildern',
    ModelTask.textClassification => 'Texte klassifizieren',
    ModelTask.tokenClassification => 'Begriffe erkennen',
    ModelTask.translation => 'Übersetzen',
    ModelTask.featureExtraction => 'Merkmale berechnen',
    ModelTask.other => 'Sonstige',
  };

  IconData get icon => switch (this) {
    ModelTask.textToSpeech => Icons.record_voice_over_outlined,
    ModelTask.automaticSpeechRecognition => Icons.mic_none_outlined,
    ModelTask.audioClassification => Icons.graphic_eq,
    ModelTask.imageClassification => Icons.image_outlined,
    ModelTask.objectDetection => Icons.center_focus_strong_outlined,
    ModelTask.imageSegmentation => Icons.auto_awesome_mosaic_outlined,
    ModelTask.imageToText => Icons.document_scanner_outlined,
    ModelTask.textClassification => Icons.label_outline,
    ModelTask.tokenClassification => Icons.text_fields,
    ModelTask.translation => Icons.translate,
    ModelTask.featureExtraction => Icons.scatter_plot_outlined,
    ModelTask.other => Icons.memory_outlined,
  };
}

const _languageNames = {
  'de': 'Deutsch',
  'en': 'Englisch',
  'fr': 'Französisch',
  'es': 'Spanisch',
  'it': 'Italienisch',
  'nl': 'Niederländisch',
  'pl': 'Polnisch',
  'pt': 'Portugiesisch',
  'tr': 'Türkisch',
  'ru': 'Russisch',
  'uk': 'Ukrainisch',
  'ar': 'Arabisch',
  'zh': 'Chinesisch',
  'ja': 'Japanisch',
};

/// „Deutsch“ für `de`, „Englisch (GB)“ für `en-GB`, sonst der Code selbst.
String languageLabel(String code) {
  final parts = code.split('-');
  final name = _languageNames[parts.first.toLowerCase()];
  if (name == null) return code.toUpperCase();
  return parts.length == 1 ? name : '$name (${parts.sublist(1).join('-')})';
}
