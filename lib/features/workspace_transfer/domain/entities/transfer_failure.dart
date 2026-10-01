enum TransferFailureKind { cancelled, failed }

class TransferFailure {
  const TransferFailure(this.kind, this.message);

  const TransferFailure.cancelled()
    : kind = TransferFailureKind.cancelled,
      message = 'Abgebrochen.';

  final TransferFailureKind kind;
  final String message;

  bool get isCancelled => kind == TransferFailureKind.cancelled;
}
