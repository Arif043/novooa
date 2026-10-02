import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/files/domain/repositories/file_settings_repository.dart';
import 'package:syscat2/features/files/domain/usecases/save_file_version_limit.dart';
import 'package:syscat2/features/files/domain/usecases/watch_file_version_limit.dart';
import 'package:syscat2/features/files/presentation/cubits/file_settings_cubit.dart';
import 'package:syscat2/features/files/presentation/cubits/file_settings_state.dart';

void main() {
  test(
    'saveVersionLimit speichert das Limit und übernimmt den Stream',
    () async {
      final repository = _Repository();
      final cubit = FileSettingsCubit(
        WatchFileVersionLimit(repository),
        SaveFileVersionLimit(repository),
      );

      await cubit.load();
      repository.controller.add(10);
      await Future<void>.delayed(Duration.zero);
      await cubit.saveVersionLimit(3);
      await Future<void>.delayed(Duration.zero);

      expect(repository.saved, 3);
      expect(cubit.state, isA<FileSettingsReady>());
      expect((cubit.state as FileSettingsReady).versionLimit, 3);
      await cubit.close();
    },
  );

  test('ungültiges Limit wird nicht gespeichert', () async {
    final repository = _Repository();
    final cubit = FileSettingsCubit(
      WatchFileVersionLimit(repository),
      SaveFileVersionLimit(repository),
    );

    await cubit.load();
    repository.controller.add(10);
    await Future<void>.delayed(Duration.zero);
    await cubit.saveVersionLimit(0);

    expect(repository.saved, isNull);
    expect((cubit.state as FileSettingsReady).message, isNotNull);
    await cubit.close();
  });
}

class _Repository implements FileSettingsRepository {
  final controller = StreamController<int>.broadcast();
  int? saved;

  @override
  Stream<int> watchVersionLimit() => controller.stream;

  @override
  Future<void> saveVersionLimit(int limit) async {
    saved = limit;
    controller.add(limit);
  }
}
