part of 'node_config.dart';

class TableFromCollectionNodeConfig extends NodeConfig {
  const TableFromCollectionNodeConfig({required this.collectionName});

  final String collectionName;

  factory TableFromCollectionNodeConfig.initial() {
    return const TableFromCollectionNodeConfig(collectionName: '');
  }

  @override
  WorkflowPrimitive get primitive => .tableFromCollection;

  @override
  List<Object?> get props => [collectionName];

  TableFromCollectionNodeConfig copyWith({String? collectionName}) {
    return TableFromCollectionNodeConfig(
      collectionName: collectionName ?? this.collectionName,
    );
  }
}
