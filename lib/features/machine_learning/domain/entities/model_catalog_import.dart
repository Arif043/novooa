class ModelCatalogImport {
  const ModelCatalogImport({
    required this.manifestJson,
    required this.artifactBytes,
  });

  final String manifestJson;
  final List<int> artifactBytes;
}
