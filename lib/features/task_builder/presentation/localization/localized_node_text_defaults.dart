import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/domain/services/node_text_defaults.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/workflow_primitive_labels.dart';

/// Liefert die Standardtexte in der aktuell gewählten App-Sprache.
class LocalizedNodeTextDefaults implements NodeTextDefaults {
  const LocalizedNodeTextDefaults();

  @override
  String outputBase(WorkflowPrimitive primitive) {
    return switch (primitive) {
      WorkflowPrimitive.stringInput =>
        LocaleKeys.task_builder_output_names_string_input.tr(),
      WorkflowPrimitive.script =>
        LocaleKeys.task_builder_output_names_script.tr(),
      WorkflowPrimitive.prompt =>
        LocaleKeys.task_builder_output_names_prompt.tr(),
      WorkflowPrimitive.conditional =>
        LocaleKeys.task_builder_output_names_conditional.tr(),
      WorkflowPrimitive.iterativeRefinement =>
        LocaleKeys.task_builder_output_names_iterative_refinement.tr(),
      WorkflowPrimitive.writeFile =>
        LocaleKeys.task_builder_output_names_write_file.tr(),
      WorkflowPrimitive.readFile =>
        LocaleKeys.task_builder_output_names_read_file.tr(),
      WorkflowPrimitive.readEmail =>
        LocaleKeys.task_builder_output_names_read_email.tr(),
      WorkflowPrimitive.readChannelEvent =>
        LocaleKeys.task_builder_output_names_read_channel_event.tr(),
      WorkflowPrimitive.readWebhook =>
        LocaleKeys.task_builder_output_names_read_webhook.tr(),
      WorkflowPrimitive.sendChannelMessage =>
        LocaleKeys.task_builder_output_names_send_channel_message.tr(),
      WorkflowPrimitive.notificationSend =>
        LocaleKeys.task_builder_output_names_notification_send.tr(),
      WorkflowPrimitive.toolCall =>
        LocaleKeys.task_builder_output_names_tool_call.tr(),
      WorkflowPrimitive.humanApproval =>
        LocaleKeys.task_builder_output_names_human_approval.tr(),
      WorkflowPrimitive.dialogInput =>
        LocaleKeys.task_builder_output_names_dialog_input.tr(),
      WorkflowPrimitive.mediaInput =>
        LocaleKeys.task_builder_output_names_media_input.tr(),
      WorkflowPrimitive.modelInference =>
        LocaleKeys.task_builder_output_names_model_inference.tr(),
      WorkflowPrimitive.textToSpeech =>
        LocaleKeys.task_builder_output_names_text_to_speech.tr(),
      WorkflowPrimitive.speechToText =>
        LocaleKeys.task_builder_output_names_speech_to_text.tr(),
      WorkflowPrimitive.forEach =>
        LocaleKeys.task_builder_output_names_for_each.tr(),
      WorkflowPrimitive.documentLookup =>
        LocaleKeys.task_builder_output_names_document_lookup.tr(),
      WorkflowPrimitive.saveDocument =>
        LocaleKeys.task_builder_output_names_save_document.tr(),
      WorkflowPrimitive.tableFromCollection =>
        LocaleKeys.task_builder_output_names_table_from_collection.tr(),
      WorkflowPrimitive.validation =>
        LocaleKeys.task_builder_output_names_validation.tr(),
      WorkflowPrimitive.httpRequest =>
        LocaleKeys.task_builder_output_names_http_request.tr(),
      WorkflowPrimitive.plugin =>
        LocaleKeys.task_builder_output_names_plugin.tr(),
    };
  }

  /// Die Schlüssel kommen aus Daten (auch aus Plugins), deshalb dynamisch
  /// statt über `LocaleKeys`; unbekannte Plugin-Schlüssel werden nur
  /// großgeschrieben.
  @override
  String outputFieldBase(String fieldKey) {
    final translationKey = 'task_builder.output_field_names.$fieldKey';
    if (trExists(translationKey)) return translationKey.tr();
    return fieldKey.isEmpty
        ? fieldKey
        : fieldKey[0].toUpperCase() + fieldKey.substring(1);
  }

