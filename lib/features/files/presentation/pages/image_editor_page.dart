import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../widgets/detail/image_editor_i18n.dart';
import '../widgets/detail/image_editor_theme.dart';

/// Bearbeitbare Bildformate: Das Ergebnis bleibt im Format der Datei, damit
/// Name, Endung und Typ zusammenpassen.
enum EditableImageFormat {
  png(OutputFormat.png),
  jpeg(OutputFormat.jpg);

  const EditableImageFormat(this.outputFormat);

  final OutputFormat outputFormat;

  static EditableImageFormat? of(String contentType) {
    return switch (contentType.toLowerCase()) {
      'image/png' => EditableImageFormat.png,
      'image/jpeg' || 'image/jpg' => EditableImageFormat.jpeg,
      _ => null,
    };
  }
}

/// Bildeditor im Vollbild. Liefert die bearbeiteten Bytes oder `null` bei
/// Abbruch.
class ImageEditorPage extends StatelessWidget {
  const ImageEditorPage({super.key, required this.bytes, required this.format});

  final Uint8List bytes;
  final EditableImageFormat format;

  static Future<Uint8List?> open(
    BuildContext context, {
    required Uint8List bytes,
    required EditableImageFormat format,
  }) {
    // Über der App-Leiste der Shell: der Editor braucht die ganze Fläche.
    return Navigator.of(context, rootNavigator: true).push<Uint8List>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ImageEditorPage(bytes: bytes, format: format),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);
    var completed = false;
    return ProImageEditor.memory(
      bytes,
      configs: ProImageEditorConfigs(
        theme: imageEditorTheme(Theme.of(context).colorScheme),
        i18n: imageEditorI18n(),
        mainEditor: const MainEditorConfigs(
          tools: [
            SubEditorMode.cropRotate,
            SubEditorMode.tune,
            SubEditorMode.filter,
            SubEditorMode.paint,
            SubEditorMode.text,
            SubEditorMode.blur,
          ],
        ),
        imageGeneration: ImageGenerationConfigs(
          outputFormat: format.outputFormat,
          jpegQuality: 92,
          // Keine Verkleinerung: Die neue Version soll die Auflösung behalten.
          maxOutputSize: const Size.square(8192),
        ),
      ),
      callbacks: ProImageEditorCallbacks(
        onImageEditingComplete: (edited) async {
          completed = true;
          navigator.pop(edited);
        },
        onCloseEditor: (_) {
          if (!completed) navigator.pop();
        },
      ),
    );
  }
}
