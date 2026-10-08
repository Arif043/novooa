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
