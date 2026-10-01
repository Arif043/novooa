import 'package:multiple_result/multiple_result.dart';

import '../entities/transfer_archive.dart';
import '../entities/transfer_failure.dart';

/// Zugriff auf das Dateisystem der Nutzer:innen (Speichern-/Öffnen-Dialog).
abstract interface class TransferFileGateway {
  Future<Result<Unit, TransferFailure>> save(TransferArchive archive);

  Future<Result<TransferArchive, TransferFailure>> pick();
}
