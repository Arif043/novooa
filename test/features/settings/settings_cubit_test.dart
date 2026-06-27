import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/core/entities/unique_id.dart';
import 'package:syscat2/features/auth/domain/entities/auth_failure.dart';
import 'package:syscat2/features/auth/domain/entities/auth_user.dart';
import 'package:syscat2/features/auth/domain/entities/email_address.dart';
import 'package:syscat2/features/auth/domain/repositories/auth_repository.dart';
import 'package:syscat2/features/settings/domain/entities/ai_model_settings.dart';
import 'package:syscat2/features/settings/domain/entities/ai_provider.dart';
import 'package:syscat2/features/settings/domain/entities/api_key.dart';
import 'package:syscat2/features/settings/domain/entities/settings_failure.dart';
import 'package:syscat2/features/settings/domain/repositories/settings_repository.dart';
import 'package:syscat2/features/settings/domain/usecases/get_ai_model_settings.dart';
import 'package:syscat2/features/settings/domain/usecases/save_ai_provider_settings.dart';
import 'package:syscat2/features/settings/presentation/cubits/settings_cubit.dart';
import 'package:syscat2/features/settings/presentation/cubits/settings_state.dart';
import 'package:syscat2/features/user/domain/entities/user_email.dart';
import 'package:syscat2/features/user/domain/entities/user_failure.dart';
import 'package:syscat2/features/user/domain/entities/user_profile.dart';
import 'package:syscat2/features/user/domain/repositories/user_repository.dart';
import 'package:syscat2/features/user/domain/usecases/ensure_user_profile.dart';
import 'package:syscat2/features/user/domain/usecases/get_current_user_profile.dart';

void main() {
  group('SettingsCubit', () {
    test('laedt Profil und Sprachmodell-Einstellungen', () async {
      final userRepository = _FakeUserRepository();
      final settingsRepository = _FakeSettingsRepository();
      final cubit = _cubitWith(userRepository, settingsRepository);
      await cubit.load();
      expect(cubit.state.loadStatus, SettingsLoadStatus.ready);
      expect(cubit.state.profile?.displayName, 'Ada');
      expect(cubit.state.selectedProvider, AiProvider.googleAi);
      await cubit.close();
    });

    test('speichert den Anzeigenamen ueber den User-Use-Case', () async {
      final userRepository = _FakeUserRepository();
      final settingsRepository = _FakeSettingsRepository();
      final cubit = _cubitWith(userRepository, settingsRepository);
      await cubit.load();
      cubit.updateDisplayName('Grace');
      await cubit.saveProfile();
      expect(userRepository.savedDisplayName, 'Grace');
      expect(cubit.state.profile?.displayName, 'Grace');
      expect(cubit.state.message, 'Profil gespeichert.');
      await cubit.close();
    });

    test('speichert Provider und API-Key write-only', () async {
      final userRepository = _FakeUserRepository();
      final settingsRepository = _FakeSettingsRepository();
      final cubit = _cubitWith(userRepository, settingsRepository);
      await cubit.load();
      cubit.updateProvider(AiProvider.openAi);
      cubit.updateApiKey('sk-test-123456');
      await cubit.saveAiModelSettings();
      expect(settingsRepository.savedProvider, AiProvider.openAi);
      expect(settingsRepository.savedApiKey, 'sk-test-123456');
      expect(cubit.state.apiKeyInput, isEmpty);
      expect(cubit.state.aiModelSettings?.maskedApiKey, '**** 3456');
      await cubit.close();
    });
  });
}

SettingsCubit _cubitWith(
  _FakeUserRepository userRepository,
  _FakeSettingsRepository settingsRepository,
) {
  final authRepository = _FakeAuthRepository();
  return SettingsCubit(
    getCurrentUserProfile: GetCurrentUserProfile(
      authRepository: authRepository,
      userRepository: userRepository,
    ),
    ensureUserProfile: EnsureUserProfile(userRepository),
    getAiModelSettings: GetAiModelSettings(settingsRepository),
    saveAiProviderSettings: SaveAiProviderSettings(settingsRepository),
  );
}

class _FakeAuthRepository implements AuthRepository {
  @override
  AuthUser? currentUser() => const AuthUser(
    id: UniqueId('user.1'),
    email: 'ada@example.com',
    displayName: 'Ada',
  );

  @override
  Stream<AuthUser?> authStateChanges() => const Stream.empty();

  @override
  Future<Result<AuthUser, AuthFailure>> signIn({
    required EmailAddress email,
    required String password,
  }) async {
    return const Result.error(AuthFailure(AuthFailureKind.unknown));
  }

  @override
  Future<Result<Unit, AuthFailure>> signOut() async {
    return const Result.success(unit);
  }

  @override
  Future<Result<AuthUser, AuthFailure>> signUp({
    required String name,
    required EmailAddress email,
    required String password,
  }) async {
    return const Result.error(AuthFailure(AuthFailureKind.unknown));
  }
}

class _FakeUserRepository implements UserRepository {
  String? savedDisplayName;

  @override
  Future<Result<UserProfile, UserFailure>> ensureProfile({
    required UniqueId id,
    required UserEmail email,
    required String displayName,
  }) async {
    savedDisplayName = displayName;
    return Result.success(_profile(displayName));
  }

  @override
  Future<Result<UserProfile, UserFailure>> getProfile(UniqueId id) async {
    return Result.success(_profile('Ada'));
  }

  UserProfile _profile(String displayName) {
    return UserProfile(
      id: const UniqueId('user.1'),
      email: UserEmail.tryCreate('ada@example.com')!,
      displayName: displayName,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026, 1, 2),
    );
  }
}

class _FakeSettingsRepository implements SettingsRepository {
  AiProvider? savedProvider;
  String? savedApiKey;

  @override
  Future<Result<AiModelSettings, SettingsFailure>> getAiModelSettings(
    UniqueId userId,
  ) async {
    return Result.success(AiModelSettings.defaults());
  }

  @override
  Future<Result<AiModelSettings, SettingsFailure>> saveAiProviderSettings({
    required UniqueId userId,
    required AiProvider provider,
    required ApiKey apiKey,
  }) async {
    savedProvider = provider;
    savedApiKey = apiKey.value;
    return Result.success(
      AiModelSettings(
        provider: provider,
        hasApiKey: true,
        maskedApiKey: '**** ${apiKey.value.substring(apiKey.value.length - 4)}',
        updatedAt: DateTime.utc(2026),
      ),
    );
  }
}
