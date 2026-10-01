sealed class FileSettingsState {
  const FileSettingsState();
}

class FileSettingsLoading extends FileSettingsState {
  const FileSettingsLoading();
}

class FileSettingsReady extends FileSettingsState {
  const FileSettingsReady({
    required this.versionLimit,
    this.isSaving = false,
    this.message,
  });

  final int versionLimit;
  final bool isSaving;
  final String? message;

  FileSettingsReady copyWith({bool? isSaving, String? message}) {
    return FileSettingsReady(
      versionLimit: versionLimit,
      isSaving: isSaving ?? this.isSaving,
      message: message,
    );
  }
}

class FileSettingsFailure extends FileSettingsState {
  const FileSettingsFailure(this.message);

  final String message;
}
