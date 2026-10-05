import 'dart:typed_data';

import 'package:multiple_result/multiple_result.dart';

import '../entities/plugin_failure.dart';

class PluginArchive {
  const PluginArchive({required this.fileName, required this.bytes});

  final String fileName;
  final Uint8List bytes;
}

/// Lässt den Nutzer ein Plugin-ZIP von seinem Gerät wählen.
abstract class PluginArchiveGateway {
  /// [PluginFailure.cancelled], wenn der Nutzer abbricht.
  Future<Result<PluginArchive, PluginFailure>> pick();
}
