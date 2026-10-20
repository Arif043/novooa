import 'package:get_it/get_it.dart';

import '../../features/runtime_users/domain/repositories/runtime_user_repository.dart';
import '../../features/runtime_users/domain/usecases/runtime_user_use_cases.dart';
import '../../features/runtime_users/infrastructure/repositories/local_runtime_user_repository.dart';
import '../../features/runtime_users/presentation/cubits/current_runtime_user_cubit.dart';
import '../../features/runtime_users/presentation/cubits/runtime_users_cubit.dart';
import '../network/workspace_api_client.dart';
import '../network/workspace_realtime_channel.dart';

/// Konten mit Rollen gibt es nur in der lokalen Runtime.
void configureStandaloneRuntimeUsersDependencies(GetIt locator) {
  locator
    ..registerLazySingleton<RuntimeUserRepository>(
      () => LocalRuntimeUserRepository(
        locator<WorkspaceApiClient>(),
        locator<WorkspaceRealtimeChannel>(),
      ),
    )
    ..registerLazySingleton(
      () => LoadCurrentRuntimeUser(locator<RuntimeUserRepository>()),
    )
    ..registerLazySingleton(
      () => WatchRuntimeUsers(locator<RuntimeUserRepository>()),
    )
    ..registerLazySingleton(
      () => CreateRuntimeUser(locator<RuntimeUserRepository>()),
    )
    ..registerLazySingleton(
      () => ChangeRuntimeUserRole(locator<RuntimeUserRepository>()),
    )
    ..registerLazySingleton(
      () => ResetRuntimeUserPassword(locator<RuntimeUserRepository>()),
    )
    ..registerLazySingleton(
      () => DeleteRuntimeUser(locator<RuntimeUserRepository>()),
    )
    ..registerLazySingleton(
      () => CurrentRuntimeUserCubit(locator<LoadCurrentRuntimeUser>())..load(),
      dispose: (cubit) => cubit.close(),
    )
    ..registerFactory(
      () => RuntimeUsersCubit(
        locator<WatchRuntimeUsers>(),
        locator<CreateRuntimeUser>(),
        locator<ChangeRuntimeUserRole>(),
        locator<ResetRuntimeUserPassword>(),
        locator<DeleteRuntimeUser>(),
      ),
    );
}
