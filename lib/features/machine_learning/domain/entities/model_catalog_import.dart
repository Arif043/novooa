class ModelCatalogImport {
  const ModelCatalogImport({
    required this.manifestJson,
    required this.artifactLength,
    required this.openArtifact,
  });

  final String manifestJson;
  final int artifactLength;
  final Stream<List<int>> Function() openArtifact;
}
