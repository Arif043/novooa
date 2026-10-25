import 'package:get_it/get_it.dart';

import '../../features/auth/domain/repositories/password_repository.dart';
import '../../features/auth/domain/usecases/set_new_password.dart';
import '../../features/auth/infrastructure/repositories/http_password_repository.dart';
import '../../features/settings/presentation/cubits/password_settings_cubit.dart';
import '../network/workspace_api_client.dart';

void registerPasswordSettingsDependencies(GetIt locator) {
  locator
    ..registerLazySingleton<PasswordRepository>(
      () => HttpPasswordRepository(locator<WorkspaceApiClient>()),
    )
    ..registerLazySingleton(() => SetNewPassword(locator<PasswordRepository>()))
    ..registerFactory(() => PasswordSettingsCubit(locator<SetNewPassword>()));
}
