import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';

extension WorkflowPrimitiveLabels on WorkflowPrimitive {
  String get label {
    return switch (this) {
      WorkflowPrimitive.stringInput =>
        LocaleKeys.task_builder_primitives_string_input_label.tr(),
      WorkflowPrimitive.script =>
        LocaleKeys.task_builder_primitives_script_label.tr(),
      WorkflowPrimitive.prompt =>
        LocaleKeys.task_builder_primitives_prompt_label.tr(),
      WorkflowPrimitive.conditional =>
        LocaleKeys.task_builder_primitives_conditional_label.tr(),
      WorkflowPrimitive.iterativeRefinement =>
        LocaleKeys.task_builder_primitives_iterative_refinement_label.tr(),
      WorkflowPrimitive.writeFile =>
        LocaleKeys.task_builder_primitives_write_file_label.tr(),
      WorkflowPrimitive.readFile =>
        LocaleKeys.task_builder_primitives_read_file_label.tr(),
      WorkflowPrimitive.readEmail =>
        LocaleKeys.task_builder_primitives_read_email_label.tr(),
      WorkflowPrimitive.readChannelEvent =>
        LocaleKeys.task_builder_primitives_read_channel_event_label.tr(),
      WorkflowPrimitive.readWebhook =>
        LocaleKeys.task_builder_primitives_read_webhook_label.tr(),
      WorkflowPrimitive.sendChannelMessage =>
        LocaleKeys.task_builder_primitives_send_channel_message_label.tr(),
      WorkflowPrimitive.notificationSend =>
        LocaleKeys.task_builder_primitives_notification_send_label.tr(),
      WorkflowPrimitive.toolCall =>
        LocaleKeys.task_builder_primitives_tool_call_label.tr(),
      WorkflowPrimitive.humanApproval =>
        LocaleKeys.task_builder_primitives_human_approval_label.tr(),
      WorkflowPrimitive.dialogInput =>
        LocaleKeys.task_builder_primitives_dialog_input_label.tr(),
      WorkflowPrimitive.mediaInput =>
        LocaleKeys.task_builder_primitives_media_input_label.tr(),
      WorkflowPrimitive.modelInference =>
        LocaleKeys.task_builder_primitives_model_inference_label.tr(),
      WorkflowPrimitive.textToSpeech =>
        LocaleKeys.task_builder_primitives_text_to_speech_label.tr(),
      WorkflowPrimitive.speechToText =>
        LocaleKeys.task_builder_primitives_speech_to_text_label.tr(),
      WorkflowPrimitive.forEach =>
        LocaleKeys.task_builder_primitives_for_each_label.tr(),
      WorkflowPrimitive.documentLookup =>
        LocaleKeys.task_builder_primitives_document_lookup_label.tr(),
      WorkflowPrimitive.saveDocument =>
        LocaleKeys.task_builder_primitives_save_document_label.tr(),
      WorkflowPrimitive.tableFromCollection =>
        LocaleKeys.task_builder_primitives_table_from_collection_label.tr(),
      WorkflowPrimitive.validation =>
        LocaleKeys.task_builder_primitives_validation_label.tr(),
      WorkflowPrimitive.httpRequest =>
        LocaleKeys.task_builder_primitives_http_request_label.tr(),
      WorkflowPrimitive.plugin =>
        LocaleKeys.task_builder_primitives_plugin_label.tr(),
    };
  }

  String get description {
    return switch (this) {
      WorkflowPrimitive.stringInput =>
        LocaleKeys.task_builder_primitives_string_input_description.tr(),
      WorkflowPrimitive.script =>
        LocaleKeys.task_builder_primitives_script_description.tr(),
      WorkflowPrimitive.prompt =>
        LocaleKeys.task_builder_primitives_prompt_description.tr(),
      WorkflowPrimitive.conditional =>
        LocaleKeys.task_builder_primitives_conditional_description.tr(),
      WorkflowPrimitive.iterativeRefinement =>
        LocaleKeys.task_builder_primitives_iterative_refinement_description
            .tr(),
      WorkflowPrimitive.writeFile =>
        LocaleKeys.task_builder_primitives_write_file_description.tr(),
      WorkflowPrimitive.readFile =>
        LocaleKeys.task_builder_primitives_read_file_description.tr(),
      WorkflowPrimitive.readEmail =>
        LocaleKeys.task_builder_primitives_read_email_description.tr(),
      WorkflowPrimitive.readChannelEvent =>
        LocaleKeys.task_builder_primitives_read_channel_event_description.tr(),
      WorkflowPrimitive.readWebhook =>
        LocaleKeys.task_builder_primitives_read_webhook_description.tr(),
      WorkflowPrimitive.sendChannelMessage =>
        LocaleKeys.task_builder_primitives_send_channel_message_description
            .tr(),
      WorkflowPrimitive.notificationSend =>
        LocaleKeys.task_builder_primitives_notification_send_description.tr(),
      WorkflowPrimitive.toolCall =>
        LocaleKeys.task_builder_primitives_tool_call_description.tr(),
      WorkflowPrimitive.humanApproval =>
        LocaleKeys.task_builder_primitives_human_approval_description.tr(),
      WorkflowPrimitive.dialogInput =>
        LocaleKeys.task_builder_primitives_dialog_input_description.tr(),
      WorkflowPrimitive.mediaInput =>
        LocaleKeys.task_builder_primitives_media_input_description.tr(),
      WorkflowPrimitive.modelInference =>
        LocaleKeys.task_builder_primitives_model_inference_description.tr(),
      WorkflowPrimitive.textToSpeech =>
        LocaleKeys.task_builder_primitives_text_to_speech_description.tr(),
      WorkflowPrimitive.speechToText =>
        LocaleKeys.task_builder_primitives_speech_to_text_description.tr(),
      WorkflowPrimitive.forEach =>
        LocaleKeys.task_builder_primitives_for_each_description.tr(),
      WorkflowPrimitive.documentLookup =>
        LocaleKeys.task_builder_primitives_document_lookup_description.tr(),
      WorkflowPrimitive.saveDocument =>
        LocaleKeys.task_builder_primitives_save_document_description.tr(),
      WorkflowPrimitive.tableFromCollection =>
        LocaleKeys.task_builder_primitives_table_from_collection_description
            .tr(),
      WorkflowPrimitive.validation =>
        LocaleKeys.task_builder_primitives_validation_description.tr(),
      WorkflowPrimitive.httpRequest =>
        LocaleKeys.task_builder_primitives_http_request_description.tr(),
      WorkflowPrimitive.plugin =>
        LocaleKeys.task_builder_primitives_plugin_description.tr(),
    };
  }
}
