part of 'node_config.dart';

class NotificationSendNodeConfig extends NodeConfig {
  const NotificationSendNodeConfig({this.title = '', required this.message});

  final String title;
  final String message;

  factory NotificationSendNodeConfig.initial() {
    return const NotificationSendNodeConfig(message: '');
  }

  @override
  WorkflowPrimitive get primitive => WorkflowPrimitive.notificationSend;

  @override
  List<Object?> get props => [title, message];

  NotificationSendNodeConfig copyWith({String? title, String? message}) {
    return NotificationSendNodeConfig(
      title: title ?? this.title,
      message: message ?? this.message,
    );
  }
}
