import 'package:flutter_test/flutter_test.dart';
import 'fcm_bootstrapper_test_doubles.dart';

void main() {
  group('FcmBootstrapper', () {
    test(
      'registriert unterschiedliche Geraete-Tokens fuer denselben Nutzer',
      () async {
        final user = testUser('kunde-1');
        final deviceRepository = TestDeviceRepository();
        final firstAuth = TestAuthRepository(user);
        final secondAuth = TestAuthRepository(user);
        final firstProvider = TestTokenProvider('token-telefon');
        final secondProvider = TestTokenProvider('token-tablet');
        final firstBootstrapper = testBootstrapper(
          firstAuth,
          firstProvider,
          deviceRepository,
        );
        final secondBootstrapper = testBootstrapper(
          secondAuth,
          secondProvider,
          deviceRepository,
        );

        await firstBootstrapper.start();
        await secondBootstrapper.start();

        expect(deviceRepository.savedTokens, hasLength(2));
        expect(
          deviceRepository.savedTokens.map((token) => token.userId),
          everyElement(user.id.value),
        );
        expect(
          deviceRepository.savedTokens.map((token) => token.token),
          containsAll(['token-telefon', 'token-tablet']),
        );

        await disposeTestResources(
          [firstBootstrapper, secondBootstrapper],
          [firstAuth, secondAuth],
          [firstProvider, secondProvider],
        );
      },
    );

    test('entfernt die alte Kontozuordnung vor einem Konto-Wechsel', () async {
      final firstUser = testUser('kunde-1');
      final authRepository = TestAuthRepository(firstUser);
      final tokenProvider = TestTokenProvider('token-telefon');
      final deviceRepository = TestDeviceRepository();
      final bootstrapper = testBootstrapper(
        authRepository,
        tokenProvider,
        deviceRepository,
      );

      await bootstrapper.start();
      authRepository.emit(testUser('kunde-2'));
      await Future<void>.delayed(Duration.zero);

      expect(deviceRepository.deletedTokens, [
        (userId: firstUser.id.value, token: 'token-telefon'),
      ]);
      expect(deviceRepository.savedTokens.last.userId, 'kunde-2');
      expect(tokenProvider.tokenDeleted, isFalse);

      await disposeTestResources([bootstrapper], [authRepository], [
        tokenProvider,
      ]);
    });

    test('fordert die Berechtigung erst durch eine Nutzeraktion an', () async {
      final authRepository = TestAuthRepository(testUser('kunde-1'));
      final tokenProvider = TestTokenProvider(
        'token-telefon',
        permissionGranted: false,
      );
      final deviceRepository = TestDeviceRepository();
      final bootstrapper = testBootstrapper(
        authRepository,
        tokenProvider,
        deviceRepository,
      );

      await bootstrapper.start();
      expect(deviceRepository.savedTokens, isEmpty);
      expect(tokenProvider.permissionRequested, isFalse);

      await bootstrapper.requestPermissionAndRegister();
      expect(deviceRepository.savedTokens.single.token, 'token-telefon');
      expect(tokenProvider.permissionRequested, isTrue);

      await disposeTestResources([bootstrapper], [authRepository], [
        tokenProvider,
      ]);
    });
  });
}