  @override
  String decisionOutputBase() =>
      LocaleKeys.task_builder_output_names_prompt_decision.tr();

  @override
  String sendOutputBase(ChannelEventKind kind) {
    return switch (kind) {
      ChannelEventKind.email =>
        LocaleKeys.task_builder_send_output_names_email.tr(),
      ChannelEventKind.whatsapp =>
        LocaleKeys.task_builder_send_output_names_whatsapp.tr(),
      ChannelEventKind.sms =>
        LocaleKeys.task_builder_send_output_names_sms.tr(),
      ChannelEventKind.telegram =>
        LocaleKeys.task_builder_send_output_names_telegram.tr(),
      ChannelEventKind.instagram =>
        LocaleKeys.task_builder_send_output_names_instagram.tr(),
    };
  }

  @override
  String title(WorkflowPrimitive primitive) => primitive.label;

  @override
  String description(WorkflowPrimitive primitive) => primitive.description;

  @override
  String readChannelTitle(ChannelEventKind kind) {
    return switch (kind) {
      ChannelEventKind.email =>
        LocaleKeys.task_builder_channels_email_read_title.tr(),
      ChannelEventKind.whatsapp =>
        LocaleKeys.task_builder_channels_whatsapp_read_title.tr(),
      ChannelEventKind.sms =>
        LocaleKeys.task_builder_channels_sms_read_title.tr(),
      ChannelEventKind.telegram =>
        LocaleKeys.task_builder_channels_telegram_read_title.tr(),
      ChannelEventKind.instagram =>
        LocaleKeys.task_builder_channels_instagram_read_title.tr(),
    };
  }

  @override
  String readChannelDescription(ChannelEventKind kind) {
    return switch (kind) {
      ChannelEventKind.email =>
        LocaleKeys.task_builder_channels_email_read_description.tr(),
      ChannelEventKind.whatsapp =>
        LocaleKeys.task_builder_channels_whatsapp_read_description.tr(),
      ChannelEventKind.sms =>
        LocaleKeys.task_builder_channels_sms_read_description.tr(),
      ChannelEventKind.telegram =>
        LocaleKeys.task_builder_channels_telegram_read_description.tr(),
      ChannelEventKind.instagram =>
        LocaleKeys.task_builder_channels_instagram_read_description.tr(),
    };
  }

  @override
  String sendChannelTitle(ChannelEventKind kind) {
    return switch (kind) {
      ChannelEventKind.email =>
        LocaleKeys.task_builder_channels_email_send_title.tr(),
      ChannelEventKind.whatsapp =>
        LocaleKeys.task_builder_channels_whatsapp_send_title.tr(),
      ChannelEventKind.sms =>
        LocaleKeys.task_builder_channels_sms_send_title.tr(),
      ChannelEventKind.telegram =>
        LocaleKeys.task_builder_channels_telegram_send_title.tr(),
      ChannelEventKind.instagram =>
        LocaleKeys.task_builder_channels_instagram_send_title.tr(),
    };
  }

  @override
  String sendChannelDescription(ChannelEventKind kind) {
    return switch (kind) {
      ChannelEventKind.email =>
        LocaleKeys.task_builder_channels_email_send_description.tr(),
      ChannelEventKind.whatsapp =>
        LocaleKeys.task_builder_channels_whatsapp_send_description.tr(),
      ChannelEventKind.sms =>
        LocaleKeys.task_builder_channels_sms_send_description.tr(),
      ChannelEventKind.telegram =>
        LocaleKeys.task_builder_channels_telegram_send_description.tr(),
      ChannelEventKind.instagram =>
        LocaleKeys.task_builder_channels_instagram_send_description.tr(),
    };
  }
}
