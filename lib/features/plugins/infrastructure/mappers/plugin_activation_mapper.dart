import '../../domain/entities/plugin_activation.dart';

/// Übersetzt `GET /v1/plugins` und `PUT /v1/plugins/:id`.
abstract final class PluginActivationMapper {
  static List<PluginActivation> listFrom(Map<String, Object?> response) {
    final items = response['items'];
    if (items is! List) return const [];
    return items
        .whereType<Map<String, Object?>>()
        .map(activationFrom)
        .nonNulls
        .toList();
  }

  static PluginActivation? activationFrom(Map<String, Object?> json) {
    final id = json['id'];
    if (id is! String || id.isEmpty) return null;
    final enabledAt = json['enabledAt'];
    return PluginActivation(
      id: PluginId(id),
      isEnabled: json['enabled'] == true,
      enabledAt: enabledAt is String ? DateTime.tryParse(enabledAt) : null,
    );
  }
}
