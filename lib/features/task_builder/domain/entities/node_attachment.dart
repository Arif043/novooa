import 'package:equatable/equatable.dart';

class NodeAttachment extends Equatable {
  const NodeAttachment({
    required this.id,
    required this.storagePath,
    required this.generation,
    required this.displayName,
    required this.contentType,
    required this.sizeBytes,
  });

  final String id;
  final String storagePath;
  final String generation;
  final String displayName;
  final String contentType;
  final int sizeBytes;

  @override
  List<Object?> get props {
    return [id, storagePath, generation, displayName, contentType, sizeBytes];
  }

  NodeAttachment copyWith({
    String? id,
    String? storagePath,
    String? generation,
    String? displayName,
    String? contentType,
    int? sizeBytes,
  }) {
    return NodeAttachment(
      id: id ?? this.id,
      storagePath: storagePath ?? this.storagePath,
      generation: generation ?? this.generation,
      displayName: displayName ?? this.displayName,
      contentType: contentType ?? this.contentType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
    );
  }
}
