import '../../domain/entities/node_config.dart';

/// Speichert die flachen Namen der Werte von „Nachricht lesen“; fehlt ein
/// Name, gilt der Standardname.
Map<String, Object?> channelEventOutputNamesToDocument(
  ChannelEventOutputNames names,
) {
  return {
    for (final field in ChannelEventOutputField.values)
      field.name: names.nameOf(field),
  };
}

ChannelEventOutputNames channelEventOutputNamesFrom(Object? value) {
  final data = value is Map ? value : const {};
  var names = const ChannelEventOutputNames();
  for (final field in ChannelEventOutputField.values) {
    final name = data[field.name];
    if (name is String && name.trim().isNotEmpty) {
      names = names.rename(field, name.trim());
    }
  }
  return names;
}
