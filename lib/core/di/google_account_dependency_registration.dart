import 'package:get_it/get_it.dart';
import 'package:syscat2/core/network/workspace_api_client.dart';
import 'package:syscat2/core/network/workspace_realtime_channel.dart';
import 'package:syscat2/features/google_accounts/domain/repositories/google_account_repository.dart';
import 'package:syscat2/features/google_accounts/domain/usecases/begin_google_authorization.dart';
import 'package:syscat2/features/google_accounts/domain/usecases/watch_google_accounts.dart';
import 'package:syscat2/features/google_accounts/infrastructure/repositories/local_google_account_repository.dart';
import 'package:syscat2/features/google_accounts/presentation/cubits/google_accounts_cubit.dart';

/// Google-Konten der Runtime: Repository, Use Cases und Cubit.
void registerGoogleAccountDependencies(GetIt locator) {
  locator
    ..registerLazySingleton<GoogleAccountRepository>(
      () => LocalGoogleAccountRepository(
        locator<WorkspaceApiClient>(),
        locator<WorkspaceRealtimeChannel>(),
      ),
    )
    ..registerLazySingleton(
      () => WatchGoogleAccounts(locator<GoogleAccountRepository>()),
    )
    ..registerLazySingleton(
      () => BeginGoogleAuthorization(locator<GoogleAccountRepository>()),
    )
    ..registerFactory(
      () => GoogleAccountsCubit(
        locator<WatchGoogleAccounts>(),
        locator<BeginGoogleAuthorization>(),
      ),
    );
}
