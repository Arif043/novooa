import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:syscat2/features/language_models/domain/entities/language_model_draft.dart';

/// Markenlogo je Anbieter — einheitlich einfarbig (`onSurfaceVariant`),
/// passend zum zurückhaltenden Icon-Stil des restlichen Studios.
/// `googleAi`/`mistral`/`openRouter`/`ollama` kommen aus `package:simple_icons`
/// (CC0-lizenziert). Für `xAi` gibt es dort kein Icon und `openAiCompatible`
/// steht stellvertretend für den generischen OpenAI-Modus — beide werden
/// stattdessen aus den mitgelieferten SVGs gerendert (`fill="currentColor"`,
/// daher über [SvgTheme.currentColor] eingefärbt statt fest verdrahtet).
Widget providerLogo(
  BuildContext context, {
  required LanguageModelProvider provider,
  required double size,
}) {
  final color = Theme.of(context).colorScheme.onSurfaceVariant;
  final svgAsset = switch (provider) {
    LanguageModelProvider.xAi => 'assets/icons/xai.svg',
    LanguageModelProvider.openAiCompatible => 'assets/icons/openai.svg',
    _ => null,
  };
  if (svgAsset != null) {
    return SvgPicture.asset(
      svgAsset,
      width: size,
      height: size,
      theme: SvgTheme(currentColor: color),
      // Falls die gebündelte SVG-Datei fehlt oder ungültig ist, lieber das
      // neutrale Platzhalter-Icon zeigen als das Dropdown abstürzen zu
      // lassen.
      errorBuilder: (context, error, stackTrace) =>
          Icon(providerIconData(provider), size: size, color: color),
    );
  }
  return Icon(providerIconData(provider), size: size, color: color);
}

IconData providerIconData(LanguageModelProvider provider) {
  return switch (provider) {
    LanguageModelProvider.googleAi => SimpleIcons.googlegemini,
    LanguageModelProvider.mistral => SimpleIcons.mistralai,
    LanguageModelProvider.openRouter => SimpleIcons.openrouter,
    LanguageModelProvider.ollama => SimpleIcons.ollama,
    LanguageModelProvider.xAi ||
    LanguageModelProvider.openAiCompatible => Icons.smart_toy_outlined,
  };
}
