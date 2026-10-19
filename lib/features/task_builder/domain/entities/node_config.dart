import 'node_delegation.dart';
import 'prompt_generation_options.dart';
import 'package:equatable/equatable.dart';
import 'package:syscat2/features/script_packages/domain/entities/python_package.dart';
import 'package:syscat2/features/task_builder/domain/entities/knowledge_attachment.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_attachment.dart';
import 'package:syscat2/features/task_builder/domain/entities/skill_attachment.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_graph.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';

export 'prompt_generation_options.dart';

part 'prompt_node_config.dart';
part 'structured_output_field.dart';
part 'file_attachment_support.dart';
part 'knowledge_attachment_support.dart';
part 'skill_attachment_support.dart';
part 'employee_assignment_support.dart';
part 'string_input_node_config.dart';
part 'script_node_config.dart';
part 'conditional_node_config.dart';
part 'branch_condition.dart';
part 'iterative_refinement_node_config.dart';
part 'human_approval_node_config.dart';
part 'dialog_input_node_config.dart';
part 'media_input_node_config.dart';
part 'model_inference_node_config.dart';
part 'speech_node_config.dart';
part 'for_each_node_config.dart';
part 'write_file_node_config.dart';
part 'read_file_node_config.dart';
part 'read_email_node_config.dart';
part 'read_webhook_node_config.dart';
part 'send_channel_message_node_config.dart';
part 'notification_send_node_config.dart';
part 'document_lookup_node_config.dart';
part 'save_document_node_config.dart';
part 'table_from_collection_node_config.dart';
part 'http_request_node_config.dart';
part 'team_member.dart';
part 'teamwork_node_config.dart';
part 'teamwork_review.dart';

/// Bewusst nicht `sealed`: Konfigurationen von Plugins liegen in ihrem eigenen
/// Ordner (`features/integrations/<plugin>/`) statt als `part` hier. Verdrahtet
/// bleiben sie zentral (Enum, Mapper, Palette, Widget); dafür prüft der Compiler
/// Switches über [NodeConfig] nicht mehr auf Vollständigkeit.
abstract class NodeConfig extends Equatable {
  const NodeConfig();

  WorkflowPrimitive get primitive;

  factory NodeConfig.initial(WorkflowPrimitive primitive) {
    return switch (primitive) {
      .stringInput => StringInputNodeConfig.initial(),
      .script => ScriptNodeConfig.initial(),
      .prompt => PromptNodeConfig.initial(),
      .conditional => ConditionalNodeConfig.initial(),
      .iterativeRefinement => IterativeRefinementNodeConfig.initial(),
      .humanApproval => HumanApprovalNodeConfig.initial(),
      .dialogInput => DialogInputNodeConfig.initial(),
      .mediaInput => MediaInputNodeConfig.initial(),
      .modelInference => ModelInferenceNodeConfig.initial(),
      .textToSpeech => TextToSpeechNodeConfig.initial(),
      .speechToText => SpeechToTextNodeConfig.initial(),
      .forEach => ForEachNodeConfig.initial(),
      .writeFile => WriteFileNodeConfig.initial(),
      .readFile => ReadFileNodeConfig.initial(),
      .documentLookup => DocumentLookupNodeConfig.initial(),
      .saveDocument => SaveDocumentNodeConfig.initial(),
      .tableFromCollection => TableFromCollectionNodeConfig.initial(),
      .readEmail => ReadEmailNodeConfig.initial(),
      .readChannelEvent => ReadChannelEventNodeConfig.initial(),
      .readWebhook => ReadWebhookNodeConfig.initial(),
      .sendChannelMessage => SendChannelMessageNodeConfig.initial(),
      .notificationSend => NotificationSendNodeConfig.initial(),
      .httpRequest => HttpRequestNodeConfig.initial(),
      .teamwork => TeamworkNodeConfig.initial(),
      _ => throw UnimplementedError(),
    };
  }
}
