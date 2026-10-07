sealed class RuntimeSessionsState {
  const RuntimeSessionsState();
}

final class RuntimeSessionsIdle extends RuntimeSessionsState {
  const RuntimeSessionsIdle();
}

final class RuntimeSessionsRevoking extends RuntimeSessionsState {
  const RuntimeSessionsRevoking();
}

final class RuntimeSessionsRevoked extends RuntimeSessionsState {
  const RuntimeSessionsRevoked(this.count);

  final int count;
}

final class RuntimeSessionsFailed extends RuntimeSessionsState {
  const RuntimeSessionsFailed(this.message);

  final String message;
}
