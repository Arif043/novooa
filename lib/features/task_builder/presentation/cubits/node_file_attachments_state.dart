import '../../domain/entities/node_attachment.dart';

enum NodeFileAttachmentsStatus { loading, ready, failure }

class NodeFileAttachmentsState {
  const NodeFileAttachmentsState({
    this.status = NodeFileAttachmentsStatus.loading,
    this.files = const [],
    this.message,
  });

  final NodeFileAttachmentsStatus status;
  final List<NodeAttachment> files;
  final String? message;

  NodeFileAttachmentsState copyWith({
    NodeFileAttachmentsStatus? status,
    List<NodeAttachment>? files,
    String? message,
  }) {
    return NodeFileAttachmentsState(
      status: status ?? this.status,
      files: files ?? this.files,
      message: message,
    );
  }
}
