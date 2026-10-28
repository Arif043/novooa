import 'package:easy_localization/easy_localization.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

/// Die sichtbaren Kerntexte des Bildeditors in der App-Sprache; seltene
/// Texte bleiben beim englischen Standard des Pakets.
I18n imageEditorI18n() {
  final back = LocaleKeys.files_editor_back.tr();
  final done = LocaleKeys.files_editor_done.tr();
  final cancel = LocaleKeys.files_editor_cancel.tr();
  final undo = LocaleKeys.files_editor_undo.tr();
  final redo = LocaleKeys.files_editor_redo.tr();
  return I18n(
    cancel: cancel,
    undo: undo,
    redo: redo,
    done: done,
    remove: LocaleKeys.files_editor_remove.tr(),
    doneLoadingMsg: LocaleKeys.files_editor_applying.tr(),
    paintEditor: I18nPaintEditor(
      bottomNavigationBarText: LocaleKeys.files_editor_paint.tr(),
      back: back,
      done: done,
      cancel: cancel,
      undo: undo,
      redo: redo,
    ),
    textEditor: I18nTextEditor(
      bottomNavigationBarText: LocaleKeys.files_editor_text.tr(),
      inputHintText: LocaleKeys.files_editor_text_hint.tr(),
      back: back,
      done: done,
    ),
    cropRotateEditor: I18nCropRotateEditor(
      bottomNavigationBarText: LocaleKeys.files_editor_crop.tr(),
      rotate: LocaleKeys.files_editor_rotate.tr(),
      flip: LocaleKeys.files_editor_flip.tr(),
      ratio: LocaleKeys.files_editor_ratio.tr(),
      back: back,
      done: done,
      cancel: cancel,
      undo: undo,
      redo: redo,
    ),
    tuneEditor: I18nTuneEditor(
      bottomNavigationBarText: LocaleKeys.files_editor_tune.tr(),
      brightness: LocaleKeys.files_editor_brightness.tr(),
      contrast: LocaleKeys.files_editor_contrast.tr(),
      saturation: LocaleKeys.files_editor_saturation.tr(),
      back: back,
      done: done,
    ),
    filterEditor: I18nFilterEditor(
      bottomNavigationBarText: LocaleKeys.files_editor_filter.tr(),
      back: back,
      done: done,
    ),
    blurEditor: I18nBlurEditor(
      bottomNavigationBarText: LocaleKeys.files_editor_blur.tr(),
      back: back,
      done: done,
    ),
  );
}
